import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/services/api_key_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/video_service.dart';
import '../../../core/services/vmodal_service.dart';
import '../../../core/services/indexing_service.dart';
import '../../../core/services/discovery_service.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../shared/models/video_model.dart';

class HomeController extends GetxController {
  final VModalService vmodalService = Get.find<VModalService>();
  final ApiKeyService apiKeyService = Get.find<ApiKeyService>();
  final AuthService authService = Get.find<AuthService>();
  final VideoService videoService = Get.find<VideoService>();
  final DiscoveryService discoveryService = Get.find<DiscoveryService>();
  final IndexingService indexingService = Get.find<IndexingService>();

  final apiKeyController = TextEditingController();
  final isConnecting = false.obs;

  VideoModel? get currentVideo => videoService.currentVideo;
  bool get hasIndexedVideo =>
      videoService.videoHistory.any((video) => video.isIndexed);

  @override
  void onInit() {
    super.onInit();
    if (vmodalService.isConfigured) {
      discoveryService.fetchSightingsFeed();
    }
  }

  Future<bool> saveApiKey(
    String apiKey, {
    required ApiKeyRetention retention,
  }) async {
    final key = apiKey.trim();
    if (key.isEmpty) {
      SnackbarUtils.showError('Please enter a valid V-Modal API Key.');
      return false;
    }

    try {
      isConnecting.value = true;
      await apiKeyService.save(key, retention);
      await indexingService.resumePendingIndexing();
      discoveryService.fetchSightingsFeed();
      SnackbarUtils.showSuccess('Your encrypted API key is ready to use.');
      return true;
    } catch (e) {
      SnackbarUtils.showError('Configuration failed: ${e.toString()}');
      return false;
    } finally {
      isConnecting.value = false;
    }
  }

  Future<bool> revokeApiKey() async {
    try {
      await apiKeyService.revoke();
      apiKeyController.clear();
      SnackbarUtils.showSuccess('The saved API key has been revoked.');
      return true;
    } catch (error) {
      SnackbarUtils.showError('Could not revoke the API key: $error');
      return false;
    }
  }

  Future<bool> updateApiKeyRetention(ApiKeyRetention retention) async {
    try {
      await apiKeyService.updateRetention(retention);
      SnackbarUtils.showSuccess('API key retention was updated.');
      return true;
    } catch (error) {
      SnackbarUtils.showError('Could not update API key retention: $error');
      return false;
    }
  }

  Future<bool> useSharedApiKey() async {
    try {
      isConnecting.value = true;
      await apiKeyService.useSharedKey();
      await indexingService.resumePendingIndexing();
      discoveryService.fetchSightingsFeed();
      SnackbarUtils.showSuccess('The free V-Modal key is ready to use.');
      return true;
    } catch (error) {
      SnackbarUtils.showError('Could not use the free API key: $error');
      return false;
    } finally {
      isConnecting.value = false;
    }
  }

  Future<bool> usePersonalApiKey() async {
    try {
      isConnecting.value = true;
      await apiKeyService.usePersonalKey();
      await indexingService.resumePendingIndexing();
      discoveryService.fetchSightingsFeed();
      SnackbarUtils.showSuccess('Your personal V-Modal key is ready to use.');
      return true;
    } catch (error) {
      SnackbarUtils.showError('Could not use your saved API key: $error');
      return false;
    } finally {
      isConnecting.value = false;
    }
  }

  Future<bool> refreshSharedApiKey() async {
    try {
      isConnecting.value = true;
      await apiKeyService.refreshSharedKey();
      if (apiKeyService.sharedKeyAvailable.value) {
        SnackbarUtils.showSuccess('The free V-Modal key is available.');
      } else {
        SnackbarUtils.showInfo('The free V-Modal key has not been configured.');
      }
      return apiKeyService.sharedKeyAvailable.value;
    } catch (error) {
      SnackbarUtils.showError('Could not load the free API key: $error');
      return false;
    } finally {
      isConnecting.value = false;
    }
  }

  Future<void> signOut() async {
    try {
      await authService.signOut();
      Get.offAllNamed(AppRoutes.login);
    } catch (error) {
      SnackbarUtils.showError('Could not sign out: $error');
      if (authService.currentUser == null) {
        Get.offAllNamed(AppRoutes.login);
      }
    }
  }

  void goToUpload() {
    Get.offNamed(AppRoutes.upload);
  }

  Future<void> goToSearch() async {
    if (!vmodalService.isConfigured) {
      SnackbarUtils.showInfo('Please configure your V-Modal API key first.');
      return;
    }
    final profileId = apiKeyService.apiKeyProfileId;
    var video = currentVideo;
    if (video?.apiKeyProfileId != null && video?.apiKeyProfileId != profileId) {
      video = null;
      SnackbarUtils.showInfo(
        'This video belongs to another API key. Select it again to upload it under the current key.',
      );
    }
    if (video?.isIndexed != true) {
      video = videoService.videoHistory.firstWhereOrNull(
        (savedVideo) =>
            savedVideo.isIndexed &&
            (savedVideo.apiKeyProfileId == null ||
                savedVideo.apiKeyProfileId == profileId),
      );
      if (video != null) await videoService.setCurrentVideo(video);
    }
    if (video?.isIndexed != true) {
      SnackbarUtils.showInfo('Upload and index a video before searching.');
      Get.toNamed(AppRoutes.upload);
      return;
    }
    Get.offNamed(AppRoutes.search);
  }

  void goToDashboard() {
    Get.offNamed(AppRoutes.dashboard);
  }

  void goToAbout() {
    Get.toNamed(AppRoutes.about);
  }

  @override
  void onClose() {
    apiKeyController.dispose();
    super.onClose();
  }
}
