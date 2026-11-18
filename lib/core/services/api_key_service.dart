import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

import 'shared_api_key_provider.dart';
import '../utils/user_data_namespace.dart';
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
    this._sharedApiKeyProvider,
    String? userId,
    DateTime Function()? clock,
  }) : _storage =
           storage ?? _FlutterSecureValueStore(const FlutterSecureStorage()),
       _userId = userId,
       _clock = clock ?? DateTime.now;

  static const String _credentialStorageKey = 'vmodal_api_credential';
  static const String _keySourceStorageKey = 'vmodal_api_key_source';
  static const String _fingerprintSecretStorageKey =
      'vmodal_api_fingerprint_secret';
  static const Duration _maxExpiryTimerDelay = Duration(hours: 12);

  final VModalService vmodalService;
  final SecureValueStore _storage;
  final SharedApiKeyProvider? _sharedApiKeyProvider;
  final DateTime Function() _clock;
  String? _userId;
  bool _isSignedOutScope = false;

  final hasSavedCredential = false.obs;
  final isUsingSharedKey = false.obs;
  final sharedKeyAvailable = false.obs;
  final sharedKeyError = RxnString();
  final savedRetention = Rxn<ApiKeyRetention>();
  final savedExpiry = Rxn<DateTime>();
  final restoreError = RxnString();
  final credentialExpired = false.obs;

  ApiKeyCredential? _credential;
  String? _sharedApiKey;
  String? _activeApiKey;
  String? _activeProfileId;
  Timer? _expiryTimer;
  Future<void>? _initialization;
  bool get isInitialized => _initialization != null;

  String? get apiKeyProfileId => _activeProfileId;
  ApiKeyRetention? get retention => _credential?.retention;
  DateTime? get expiresAt => _credential?.expiresAt;

  void Function()? onCredentialsChanged;

  Future<void> initialize() => _initialization ??= _restore();

  Future<void> switchUser(String? userId) async {
    if (_userId == userId && (userId != null || _isSignedOutScope)) return;

    onCredentialsChanged?.call();
    _expiryTimer?.cancel();
    _expiryTimer = null;
    if (vmodalService.isConfigured) {
      await vmodalService.clearConfiguration();
    }

    _userId = userId;
    _isSignedOutScope = userId == null;
    _credential = null;
    _sharedApiKey = null;
    _activeApiKey = null;
    _activeProfileId = null;
    hasSavedCredential.value = false;
    isUsingSharedKey.value = false;
    sharedKeyAvailable.value = false;
    sharedKeyError.value = null;
    savedRetention.value = null;
    savedExpiry.value = null;
    restoreError.value = null;
    credentialExpired.value = false;
    _initialization = null;
    if (userId == null) {
      _isSignedOutScope = true;
      _initialization = Future<void>.value();
      return;
    }
    await initialize();
  }

  String _scopedStorageKey(String key) => UserDataNamespace.secureStorageKey(
    key,
    _isSignedOutScope ? 'signed_out' : _userId,
  );

  Future<void> _restore() async {
    try {
      final rawCredential = await _storage.read(
        _scopedStorageKey(_credentialStorageKey),
      );
      if (rawCredential != null) {
        final credential = ApiKeyCredential.fromJson(
          jsonDecode(rawCredential) as Map<String, dynamic>,
        );
        final expiry = credential.expiresAt;
        if (expiry != null && !_clock().isBefore(expiry)) {
          await _storage.delete(_scopedStorageKey(_credentialStorageKey));
          await _storage.delete(_scopedStorageKey(_keySourceStorageKey));
          credentialExpired.value = true;
        } else {
          _setCredential(credential);
          _scheduleExpiry();
        }
      }

      if (_sharedApiKeyProvider != null) {
        try {
          _sharedApiKey = await _sharedApiKeyProvider.fetchApiKey();
          sharedKeyAvailable.value = _sharedApiKey != null;
          sharedKeyError.value = null;
        } catch (error, stackTrace) {
          sharedKeyError.value = error.toString();
          developer.log(
            'Could not fetch the shared V-Modal API key.',
            name: 'ApiKeyService',
            error: error,
            stackTrace: stackTrace,
          );
        }
      }

      final savedSource = await _storage.read(
        _scopedStorageKey(_keySourceStorageKey),
      );
      final shouldUseSharedKey =
          savedSource == 'shared' ||
          (savedSource == null &&
              _credential == null &&
              _sharedApiKeyProvider != null);
      if (shouldUseSharedKey) {
        if (_sharedApiKey != null) {
          await _activateKey(_sharedApiKey!, useSharedKey: true);
        }
      } else if (_credential != null) {
        await vmodalService.configure(_credential!.apiKey);
        _activeApiKey = _credential!.apiKey;
        _activeProfileId = _credential!.profileId;
      }
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
    final credentialKey = _scopedStorageKey(_credentialStorageKey);
    final sourceKey = _scopedStorageKey(_keySourceStorageKey);
    final previousRawCredential = await _storage.read(credentialKey);
    final previousSource = await _storage.read(sourceKey);
    final previousApiKey = _activeApiKey;
    final previousProfileId = _activeProfileId;
    final previousSharedKey = isUsingSharedKey.value;
    try {
      await _activateKey(cleanKey, useSharedKey: false);
      await _storage.write(credentialKey, jsonEncode(credential.toJson()));
      await _storage.write(sourceKey, 'personal');
    } catch (error, stackTrace) {
      try {
        if (previousRawCredential == null) {
          await _storage.delete(credentialKey);
        } else {
          await _storage.write(credentialKey, previousRawCredential);
        }
        if (previousSource == null) {
          await _storage.delete(sourceKey);
        } else {
          await _storage.write(sourceKey, previousSource);
        }
      } catch (rollbackError, rollbackStackTrace) {
        Error.throwWithStackTrace(
          StateError(
            'The API key could not be saved securely ($error), and restoring '
            'the previous key settings failed ($rollbackError).',
          ),
          rollbackStackTrace,
        );
      }
      try {
        await _restoreActiveConnection(
          previousApiKey,
          previousProfileId,
          previousSharedKey,
        );
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
    sharedKeyError.value = null;
    _scheduleExpiry();
  }

  Future<void> revoke() async {
    await initialize();
    final wasUsingSharedKey = isUsingSharedKey.value;
    if (_sharedApiKey != null) {
      if (!wasUsingSharedKey) {
        await _persistAndActivateKey(_sharedApiKey!, useSharedKey: true);
      }
      await _storage.write(_scopedStorageKey(_keySourceStorageKey), 'shared');
    } else {
      if (!wasUsingSharedKey) onCredentialsChanged?.call();
      await vmodalService.clearConfiguration();
      await _storage.delete(_scopedStorageKey(_keySourceStorageKey));
    }
    await _storage.delete(_scopedStorageKey(_credentialStorageKey));

    _expiryTimer?.cancel();
    _expiryTimer = null;
    _credential = null;
    hasSavedCredential.value = false;
    savedRetention.value = null;
    savedExpiry.value = null;
    credentialExpired.value = false;
    restoreError.value = null;
    if (_sharedApiKey == null) {
      _activeProfileId = null;
      _activeApiKey = null;
      isUsingSharedKey.value = false;
    }
  }

  Future<void> useSharedKey() async {
    await initialize();
    await refreshSharedKey();
    final apiKey = _sharedApiKey;
    if (apiKey == null) {
      throw StateError('The shared V-Modal API key is not available.');
    }
    await _persistAndActivateKey(apiKey, useSharedKey: true);
    sharedKeyError.value = null;
  }

  Future<void> refreshSharedKey() async {
    final provider = _sharedApiKeyProvider;
    if (provider == null) {
      throw StateError('The shared V-Modal API key is not configured.');
    }

    try {
      _sharedApiKey = await provider.fetchApiKey();
      sharedKeyAvailable.value = _sharedApiKey != null;
      sharedKeyError.value = null;
    } catch (error, stackTrace) {
      sharedKeyError.value = error.toString();
      developer.log(
        'Could not refresh the shared V-Modal API key.',
        name: 'ApiKeyService',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> usePersonalKey() async {
    await initialize();
    final credential = _credential;
    if (credential == null) {
      throw StateError('There is no saved personal API key.');
    }

    await _persistAndActivateKey(credential.apiKey, useSharedKey: false);
  }

  Future<void> _activateKey(String apiKey, {required bool useSharedKey}) async {
    final profileId = await _profileIdFor(apiKey);
    final keyChanged = _activeProfileId != profileId;
    if (keyChanged) onCredentialsChanged?.call();
    try {
      await vmodalService.configure(apiKey);
    } catch (error, stackTrace) {
      try {
        await _restoreActiveConnection(
          _activeApiKey,
          _activeProfileId,
          isUsingSharedKey.value,
        );
      } catch (rollbackError, rollbackStackTrace) {
        Error.throwWithStackTrace(
          StateError(
            'The new API key could not be configured ($error), and restoring '
            'the previous connection also failed ($rollbackError).',
          ),
          rollbackStackTrace,
        );
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
    _activeApiKey = apiKey;
    _activeProfileId = profileId;
    isUsingSharedKey.value = useSharedKey;
    if (!useSharedKey && _credential != null) {
      _setCredential(_credential!);
      _scheduleExpiry();
    }
  }

  Future<void> _persistAndActivateKey(
    String apiKey, {
    required bool useSharedKey,
  }) async {
    final sourceKey = _scopedStorageKey(_keySourceStorageKey);
    final previousSource = await _storage.read(sourceKey);
    final previousApiKey = _activeApiKey;
    final previousProfileId = _activeProfileId;
    final previousSharedKey = isUsingSharedKey.value;
    try {
      await _activateKey(apiKey, useSharedKey: useSharedKey);
      await _storage.write(sourceKey, useSharedKey ? 'shared' : 'personal');
    } catch (error, stackTrace) {
      try {
        if (previousSource == null) {
          await _storage.delete(sourceKey);
        } else {
          await _storage.write(sourceKey, previousSource);
        }
      } catch (rollbackError, rollbackStackTrace) {
        Error.throwWithStackTrace(
          StateError(
            'The API key source could not be saved ($error), and restoring '
            'the previous selection failed ($rollbackError).',
          ),
          rollbackStackTrace,
        );
      }
      try {
        await _restoreActiveConnection(
          previousApiKey,
          previousProfileId,
          previousSharedKey,
        );
      } catch (rollbackError, rollbackStackTrace) {
        Error.throwWithStackTrace(
          StateError(
            'The API key source could not be saved ($error), and restoring '
            'the previous connection also failed ($rollbackError).',
          ),
          rollbackStackTrace,
        );
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> _restoreActiveConnection(
    String? apiKey,
    String? profileId,
    bool useSharedKey,
  ) async {
    if (apiKey == null) {
      await vmodalService.clearConfiguration();
    } else {
      await vmodalService.configure(apiKey);
    }
    _activeApiKey = apiKey;
    _activeProfileId = profileId;
    isUsingSharedKey.value = useSharedKey;
  }

  Future<String> _profileIdFor(String apiKey) async {
    final secret = await _fingerprintSecret();
    return Hmac(sha256, secret).convert(utf8.encode(apiKey)).toString();
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
    await _storage.write(
      _scopedStorageKey(_credentialStorageKey),
      jsonEncode(updated.toJson()),
    );
    _setCredential(updated);
    credentialExpired.value = false;
    restoreError.value = null;
    _scheduleExpiry();
  }

  Future<List<int>> _fingerprintSecret() async {
    final secretKey = _scopedStorageKey(_fingerprintSecretStorageKey);
    final storedSecret = await _storage.read(secretKey);
    if (storedSecret != null) return base64Url.decode(storedSecret);

    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    await _storage.write(secretKey, base64UrlEncode(bytes));
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
