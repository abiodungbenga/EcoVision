import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

import 'vmodal_service.dart';

enum ApiKeyRetention {
  oneDay('1 day', Duration(days: 1)),
  oneWeek('7 days', Duration(days: 7)),
  oneMonth('30 days', Duration(days: 30)),
  permanent('Permanently', null);

  const ApiKeyRetention(this.label, this.duration);

  final String label;
  final Duration? duration;
}

abstract interface class SecureValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class _FlutterSecureValueStore implements SecureValueStore {
  _FlutterSecureValueStore(this._storage);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

class ApiKeyService extends GetxService {
  ApiKeyService({
    required this.vmodalService,
    SecureValueStore? storage,
    DateTime Function()? clock,
  }) : _storage =
           storage ?? _FlutterSecureValueStore(const FlutterSecureStorage()),
       _clock = clock ?? DateTime.now;

  static const String _credentialStorageKey = 'vmodal_api_credential';
  static const String _fingerprintSecretStorageKey =
      'vmodal_api_fingerprint_secret';
  static const Duration _maxExpiryTimerDelay = Duration(hours: 12);

  final VModalService vmodalService;
  final SecureValueStore _storage;
  final DateTime Function() _clock;

  final hasSavedCredential = false.obs;
  final savedRetention = Rxn<ApiKeyRetention>();
  final savedExpiry = Rxn<DateTime>();
  final restoreError = RxnString();
  final credentialExpired = false.obs;

  ApiKeyCredential? _credential;
  Timer? _expiryTimer;
  Future<void>? _initialization;
  bool get isInitialized => _initialization != null;

  String? get apiKeyProfileId => _credential?.profileId;
  ApiKeyRetention? get retention => _credential?.retention;
  DateTime? get expiresAt => _credential?.expiresAt;

  void Function()? onCredentialsChanged;

  Future<void> initialize() => _initialization ??= _restore();

  Future<void> _restore() async {
    try {
      final rawCredential = await _storage.read(_credentialStorageKey);
      if (rawCredential == null) return;

      final credential = ApiKeyCredential.fromJson(
        jsonDecode(rawCredential) as Map<String, dynamic>,
      );
      final expiry = credential.expiresAt;
      if (expiry != null && !_clock().isBefore(expiry)) {
        await _storage.delete(_credentialStorageKey);
        credentialExpired.value = true;
        return;
      }

      await vmodalService.configure(credential.apiKey);
      _setCredential(credential);
      _scheduleExpiry();
    } catch (error, stackTrace) {
      restoreError.value = error.toString();
      developer.log(
        'Could not restore the encrypted V-Modal API key.',
        name: 'ApiKeyService',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> save(String apiKey, ApiKeyRetention retention) async {
    await initialize();
    final cleanKey = apiKey.trim();
    if (cleanKey.isEmpty) {
      throw ArgumentError.value(apiKey, 'apiKey', 'API key cannot be empty.');
    }

    final secret = await _fingerprintSecret();
    final profileId = Hmac(
      sha256,
      secret,
    ).convert(utf8.encode(cleanKey)).toString();
    final now = _clock();
    final credential = ApiKeyCredential(
      apiKey: cleanKey,
      profileId: profileId,
      retention: retention,
      expiresAt: retention.duration == null
          ? null
          : now.add(retention.duration!),
    );
    final previous = _credential;
    final keyChanged = previous?.profileId != profileId;

    if (keyChanged) onCredentialsChanged?.call();
    try {
      await vmodalService.configure(cleanKey);
    } catch (error, stackTrace) {
      if (previous != null) {
        try {
          await vmodalService.configure(previous.apiKey);
        } catch (rollbackError, rollbackStackTrace) {
          Error.throwWithStackTrace(
            StateError(
              'The new API key could not be configured ($error), and '
              'restoring the previous connection also failed '
              '($rollbackError).',
            ),
            rollbackStackTrace,
          );
        }
      }
      Error.throwWithStackTrace(error, stackTrace);
    }

    try {
      await _storage.write(
        _credentialStorageKey,
        jsonEncode(credential.toJson()),
      );
    } catch (error, stackTrace) {
      try {
        if (previous == null) {
          await vmodalService.clearConfiguration();
        } else {
          await vmodalService.configure(previous.apiKey);
        }
      } catch (rollbackError, rollbackStackTrace) {
        Error.throwWithStackTrace(
          StateError(
            'The API key could not be saved securely ($error), and restoring '
            'the previous connection also failed ($rollbackError).',
          ),
          rollbackStackTrace,
        );
      }
      Error.throwWithStackTrace(error, stackTrace);
    }

    _setCredential(credential);
    credentialExpired.value = false;
    restoreError.value = null;
    _scheduleExpiry();
  }

  Future<void> revoke() async {
    await initialize();
    await _storage.delete(_credentialStorageKey);
    onCredentialsChanged?.call();
    _expiryTimer?.cancel();
    _expiryTimer = null;
    _credential = null;
    hasSavedCredential.value = false;
    savedRetention.value = null;
    savedExpiry.value = null;
    credentialExpired.value = false;
    restoreError.value = null;
    await vmodalService.clearConfiguration();
  }

  Future<void> updateRetention(ApiKeyRetention retention) async {
    await initialize();
    final current = _credential;
    if (current == null) {
      throw StateError('There is no saved API key to update.');
    }

    final updated = ApiKeyCredential(
      apiKey: current.apiKey,
      profileId: current.profileId,
      retention: retention,
      expiresAt: retention.duration == null
          ? null
          : _clock().add(retention.duration!),
    );
    await _storage.write(_credentialStorageKey, jsonEncode(updated.toJson()));
    _setCredential(updated);
    credentialExpired.value = false;
    restoreError.value = null;
    _scheduleExpiry();
  }

  Future<List<int>> _fingerprintSecret() async {
    final storedSecret = await _storage.read(_fingerprintSecretStorageKey);
    if (storedSecret != null) return base64Url.decode(storedSecret);

    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    await _storage.write(_fingerprintSecretStorageKey, base64UrlEncode(bytes));
    return bytes;
  }

  void _setCredential(ApiKeyCredential credential) {
    _credential = credential;
    hasSavedCredential.value = true;
    savedRetention.value = credential.retention;
    savedExpiry.value = credential.expiresAt;
  }

  void _scheduleExpiry() {
    _expiryTimer?.cancel();
    final expiry = _credential?.expiresAt;
    if (expiry == null) return;

    final remaining = expiry.difference(_clock());
    final delay = remaining > _maxExpiryTimerDelay
        ? _maxExpiryTimerDelay
        : remaining;
    _expiryTimer = Timer(delay, () {
      if (!_clock().isBefore(expiry)) {
        unawaited(_expireCredential());
      } else {
        _scheduleExpiry();
      }
    });
  }

  Future<void> _expireCredential() async {
    try {
      await revoke();
      credentialExpired.value = true;
    } catch (error, stackTrace) {
      restoreError.value =
          'The saved API key expired, but could not be removed securely: '
          '$error';
      developer.log(
        'Could not remove the expired V-Modal API key.',
        name: 'ApiKeyService',
        error: error,
        stackTrace: stackTrace,
      );
      onCredentialsChanged?.call();
      try {
        await vmodalService.clearConfiguration();
      } catch (clearError, clearStackTrace) {
        restoreError.value =
            '${restoreError.value} The connection could not be fully closed: '
            '$clearError';
        developer.log(
          'Could not close the V-Modal client after key expiry.',
          name: 'ApiKeyService',
          error: clearError,
          stackTrace: clearStackTrace,
        );
      }
    }
  }

  @override
  void onClose() {
    _expiryTimer?.cancel();
    super.onClose();
  }
}

class ApiKeyCredential {
  const ApiKeyCredential({
    required this.apiKey,
    required this.profileId,
    required this.retention,
    required this.expiresAt,
  });

  final String apiKey;
  final String profileId;
  final ApiKeyRetention retention;
  final DateTime? expiresAt;

  Map<String, Object?> toJson() => {
    'apiKey': apiKey,
    'profileId': profileId,
    'retention': retention.name,
    'expiresAt': expiresAt?.toIso8601String(),
  };

  factory ApiKeyCredential.fromJson(Map<String, dynamic> json) {
    final retentionName = json['retention'] as String?;
    final retention = ApiKeyRetention.values.firstWhere(
      (value) => value.name == retentionName,
      orElse: () =>
          throw FormatException('Unknown API key retention "$retentionName".'),
    );
    final apiKey = json['apiKey'] as String?;
    final profileId = json['profileId'] as String?;
    if (apiKey == null || apiKey.trim().isEmpty || profileId == null) {
      throw const FormatException('Saved API key data is incomplete.');
    }

    final expiryText = json['expiresAt'] as String?;
    final expiresAt = expiryText == null ? null : DateTime.tryParse(expiryText);
    if ((retention.duration == null) != (expiresAt == null) ||
        (expiryText != null && expiresAt == null)) {
      throw const FormatException('Saved API key expiry is invalid.');
    }

    return ApiKeyCredential(
      apiKey: apiKey,
      profileId: profileId,
      retention: retention,
      expiresAt: expiresAt,
    );
  }
}
