import 'package:firebase_remote_config/firebase_remote_config.dart';

abstract interface class SharedApiKeyProvider {
  Future<String?> fetchApiKey();
}

class FirebaseSharedApiKeyProvider implements SharedApiKeyProvider {
  FirebaseSharedApiKeyProvider({FirebaseRemoteConfig? remoteConfig})
    : _remoteConfig = remoteConfig ?? FirebaseRemoteConfig.instance;

  static const parameterName = 'free_vmodal_api_key';

  final FirebaseRemoteConfig _remoteConfig;

  @override
  Future<String?> fetchApiKey() async {
    await _remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1),
      ),
    );
    await _remoteConfig.setDefaults(const {parameterName: ''});
    await _remoteConfig.fetchAndActivate();
    final value = _remoteConfig.getString(parameterName).trim();
    return value.isEmpty ? null : value;
  }
}
