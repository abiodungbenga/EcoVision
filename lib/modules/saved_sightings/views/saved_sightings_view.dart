import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/services/discovery_service.dart';
import '../../../core/services/video_service.dart';
import '../../../shared/models/search_result_model.dart';
import '../../../shared/widgets/app_bottom_navigation_bar.dart';

enum SavedTimestampFilter { any, timestamped, untimestamped }

List<SearchResultModel> filterSavedSightings(
  Iterable<SearchResultModel> sightings, {
  String query = '',
  String? videoFileName,
  SavedTimestampFilter timestampFilter = SavedTimestampFilter.any,
}) {
  final normalizedQuery = query.trim().toLowerCase();
  return sightings.where((sighting) {
    final matchesQuery =
        normalizedQuery.isEmpty ||
        sighting.title.toLowerCase().contains(normalizedQuery) ||
        sighting.description.toLowerCase().contains(normalizedQuery) ||
        sighting.query.toLowerCase().contains(normalizedQuery) ||
        sighting.videoFileName.toLowerCase().contains(normalizedQuery);
    final matchesVideo =
        videoFileName == null || sighting.videoFileName == videoFileName;
    final matchesTimestamp = switch (timestampFilter) {
      SavedTimestampFilter.any => true,
      SavedTimestampFilter.timestamped => sighting.hasTimestamp,
      SavedTimestampFilter.untimestamped => !sighting.hasTimestamp,
    };
    return matchesQuery && matchesVideo && matchesTimestamp;
  }).toList();
}

class SavedSightingsView extends StatefulWidget {
  const SavedSightingsView({super.key});

  @override
  State<SavedSightingsView> createState() => _SavedSightingsViewState();
}

class _SavedSightingsViewState extends State<SavedSightingsView> {
  final DiscoveryService _discoveryService = Get.find<DiscoveryService>();
  final VideoService _videoService = Get.find<VideoService>();
  final TextEditingController _searchController = TextEditingController();

  static const _allVideosValue = '__all_videos__';

  String _query = '';
  String? _selectedVideo;
  SavedTimestampFilter _timestampFilter = SavedTimestampFilter.any;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openPlayer(SearchResultModel sighting) {
    var path = sighting.videoPath;
    if (path.isEmpty) {
      final video = _videoService.videoHistory.firstWhereOrNull(
        (item) => item.fileName == sighting.videoFileName,
      );
      if (video != null) path = video.filePath;
    }

    Get.toNamed(
      AppRoutes.player,
      arguments: {
        'videoPath': path,
        'videoName': sighting.videoFileName.isNotEmpty
            ? sighting.videoFileName
            : sighting.title,
        'title': sighting.title,
        'timestamp': sighting.timestampDuration,
        'timestampText': sighting.formattedTimestamp,
        'hasTimestamp': sighting.hasTimestamp,
        'isTimestampApproximate': sighting.isTimestampApproximate,
      },
    );
  }

  ImageProvider? _thumbnail(String? path) {
    if (path == null || path.isEmpty) return null;
    return path.startsWith('http') ? NetworkImage(path) : FileImage(File(path));
  }

  Widget _buildSightingCard(BuildContext context, SearchResultModel sighting) {
    final palette = AppPalette.of(context);
    final image = _thumbnail(sighting.thumbnailUrl);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: palette.divider),
      ),
      child: InkWell(
        onTap: () => _openPlayer(sighting),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (image != null)
                    Image(
                      image: image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _thumbnailPlaceholder(palette),
                    )
                  else
                    _thumbnailPlaceholder(palette),
                  Align(
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.play_circle_fill_rounded,
                      color: Colors.white.withValues(alpha: 0.94),
                      size: 40,
                    ),
                  ),
                  if (sighting.hasTimestamp)
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.68),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          sighting.formattedTimestamp,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton.filledTonal(
                      tooltip: 'Remove from saved',
                      visualDensity: VisualDensity.compact,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.55),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.bookmark_rounded, size: 19),
                      onPressed: () =>
                          _discoveryService.toggleBookmark(sighting),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(11, 10, 11, 9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sighting.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          Icons.video_library_outlined,
                          size: 14,
                          color: palette.secondaryText,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            sighting.videoFileName.isNotEmpty
                                ? sighting.videoFileName
                                : 'Unknown video',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: palette.secondaryText,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumbnailPlaceholder(AppPalette palette) {
    return ColoredBox(
      color: palette.surfaceVariant,
      child: Center(
        child: Icon(
          Icons.nature_outlined,
          color: palette.secondaryText,
          size: 34,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, {required bool hasFilters}) {
    final palette = AppPalette.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasFilters
                  ? Icons.filter_list_off_rounded
                  : Icons.bookmarks_outlined,
              size: 44,
              color: palette.secondaryText,
            ),
            const SizedBox(height: 12),
            Text(
              hasFilters
                  ? 'No sightings match these filters'
                  : 'No saved sightings yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: palette.text,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hasFilters ? 'Try another search or clear the selected filters.' : 'Bookmark a moment from your sightings feed to keep it here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.secondaryText, fontSize: 13),
            ),
            if (hasFilters) ...[
              const SizedBox(height: 14),
              TextButton(
                onPressed: () {
                  setState(() {
                    _query = '';
                    _searchController.clear();
                    _selectedVideo = null;
                    _timestampFilter = SavedTimestampFilter.any;
                  });
                },
                child: const Text('Clear filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Scaffold(
      bottomNavigationBar: const AppBottomNavigationBar(selectedIndex: 0),
      appBar: AppBar(title: const Text('Saved sightings')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      hintText: 'Search saved sightings',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Obx(() {
                    final sightings = _discoveryService.savedObservations;
                    final videos =
                        sightings
                            .map((item) => item.videoFileName)
                            .where((name) => name.isNotEmpty)
                            .toSet()
                            .toList()
                          ..sort();

                    return Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String?>(
                            initialValue: _selectedVideo ?? _allVideosValue,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Video',
                              prefixIcon: Icon(Icons.video_library_outlined),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: _allVideosValue,
                                child: Text('All videos'),
                              ),
                              ...videos.map(
                                (video) => DropdownMenuItem<String?>(
                                  value: video,
                                  child: Text(
                                    video,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (value) => setState(
                              () => _selectedVideo = value == _allVideosValue
                                  ? null
                                  : value,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        PopupMenuButton<SavedTimestampFilter>(
                          tooltip: 'Filter by timestamp',
                          initialValue: _timestampFilter,
                          onSelected: (value) =>
                              setState(() => _timestampFilter = value),
                          itemBuilder: (context) => const [
                            PopupMenuItem<SavedTimestampFilter>(
                              value: SavedTimestampFilter.any,
                              child: Text('Any timestamp'),
                            ),
                            PopupMenuItem<SavedTimestampFilter>(
                              value: SavedTimestampFilter.timestamped,
                              child: Text('Timestamped'),
                            ),
                            PopupMenuItem<SavedTimestampFilter>(
                              value: SavedTimestampFilter.untimestamped,
                              child: Text('No timestamp'),
                            ),
                          ],
                          child: Container(
                            height: 56,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color:
                                  _timestampFilter == SavedTimestampFilter.any
                                  ? palette.surface
                                  : palette.primary.withValues(alpha: 0.1),
                              border: Border.all(
                                color:
                                    _timestampFilter == SavedTimestampFilter.any
                                    ? palette.divider
                                    : palette.primary,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.filter_list_rounded,
                                  color:
                                      _timestampFilter ==
                                          SavedTimestampFilter.any
                                      ? palette.secondaryText
                                      : palette.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _timestampFilter ==
                                          SavedTimestampFilter.timestamped
                                      ? 'Timed'
                                      : _timestampFilter ==
                                            SavedTimestampFilter.untimestamped
                                      ? 'Untimed'
                                      : 'Filter',
                                  style: TextStyle(
                                    color: palette.text,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
            Expanded(
              child: Obx(() {
                final allSightings = _discoveryService.savedObservations;
                final sightings = filterSavedSightings(
                  allSightings,
                  query: _query,
                  videoFileName: _selectedVideo,
                  timestampFilter: _timestampFilter,
                );
                if (sightings.isEmpty) {
                  return _buildEmptyState(
                    context,
                    hasFilters:
                        allSightings.isNotEmpty ||
                        _query.isNotEmpty ||
                        _selectedVideo != null ||
                        _timestampFilter != SavedTimestampFilter.any,
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth >= 1000
                        ? 4
                        : constraints.maxWidth >= 650
                        ? 3
                        : 2;
                    return CustomScrollView(
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          sliver: SliverToBoxAdapter(
                            child: Text(
                              '${sightings.length} ${sightings.length == 1 ? 'sighting' : 'sightings'}',
                              style: TextStyle(
                                color: palette.secondaryText,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                          sliver: SliverGrid(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) =>
                                  _buildSightingCard(context, sightings[index]),
                              childCount: sightings.length,
                            ),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 0.78,
                                ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
