import 'dart:async';
import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:network_internet_checker/network_internet_checker.dart';

import '../../core/services/api_key_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/indexing_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/network_status_service.dart';
import '../../core/services/video_service.dart';
import '../../core/services/vmodal_service.dart';
import '../../core/services/discovery_service.dart';
import '../../core/services/research_service.dart';
import '../../core/services/user_profile_service.dart';
import '../../core/utils/snackbar_utils.dart';

class InitialBinding extends Bindings {
  InitialBinding({
    this.internetChecker,
    this.apiKeyService,
    this.vmodalService,
  });

  final InternetChecker? internetChecker;
  final ApiKeyService? apiKeyService;
  final VModalService? vmodalService;

  @override
  void dependencies() {
    final auth = Get.put<AuthService>(AuthService(), permanent: true);
    final userId = auth.currentUser?.uid;
    final notifications = NotificationService.instance;
    final profiles = Get.put<UserProfileService>(
      UserProfileService(notificationService: notifications),
      permanent: true,
    );
    Future<void> syncProfile(User? user) async {
      try {
        await profiles.syncUser(user);
      } catch (error, stackTrace) {
        developer.log(
          'Could not sync the signed-in user profile to Firestore.',
          name: 'InitialBinding',
          error: error,
          stackTrace: stackTrace,
        );
        if (Get.context != null) {
          SnackbarUtils.showError('Could not sync account data: $error');
        }
      }
    }

    notifications.onFcmTokenChanged = (token) async {
      try {
        await profiles.syncFcmToken(token);
      } catch (error, stackTrace) {
        developer.log(
          'Could not save the FCM token to Firestore.',
          name: 'InitialBinding',
          error: error,
          stackTrace: stackTrace,
        );
        if (Get.context != null) {
          SnackbarUtils.showError('Could not save notification token: $error');
        }
      }
    };

    Get.put<NetworkStatusService>(
      NetworkStatusService(checker: internetChecker),
      permanent: true,
    );
    final vmodal = Get.put<VModalService>(
      vmodalService ?? VModalService(),
      permanent: true,
    );
    vmodal.setUserId(userId);
    final videos = Get.put<VideoService>(
      VideoService(userId: userId),
      permanent: true,
    );
    final apiKeys = Get.put<ApiKeyService>(
      apiKeyService ?? ApiKeyService(vmodalService: vmodal, userId: userId),
      permanent: true,
    );

    // Permanent so indexing keeps polling while the user navigates away from
    // the Upload screen.
    final indexing = Get.put<IndexingService>(
      IndexingService(
        vmodalService: vmodal,
        videoService: videos,
        apiKeyService: apiKeys,
      ),
      permanent: true,
    );
    apiKeys.onCredentialsChanged = indexing.stopPolling;
    final discovery = Get.put<DiscoveryService>(
      DiscoveryService(userId: userId),
      permanent: true,
    );
    final research = Get.put<ResearchService>(
      ResearchService(userId: userId),
      permanent: true,
    );
    auth.onUserChanged = (nextUserId) async {
      if (nextUserId == null) {
        await syncProfile(null);
      }
      indexing.reset();
      vmodal.setUserId(nextUserId);
      await Future.wait([
        videos.switchUser(nextUserId),
        research.switchUser(nextUserId),
        discovery.switchUser(nextUserId),
      ]);
      await apiKeys.switchUser(nextUserId);
      if (vmodal.isConfigured) {
        await indexing.resumePendingIndexing();
      }
      if (nextUserId != null) await syncProfile(auth.currentUser);
    };
    if (auth.currentUser != null) {
      unawaited(syncProfile(auth.currentUser));
    }
  }
}
