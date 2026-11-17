import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../models/video_model.dart';
import 'status_indicator.dart';

class VideoCard extends StatelessWidget {
  final VideoModel video;
  final VoidCallback? onTap;
  final VoidCallback? onUploadTap;
  final VoidCallback? onSearchTap;

  const VideoCard({
    super.key,
    required this.video,
    this.onTap,
    this.onUploadTap,
    this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: palette.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.video_file_rounded,
                    color: palette.primary,
                    size: 28,
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
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: palette.text,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Size: ${video.formattedSize} • Collection: ${video.collectionName}',
                        style: TextStyle(
                          fontSize: 12,
                          color: palette.secondaryText,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                StatusIndicator(status: video.status),
                if (video.status == VideoStatus.indexed && onSearchTap != null)
                  ElevatedButton.icon(
                    onPressed: onSearchTap,
                    icon: const Icon(Icons.search, size: 16),
                    label: const Text('Search'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: palette.primary,
                      foregroundColor: palette.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  )
                else if (video.status == VideoStatus.selected &&
                    onUploadTap != null)
                  ElevatedButton.icon(
                    onPressed: onUploadTap,
                    icon: const Icon(Icons.cloud_upload_outlined, size: 16),
                    label: const Text('Upload & Index'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: palette.info,
                      foregroundColor: palette.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
              ],
            ),
            if (video.isUploading) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: video.uploadProgress / 100,
                  backgroundColor: palette.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(palette.primary),
                  minHeight: 6,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
