import 'package:flutter/material.dart';

import 'dart:io';

import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/app_button.dart';
import '../../../shared/widgets/video_card.dart';
import '../../../shared/models/search_result_model.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  Widget _buildDiscoverySection() {
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            dividerColor: Colors.transparent,
            indicatorColor: const Color(0xFF1B4D3E),
            labelColor: const Color(0xFF1B4D3E),
            unselectedLabelColor: const Color(0xFF64748B),
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
            tabs: const [
              Tab(text: 'Discovery Feed'),
              Tab(text: 'Saved Observations'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: TabBarView(
              children: [_buildSightingsFeed(), _buildSavedObservations()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSightingsFeed() {
    return Obx(() {
      if (controller.discoveryService.isFetchingFeed.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.discoveryService.sightingsFeed.isEmpty) {
        return _buildEmptyDiscovery(
          'No recent sightings detected across your archive.',
        );
      }
      return ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: controller.discoveryService.sightingsFeed.length,
        itemBuilder: (context, index) {
          final result = controller.discoveryService.sightingsFeed[index];
          return _buildMomentCard(context, result);
        },
      );
    });
  }

  Widget _buildSavedObservations() {
    return Obx(() {
      if (controller.discoveryService.savedObservations.isEmpty) {
        return _buildEmptyDiscovery('You haven\'t saved any observations yet.');
      }
      return ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: controller.discoveryService.savedObservations.length,
        itemBuilder: (context, index) {
          final result = controller.discoveryService.savedObservations[index];
          return _buildMomentCard(context, result);
        },
      );
    });
  }

  Widget _buildMomentCard(BuildContext context, SearchResultModel result) {
    final thumbUrl = result.thumbnailUrl;

    void openPlayer() {
      var path = result.videoPath;
      if (path.isEmpty) {
        final match =
            controller.videoService.videoHistory.firstWhereOrNull(
              (v) => v.fileName == result.videoFileName,
            ) ??
            controller.currentVideo;
        if (match != null) {
          path = match.filePath;
        }
      }

      Get.toNamed(
        AppRoutes.player,
        arguments: {
          'videoPath': path,
          'videoName': result.videoFileName.isNotEmpty
              ? result.videoFileName
              : result.title,
          'title': result.title,
          'timestamp': result.timestampDuration,
          'timestampText': result.formattedTimestamp,
          'hasTimestamp': result.hasTimestamp,
          'isTimestampApproximate': result.isTimestampApproximate,
        },
      );
    }

    return GestureDetector(
      onTap: openPlayer,
      child: Container(
        width: 220,
        margin: const EdgeInsets.only(right: 16, bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                ),
                child: Stack(
                  children: [
                    if (thumbUrl != null && thumbUrl.isNotEmpty)
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(14),
                          ),
                          child: Image(
                            image: thumbUrl.startsWith('http')
                                ? NetworkImage(thumbUrl)
                                : FileImage(File(thumbUrl)),
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Center(
                              child: Icon(
                                Icons.movie_rounded,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                        ),
                      ),
                    Positioned.fill(
                      child: Container(
                        color: Colors.black26,
                        child: const Center(
                          child: Icon(
                            Icons.play_circle_fill_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B4D3E),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Start @ ${result.formattedTimestamp}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Obx(
                        () => IconButton(
                          icon: Icon(
                            controller.discoveryService.isBookmarked(result)
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            color: Colors.white,
                          ),
                          onPressed: () => controller.discoveryService
                              .toggleBookmark(result),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    result.videoFileName.isNotEmpty
                        ? result.videoFileName
                        : 'Wildlife Moment',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyDiscovery(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            color: Color(0xFFCBD5E1),
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.eco_rounded, color: Color(0xFF1B4D3E), size: 24),
            SizedBox(width: 8),
            Text(
              AppConstants.appName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B4D3E),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.key_rounded),
            tooltip: 'API Key Configuration',
            onPressed: () => _showApiKeyDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B4D3E), Color(0xFF2E7D32)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1B4D3E).withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Environmental Video Research',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Index wildlife footage and search moments using natural language powered by V-Modal AI.',
                      style: TextStyle(
                        color: Color(0xFFE8F5E9),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // SDK Configuration Status Widget
              Obx(() {
                final isConfigured = controller.vmodalService.isConfigured;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isConfigured
                        ? const Color(0xFFF0FDF4)
                        : const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isConfigured
                          ? const Color(0xFFBBF7D0)
                          : const Color(0xFFFDE68A),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isConfigured
                            ? Icons.check_circle_rounded
                            : Icons.info_outline_rounded,
                        color: isConfigured
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFD97706),
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isConfigured
                              ? 'V-Modal SDK active & authenticated'
                              : 'V-Modal API key needed to enable live search',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isConfigured
                                ? const Color(0xFF15803D)
                                : const Color(0xFFB45309),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _showApiKeyDialog(context),
                        child: Text(isConfigured ? 'Change' : 'Set Key'),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 24),

              // Quick Actions Section
              LayoutBuilder(
                builder: (context, constraints) {
                  final uploadButton = AppButton(
                    label: 'Upload Video',
                    icon: Icons.video_call_rounded,
                    onPressed: controller.goToUpload,
                  );
                  final searchButton = AppButton(
                    label: 'Search Footage',
                    icon: Icons.search_rounded,
                    isSecondary: true,
                    onPressed: controller.goToSearch,
                  );
                  final dashboardButton = AppButton(
                    label: 'Dashboard',
                    icon: Icons.bar_chart_rounded,
                    isSecondary: true,
                    onPressed: controller.goToDashboard,
                  );

                  if (constraints.maxWidth < 500) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        uploadButton,
                        const SizedBox(height: 10),
                        searchButton,
                        const SizedBox(height: 10),
                        dashboardButton,
                      ],
                    );
                  }

                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: uploadButton),
                          const SizedBox(width: 14),
                          Expanded(child: searchButton),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: dashboardButton),
                          const SizedBox(width: 14),
                          const Expanded(child: SizedBox.shrink()),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 28),

              // Active Video Section
              const Text(
                'Current Wildlife Footage',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 12),
              Obx(() {
                final video = controller.currentVideo;
                if (video == null) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.cloud_upload_outlined,
                          size: 42,
                          color: Color(0xFFA0AEC0),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No footage uploaded yet',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: Color(0xFF4A5568),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Select a wildlife video to upload and index using V-Modal.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF718096),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: controller.goToUpload,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Select Wildlife Footage'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B4D3E),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return VideoCard(
                  video: video,
                  onUploadTap: controller.goToUpload,
                  onSearchTap: controller.goToSearch,
                );
              }),
              const SizedBox(height: 28),

              // Tabs for Sightings and Bookmarks
              _buildDiscoverySection(),

              const SizedBox(height: 28),

              // Research Guide Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 20,
                          color: Color(0xFF475569),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'How EcoVision Works',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. Select environmental video footage from your device.\n'
                      '2. Upload & index it with V-Modal multimodal engine.\n'
                      '3. Query moments in natural language ("elephants near water").\n'
                      '4. Jump directly to matching video timestamps.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showApiKeyDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    var obscureApiKey = true;
    var isSaving = false;

    Future<void> saveKey(
      StateSetter updateDialog,
      BuildContext dialogContext,
    ) async {
      if (isSaving || !formKey.currentState!.validate()) return;
      updateDialog(() => isSaving = true);
      final saved = await controller.saveApiKey(
        controller.apiKeyController.text,
      );
      if (!dialogContext.mounted) return;
      if (saved) {
        Navigator.of(dialogContext).pop();
      } else {
        updateDialog(() => isSaving = false);
      }
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('V-Modal API Key'),
          content: Form(
            key: formKey,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter your V-Modal runtime API key to authorize indexing and search.',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: controller.apiKeyController,
                    autofocus: true,
                    enabled: !isSaving,
                    obscureText: obscureApiKey,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => saveKey(setState, dialogContext),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter an API key to continue.'
                        : null,
                    decoration: InputDecoration(
                      labelText: 'API key',
                      hintText: 'Enter your API key',
                      prefixIcon: const Icon(Icons.key_rounded),
                      suffixIcon: IconButton(
                        tooltip: obscureApiKey
                            ? 'Show API key'
                            : 'Hide API key',
                        onPressed: () {
                          setState(() => obscureApiKey = !obscureApiKey);
                        },
                        icon: Icon(
                          obscureApiKey
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving
                  ? null
                  : () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: isSaving
                  ? null
                  : () => saveKey(setState, dialogContext),
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save key'),
            ),
          ],
        ),
      ),
    );
  }
}
