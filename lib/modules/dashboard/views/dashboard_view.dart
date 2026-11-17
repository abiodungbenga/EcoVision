import 'package:flutter/material.dart';

import 'dart:io';

import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/services/video_service.dart';
import '../controllers/dashboard_controller.dart';
import '../../../shared/models/observation_model.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Research Dashboard')),
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Obx(
                () => Text(
                  controller.greeting.value,
                  style: TextStyle(fontSize: 14, color: palette.secondaryText),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Your Environmental Research Overview',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: palette.text,
                ),
              ),
              const SizedBox(height: 16),

              // Statistics Grid (Responsive layouts)
              Obx(
                () => GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  children: [
                    _buildStatCard(
                      context,
                      '${controller.videosAnalyzed.value}',
                      'Videos analyzed',
                      Icons.video_library_rounded,
                      palette.surfaceVariant,
                      palette.info,
                    ),
                    _buildStatCard(
                      context,
                      '${controller.observationCount.value}',
                      'Observations saved',
                      Icons.science_rounded,
                      palette.surfaceVariant,
                      palette.success,
                    ),
                    _buildStatCard(
                      context,
                      '${controller.monthlySearchCount.value}',
                      'Searches this month',
                      Icons.search_rounded,
                      palette.surfaceVariant,
                      palette.warning,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Recent Observations Section
              Text(
                'Recent Observations',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: palette.text,
                ),
              ),
              const SizedBox(height: 10),
              Obx(() {
                if (controller.recentObservations.isEmpty) {
                  return _buildEmptySection(
                    context,
                    'No recent observations saved.',
                  );
                }
                return Column(
                  children: controller.recentObservations
                      .map((obs) => _buildRecentObservationTile(context, obs))
                      .toList(),
                );
              }),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String val,
    String title,
    IconData icon,
    Color bgColor,
    Color iconColor,
  ) {
    final palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                val,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: palette.text,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
            ],
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: palette.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentObservationTile(
    BuildContext context,
    ObservationModel obs,
  ) {
    final palette = AppPalette.of(context);
    void openPlayer() {
      var path = obs.videoPath;
      if (path.isEmpty) {
        final videoService = Get.find<VideoService>();
        final match =
            videoService.videoHistory.firstWhereOrNull(
              (v) => v.fileName == obs.videoName,
            ) ??
            videoService.currentVideo;
        if (match != null) {
          path = match.filePath;
        }
      }

      Get.toNamed(
        AppRoutes.player,
        arguments: {
          'videoPath': path,
          'videoName': obs.videoName.isNotEmpty ? obs.videoName : obs.species,
          'title': '${obs.species} Sighting',
          'timestamp': Duration(milliseconds: obs.timestampMs),
          'timestampText': obs.formattedTimestamp,
          'hasTimestamp': true,
          'isTimestampApproximate': false,
        },
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        dense: true,
        leading: GestureDetector(
          onTap: openPlayer,
          child: SizedBox(
            width: 56,
            height: 56,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                color: palette.surfaceVariant,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child:
                          obs.thumbnailUrl == null || obs.thumbnailUrl!.isEmpty
                          ? Icon(
                              Icons.movie_rounded,
                              color: palette.secondaryText,
                            )
                          : Image(
                              image: obs.thumbnailUrl!.startsWith('http')
                                  ? NetworkImage(obs.thumbnailUrl!)
                                  : FileImage(File(obs.thumbnailUrl!)),
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Icon(
                                Icons.movie_rounded,
                                color: palette.secondaryText,
                              ),
                            ),
                    ),
                    Positioned.fill(
                      child: Container(
                        color: Colors.black26,
                        child: Center(
                          child: Icon(
                            Icons.play_circle_fill_rounded,
                            color: palette.onPrimary,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        title: Text(
          obs.species,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: palette.primary,
          ),
        ),
        subtitle: Text(
          '${obs.formattedTimestamp} • ${obs.videoName.isNotEmpty ? obs.videoName : "Video"}',
          style: TextStyle(fontSize: 12, color: palette.secondaryText),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatTimeAgo(obs.createdAt),
              style: TextStyle(fontSize: 11, color: palette.secondaryText),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.play_circle_outline_rounded,
              color: palette.primary,
              size: 22,
            ),
          ],
        ),
        onTap: openPlayer,
      ),
    );
  }

  Widget _buildEmptySection(BuildContext context, String text) {
    final palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.divider),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(fontSize: 13, color: palette.secondaryText),
        ),
      ),
    );
  }
}
