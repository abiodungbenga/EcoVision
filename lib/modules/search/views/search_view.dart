import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../shared/widgets/app_bottom_navigation_bar.dart';
import '../../../shared/widgets/search_result_card.dart';
import '../controllers/search_controller.dart';

class SearchView extends GetView<SearchViewController> {
  const SearchView({super.key});

  Widget _buildSearchControls(BuildContext context) {
    final palette = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Research Filters:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: palette.secondaryText,
              ),
            ),
            Obx(
              () => Row(
                children: [
                  Text(
                    'Global Archive',
                    style: TextStyle(
                      fontSize: 12,
                      color: palette.secondaryText,
                    ),
                  ),
                  Switch.adaptive(
                    value: controller.isGlobalSearch.value,
                    onChanged: (v) => controller.isGlobalSearch.value = v,
                    activeTrackColor: palette.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: AppConstants.semanticChips.map((chip) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ActionChip(
                  label: Text(
                    chip['label']!,
                    style: TextStyle(fontSize: 12, color: palette.text),
                  ),
                  backgroundColor: palette.surfaceVariant,
                  side: BorderSide(color: palette.divider),
                  onPressed: () {
                    controller.queryTextController.text = chip['query']!;
                    controller.performSearch();
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Scaffold(
      bottomNavigationBar: const AppBottomNavigationBar(selectedIndex: 2),
      appBar: AppBar(title: const Text('Search Wildlife Footage')),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => Get.focusScope?.unfocus(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),

              Obx(() {
                final videos = controller.selectableVideos;
                if (videos.isEmpty) return const SizedBox.shrink();
                final selectedVideo = controller.currentVideo;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DropdownButtonFormField<String>(
                    initialValue:
                        videos.any((video) => video.id == selectedVideo?.id)
                        ? selectedVideo?.id
                        : null,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Search within your video library',
                      prefixIcon: Icon(Icons.video_library_outlined),
                    ),
                    hint: const Text('Choose a video'),
                    items: videos
                        .map(
                          (video) => DropdownMenuItem(
                            value: video.id,
                            child: Text(
                              '${video.fileName} · ${video.isIndexed ? 'Indexed' : 'Not indexed'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: controller.selectVideo,
                  ),
                );
              }),

              // Search Bar Input Container
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact = constraints.maxWidth < 420;

                      final imagePreview = Obx(() {
                        final file = controller.referenceImage.value;
                        if (file == null) return const SizedBox.shrink();

                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Stack(
                            alignment: Alignment.topRight,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  file,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              GestureDetector(
                                onTap: controller.clearReferenceImage,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      });

                      final input = Expanded(
                        child: TextField(
                          controller: controller.queryTextController,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => controller.performSearch(),
                          decoration: const InputDecoration(
                            hintText: 'Search or add reference image...',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                          ),
                        ),
                      );

                      final imageButton = IconButton(
                        icon: const Icon(Icons.add_a_photo_rounded),
                        tooltip: 'Add visual reference',
                        onPressed: controller.pickReferenceImage,
                        color: palette.primary,
                      );

                      final searchButton = Obx(
                        () => AppButton(
                          label: 'Search',
                          isLoading: controller.isSearching.value,
                          onPressed: controller.performSearch,
                        ),
                      );

                      if (isCompact) {
                        return Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.search_rounded,
                                  color: palette.primary,
                                  size: 24,
                                ),
                                const SizedBox(width: 10),
                                imagePreview,
                                input,
                                imageButton,
                              ],
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              width: double.infinity,
                              child: searchButton,
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            color: palette.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 10),
                          imagePreview,
                          input,
                          imageButton,
                          const SizedBox(width: 8),
                          searchButton,
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Global Archive Search Toggle & Semantic Chips
              _buildSearchControls(context),

              const SizedBox(height: 16),

              // Search Results Summary Banner or Loading / Empty States
              Expanded(
                child: Obx(() {
                  if (controller.isSearching.value) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              palette.primary,
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Searching V-Modal multimodal index...',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: palette.text,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Analyzing video moments, visible text & speech...',
                            style: TextStyle(
                              fontSize: 13,
                              color: palette.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (controller.errorMessage.value.isNotEmpty) {
                    return ErrorState(
                      title: 'Search Error',
                      message: controller.errorMessage.value,
                      onRetry: controller.performSearch,
                    );
                  }

                  if (!controller.hasSearched.value) {
                    return const EmptyState(
                      title: 'Search your footage',
                      description: 'Enter a natural language description above to find specific moments in your indexed video.',
                      icon: Icons.travel_explore_rounded,
                    );
                  }

                  if (controller.searchResults.isEmpty) {
                    return EmptyState(
                      title: 'No relevant moments found',
                      description:
                          'No matching moments were found in the indexed footage for "${controller.activeQuery.value}".',
                      icon: Icons.search_off_rounded,
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary Header
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 4,
                        ),
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 500),
                              child: Text(
                                'Results for "${controller.activeQuery.value}"',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: palette.text,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${controller.searchResults.length} moments found (${controller.executionTimeMs.value.round()} ms)',
                              style: TextStyle(
                                fontSize: 12,
                                color: palette.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Results List
                      Expanded(
                        child: ListView.builder(
                          itemCount: controller.searchResults.length,
                          itemBuilder: (context, index) {
                            final item = controller.searchResults[index];
                            return SearchResultCard(
                              result: item,
                              onTap: () {
                                Get.toNamed(
                                  AppRoutes.player,
                                  arguments: {
                                    'videoPath': item.videoPath,
                                    'videoName': item.videoFileName.isNotEmpty
                                        ? item.videoFileName
                                        : item.title,
                                    'title': item.title,
                                    'timestamp': item.timestampDuration,
                                    'timestampText': item.formattedTimestamp,
                                    'hasTimestamp': item.hasTimestamp,
                                    'isTimestampApproximate':
                                        item.isTimestampApproximate,
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
