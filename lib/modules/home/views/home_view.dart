import 'dart:io';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:features_tour/features_tour.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/app_button.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../../shared/widgets/video_card.dart';
import '../../../shared/models/search_result_model.dart';
import '../controllers/home_controller.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final HomeController controller = Get.find<HomeController>();
  final FeaturesTourController _tourController = FeaturesTourController(
    'ecovision-home',
  );
  final Map<int, GlobalKey> _tourKeys = {
    for (var index = 0; index < 6; index++) index: GlobalKey(),
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _tourController.start(
          context,
          delay: const Duration(milliseconds: 350),
        );
      }
    });
  }

  Widget _tourStep({
    required BuildContext context,
    required int index,
    required String title,
    required String description,
    required Widget child,
  }) {
    final palette = AppPalette.of(context);
    return FeaturesTour(
      key: _tourKeys[index],
      controller: _tourController,
      index: index.toDouble(),
      introduce: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              color: palette.text,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            description,
            style: TextStyle(
              color: palette.secondaryText,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'STEP ${index + 1} OF 6',
            style: TextStyle(
              color: palette.primary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
      onBeforeIntroduce: () async {
        final target = _tourKeys[index]?.currentContext;
        if (target != null) {
          await Scrollable.ensureVisible(
            target,
            duration: const Duration(milliseconds: 380),
            curve: Curves.easeInOutCubic,
            alignment: 0.3,
          );
        }
      },
      child: child,
    );
  }

  Widget _buildDiscoverySection(BuildContext context) {
    final palette = AppPalette.of(context);
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            dividerColor: Colors.transparent,
            indicatorColor: palette.primary,
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: palette.primary,
            unselectedLabelColor: palette.secondaryText,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            tabs: const [
              Tab(text: 'Recent sightings'),
              Tab(text: 'Saved'),
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
          context,
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
        return _buildEmptyDiscovery(
          context,
          'You haven\'t saved any observations yet.',
        );
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
    final palette = AppPalette.of(context);
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
          color: palette.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: palette.divider),
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
                decoration: BoxDecoration(
                  color: palette.surfaceVariant,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Stack(
                  children: [
                    if (thumbUrl != null && thumbUrl.isNotEmpty)
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child: Image(
                            image: thumbUrl.startsWith('http')
                                ? NetworkImage(thumbUrl)
                                : FileImage(File(thumbUrl)),
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Center(
                              child: Icon(
                                Icons.movie_rounded,
                                color: palette.secondaryText,
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
                          color: palette.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Start @ ${result.formattedTimestamp}',
                          style: TextStyle(
                            color: palette.onPrimary,
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
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: palette.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    result.videoFileName.isNotEmpty
                        ? result.videoFileName
                        : 'Wildlife Moment',
                    style: TextStyle(
                      fontSize: 12,
                      color: palette.secondaryText,
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

  Widget _buildEmptyDiscovery(BuildContext context, String message) {
    final palette = AppPalette.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.nature_outlined, color: palette.secondaryText, size: 32),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: palette.secondaryText),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Scaffold(
      appBar: AppBar(
        title: _tourStep(
          context: context,
          index: 0,
          title: 'Welcome to EcoVision',
          description: 'Your field footage, sightings, and saved observations all come together here.',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppLogo(),
              const SizedBox(width: 8),
              const Text(AppConstants.appName),
            ],
          ),
        ),
        actions: [
          PopupMenuButton<AdaptiveThemeMode>(
            tooltip: 'Appearance',
            initialValue: AdaptiveTheme.of(context).mode,
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.dark_mode_outlined
                  : Icons.light_mode_outlined,
            ),
            onSelected: (mode) => AdaptiveTheme.of(context).setThemeMode(mode),
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: AdaptiveThemeMode.system,
                child: Row(
                  children: [
                    Icon(Icons.brightness_auto_outlined),
                    SizedBox(width: 12),
                    Text('System'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: AdaptiveThemeMode.light,
                child: Row(
                  children: [
                    Icon(Icons.light_mode_outlined),
                    SizedBox(width: 12),
                    Text('Light'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: AdaptiveThemeMode.dark,
                child: Row(
                  children: [
                    Icon(Icons.dark_mode_outlined),
                    SizedBox(width: 12),
                    Text('Dark'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.insights_outlined),
            tooltip: 'Research dashboard',
            onPressed: controller.goToDashboard,
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'API Key Configuration',
            onPressed: () => _showApiKeyDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: palette.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Text(
                    'FIELDWORK, MADE SEARCHABLE',
                    style: TextStyle(
                      color: palette.secondaryText,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Find the moment\nthat matters.',
                style: TextStyle(
                  color: palette.text,
                  fontSize: 38,
                  height: 1.08,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Bring your wildlife footage together and discover the details worth a closer look.',
                style: TextStyle(
                  color: palette.secondaryText,
                  fontSize: 15,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _tourStep(
                      context: context,
                      index: 1,
                      title: 'Bring in your footage',
                      description: 'Choose a wildlife clip from your device. EcoVision indexes it so you can find specific moments later.',
                      child: AppButton(
                        label: 'Upload',
                        icon: Icons.add_rounded,
                        onPressed: controller.goToUpload,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _tourStep(
                      context: context,
                      index: 2,
                      title: 'Search by what you saw',
                      description: 'Describe a scene in everyday language and jump straight to matching moments in your footage.',
                      child: AppButton(
                        label: 'Search',
                        icon: Icons.search_rounded,
                        isSecondary: true,
                        onPressed: controller.goToSearch,
                      ),
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: controller.goToDashboard,
                  icon: const Icon(Icons.insights_outlined, size: 17),
                  label: const Text('Open research dashboard'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.only(left: 2, top: 12, bottom: 4),
                    foregroundColor: palette.secondaryText,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              _tourStep(
                context: context,
                index: 3,
                title: 'Connect your archive',
                description: 'Add your V-Modal API key here to enable indexing and search across your footage.',
                child: Obx(() {
                  final isConfigured = controller.vmodalService.isConfigured;
                  return Container(
                    padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                    decoration: BoxDecoration(
                      color: palette.surface.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: palette.divider),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isConfigured
                                ? palette.success
                                : palette.warning,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Text(
                            isConfigured
                                ? 'Archive connection is ready'
                                : 'Connect your archive to get started',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: palette.secondaryText,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _showApiKeyDialog(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(isConfigured ? 'Manage' : 'Connect'),
                        ),
                      ],
                    ),
                  );
                }),
              ),
              const SizedBox(height: 34),
              _tourStep(
                context: context,
                index: 4,
                title: 'Your current footage',
                description: 'Check the clip you selected, see its indexing status, and continue searching when it is ready.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Your footage',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.5,
                        color: palette.text,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'The clips you are currently exploring.',
                      style: TextStyle(
                        fontSize: 13,
                        color: palette.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Obx(() {
                      final video = controller.currentVideo;
                      if (video == null) {
                        return Container(
                          padding: const EdgeInsets.fromLTRB(20, 26, 20, 22),
                          decoration: BoxDecoration(
                            color: palette.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: palette.divider),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: palette.surfaceVariant,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.video_library_outlined,
                                  size: 23,
                                  color: palette.primary,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'A fresh perspective starts here',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: palette.text,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Add a clip to make its moments searchable.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.45,
                                  color: palette.secondaryText,
                                ),
                              ),
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                onPressed: controller.goToUpload,
                                icon: const Icon(Icons.add_rounded, size: 18),
                                label: const Text('Add your first clip'),
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
                  ],
                ),
              ),
              const SizedBox(height: 36),
              _tourStep(
                context: context,
                index: 5,
                title: 'Keep the moments that matter',
                description: 'Browse recent sightings, open a moment in the player, or save discoveries to revisit later.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Moments worth keeping',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.5,
                        color: palette.text,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'A closer look at recent sightings and saved finds.',
                      style: TextStyle(
                        fontSize: 13,
                        color: palette.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDiscoverySection(context),
                  ],
                ),
              ),
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
