import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../shared/models/video_model.dart';
import '../../../shared/widgets/status_indicator.dart';
import '../controllers/upload_controller.dart';

class UploadView extends GetView<UploadController> {
  const UploadView({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Wildlife Footage')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: palette.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: palette.success.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.video_collection_outlined,
                    color: palette.success,
                    size: 28,
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Select a wildlife or environmental video to upload to V-Modal for multimodal indexing.',
                      style: TextStyle(
                        fontSize: 13,
                        color: palette.success,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Video File Selection Section
            Obx(() {
              final video = controller.currentVideo;
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: palette.divider),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected File',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: palette.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (video == null) ...[
                      Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.folder_open_rounded,
                              size: 48,
                              color: palette.secondaryText,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'No video selected',
                              style: TextStyle(
                                fontSize: 14,
                                color: palette.secondaryText,
                              ),
                            ),
                            const SizedBox(height: 16),
                            AppButton(
                              label: 'Select Video',
                              icon: Icons.video_library_rounded,
                              onPressed: controller.isProcessing
                                  ? null
                                  : controller.selectVideo,
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: palette.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.movie_creation_outlined,
                              color: palette.primary,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  video.fileName,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: palette.text,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${video.formattedSize} • ${video.collectionName}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: palette.secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          StatusIndicator(status: video.status),
                          if (!controller.isProcessing)
                            TextButton.icon(
                              onPressed: () => _confirmReplace(context),
                              icon: const Icon(Icons.swap_horiz, size: 18),
                              label: Text(
                                video.status == VideoStatus.indexed
                                    ? 'Replace Video'
                                    : 'Change File',
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _buildVideoPreview(context),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),

            // Upload Progress & Index Status Card
            Obx(() {
              final video = controller.currentVideo;
              if (video == null) return const SizedBox.shrink();

              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: palette.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upload & Index Status',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: palette.text,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Progress message banner
                    Text(
                      controller.statusMessage,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: palette.text,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Upload Progress bar
                    if (video.status == VideoStatus.uploading ||
                        controller.uploadProgress.value > 0) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Upload Progress',
                            style: TextStyle(
                              fontSize: 12,
                              color: palette.secondaryText,
                            ),
                          ),
                          Text(
                            '${controller.uploadProgress.value.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: palette.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: controller.uploadProgress.value / 100,
                          backgroundColor: palette.surfaceVariant,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            palette.primary,
                          ),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Index Job ID details
                    if (controller.jobId.value.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: palette.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: palette.divider),
                        ),
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            Text(
                              'Job ID: ${controller.jobId.value.substring(0, controller.jobId.value.length > 12 ? 12 : controller.jobId.value.length)}...',
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                            Text(
                              'Status: ${controller.indexStatus.value}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: palette.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Action buttons
                    if (controller.isProcessing) ...[
                      OutlinedButton.icon(
                        onPressed: controller.cancelUpload,
                        icon: const Icon(
                          Icons.cancel_outlined,
                          color: Colors.red,
                        ),
                        label: const Text(
                          'Cancel Processing',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ] else if (video.status == VideoStatus.indexed) ...[
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          AppButton(
                            label: 'Re-index Video',
                            icon: Icons.refresh_rounded,
                            isSecondary: true,
                            onPressed: controller.reindexCurrentVideo,
                          ),
                          AppButton(
                            label: 'Proceed to Search',
                            icon: Icons.search_rounded,
                            onPressed: controller.goToSearch,
                          ),
                        ],
                      ),
                    ] else if (video.status == VideoStatus.error) ...[
                      AppButton(
                        label: 'Try Indexing Again',
                        icon: Icons.refresh_rounded,
                        onPressed: controller.reindexCurrentVideo,
                      ),
                    ] else ...[
                      AppButton(
                        label: 'Upload & Index Video',
                        icon: Icons.cloud_upload_rounded,
                        isLoading: controller.isProcessing,
                        onPressed: controller.startUploadAndIndex,
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPreview(BuildContext context) {
    final palette = AppPalette.of(context);
    return Obx(() {
      if (controller.previewError.value.isNotEmpty) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: palette.warning.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: palette.warning.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: palette.warning),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  controller.previewError.value,
                  style: TextStyle(fontSize: 12, color: palette.warning),
                ),
              ),
            ],
          ),
        );
      }

      final player = controller.previewPlayerController;
      if (!controller.isPreviewInitialized.value || player == null) {
        return Container(
          height: 180,
          decoration: BoxDecoration(
            color: palette.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: palette.divider),
          ),
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      }

      final aspectRatio = player.value.aspectRatio > 0
          ? player.value.aspectRatio
          : 16 / 9;

      return Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: aspectRatio,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  VideoPlayer(player),
                  GestureDetector(
                    onTap: controller.togglePreview,
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedOpacity(
                      opacity: controller.isPreviewPlaying.value ? 0 : 1,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            VideoProgressIndicator(
              player,
              allowScrubbing: true,
              padding: const EdgeInsets.symmetric(vertical: 6),
              colors: VideoProgressColors(
                playedColor: palette.success,
                bufferedColor: palette.secondaryText,
                backgroundColor: palette.divider,
              ),
            ),
            SizedBox(
              height: 42,
              child: Row(
                children: [
                  IconButton(
                    tooltip: controller.isPreviewPlaying.value
                        ? 'Pause preview'
                        : 'Play preview',
                    onPressed: controller.togglePreview,
                    icon: Icon(
                      controller.isPreviewPlaying.value
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: palette.onPrimary,
                    ),
                  ),
                  const Text(
                    'Preview selected video',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Future<void> _confirmReplace(BuildContext context) async {
    final shouldReplace = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Replace current video?'),
        content: const Text(
          'The current video will be removed from this app so you can select and index another one. The original file on your device will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep Video'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Replace'),
          ),
        ],
      ),
    );

    if (shouldReplace == true) {
      controller.removeCurrentVideo();
    }
  }
}
