import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../models/video_model.dart';

class StatusIndicator extends StatelessWidget {
  final VideoStatus status;
  final String? customText;

  const StatusIndicator({super.key, required this.status, this.customText});

  @override
  Widget build(BuildContext context) {
    final config = _getConfig(AppPalette.of(context));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config.borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (config.isLoading)
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(config.textColor),
              ),
            )
          else
            Icon(config.icon, size: 14, color: config.textColor),
          const SizedBox(width: 6),
          Text(
            customText ?? config.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: config.textColor,
            ),
          ),
        ],
      ),
    );
  }

  _StatusConfig _getConfig(AppPalette palette) {
    switch (status) {
      case VideoStatus.idle:
        return _StatusConfig(
          label: 'Idle',
          icon: Icons.hourglass_empty_rounded,
          backgroundColor: palette.surfaceVariant,
          borderColor: palette.divider,
          textColor: palette.secondaryText,
        );
      case VideoStatus.selected:
        return _StatusConfig(
          label: 'Ready to Upload',
          icon: Icons.file_present_rounded,
          backgroundColor: palette.info.withValues(alpha: 0.12),
          borderColor: palette.info.withValues(alpha: 0.35),
          textColor: palette.info,
        );
      case VideoStatus.uploading:
        return _StatusConfig(
          label: 'Uploading...',
          icon: Icons.cloud_upload_outlined,
          isLoading: true,
          backgroundColor: palette.warning.withValues(alpha: 0.14),
          borderColor: palette.warning.withValues(alpha: 0.4),
          textColor: palette.warning,
        );
      case VideoStatus.indexing:
        return _StatusConfig(
          label: 'Indexing Video...',
          icon: Icons.sync_rounded,
          isLoading: true,
          backgroundColor: palette.info.withValues(alpha: 0.12),
          borderColor: palette.info.withValues(alpha: 0.35),
          textColor: palette.info,
        );
      case VideoStatus.indexed:
        return _StatusConfig(
          label: 'Ready to Search',
          icon: Icons.check_circle_outline_rounded,
          backgroundColor: palette.success.withValues(alpha: 0.14),
          borderColor: palette.success.withValues(alpha: 0.4),
          textColor: palette.success,
        );
      case VideoStatus.error:
        return _StatusConfig(
          label: 'Failed',
          icon: Icons.error_outline_rounded,
          backgroundColor: palette.error.withValues(alpha: 0.14),
          borderColor: palette.error.withValues(alpha: 0.4),
          textColor: palette.error,
        );
    }
  }
}

class _StatusConfig {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final bool isLoading;

  _StatusConfig({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    this.isLoading = false,
  });
}
