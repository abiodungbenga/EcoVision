import 'dart:async';

import 'package:get/get.dart';

import '../../../core/services/video_service.dart';
import '../../../core/services/research_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../shared/models/observation_model.dart';

class DashboardController extends GetxController {
  final VideoService videoService = Get.find<VideoService>();
  final ResearchService researchService = Get.find<ResearchService>();
  final AuthService authService = Get.find<AuthService>();

  final videosAnalyzed = 0.obs;
  final observationCount = 0.obs;
  final monthlySearchCount = 0.obs;
  final greeting = 'Good morning'.obs;

  final recentObservations = <ObservationModel>[].obs;
  Timer? _greetingTimer;

  @override
  void onInit() {
    super.onInit();
    _updateGreeting();
    _greetingTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _updateGreeting(),
    );
    updateStats();
    ever(researchService.observations, (_) => updateStats());
    ever(researchService.searchHistory, (_) => updateStats());
    ever(videoService.videoHistory, (_) => updateStats());
  }

  void _updateGreeting() {
    final hour = DateTime.now().hour;
    final user = authService.currentUser;
    final displayName = user?.displayName?.trim();
    final username = displayName != null && displayName.isNotEmpty
        ? displayName
        : user?.email?.split('@').first ?? 'there';
    if (hour >= 5 && hour < 12) {
      greeting.value = 'Good morning, $username';
    } else if (hour < 17) {
      greeting.value = 'Good afternoon, $username';
    } else if (hour < 21) {
      greeting.value = 'Good evening, $username';
    } else {
      greeting.value = 'Good night, $username';
    }
  }

  void updateStats() {
    try {
      videosAnalyzed.value = videoService.videoHistory.length;
      observationCount.value = researchService.observations.length;

      monthlySearchCount.value = researchService.getMonthlySearchCount();
      recentObservations.assignAll(researchService.observations.take(5));
    } catch (_) {
      // Fail gracefully
    }
  }

  @override
  void onClose() {
    _greetingTimer?.cancel();
    super.onClose();
  }
}
