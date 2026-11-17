import 'package:flutter/material.dart';

import 'dart:io';

import 'package:get/get.dart';

import '../../app/theme/app_colors.dart';
import '../models/search_result_model.dart';
import '../models/observation_model.dart';
import '../../core/services/discovery_service.dart';
import '../../core/services/research_service.dart';

class SearchResultCard extends StatelessWidget {
  final SearchResultModel result;
  final VoidCallback onTap;

  const SearchResultCard({
    super.key,
    required this.result,
    required this.onTap,
  });

  Widget _buildThumbnail(BuildContext context) {
    final palette = AppPalette.of(context);
    final url = result.thumbnailUrl;
    if (url == null || url.isEmpty) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: palette.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: palette.divider),
        ),
        child: Icon(
          Icons.image_not_supported_rounded,
          color: palette.secondaryText,
          size: 24,
        ),
      );
    }

    final isLocal = !url.startsWith('http') && !url.startsWith('https');

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: palette.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: isLocal
                ? Image.file(
                    File(url),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Center(
                      child: Icon(Icons.broken_image_rounded, size: 20),
                    ),
                  )
                : Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Center(
                      child: Icon(Icons.broken_image_rounded, size: 20),
                    ),
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                  ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black26,
              child: const Center(
                child: Icon(
                  Icons.play_circle_fill_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final discoveryService = Get.find<DiscoveryService>();
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildThumbnail(context),
              const SizedBox(width: 12),

              // Title and metadata details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: palette.text,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (result.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        result.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: palette.secondaryText,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: palette.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.play_arrow_rounded,
                                size: 12,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                result.formattedTimestamp,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: palette.onPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (result.scoreText.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: palette.info.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: palette.info.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Text(
                              'Match: ${result.scoreText}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: palette.info,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Text(
                            result.videoFileName,
                            style: TextStyle(
                              fontSize: 11,
                              color: palette.secondaryText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.bookmark_add_rounded, size: 14),
                      label: const Text('Save observation'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: palette.primary,
                        side: BorderSide(color: palette.primary),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => _showSaveObservationSheet(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Bookmark and Arrow
              Column(
                children: [
                  Obx(
                    () => IconButton(
                      icon: Icon(
                        discoveryService.isBookmarked(result)
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        color: palette.primary,
                        size: 20,
                      ),
                      onPressed: () => discoveryService.toggleBookmark(result),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: palette.surfaceVariant,
                      shape: BoxShape.circle,
                      border: Border.all(color: palette.divider),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: palette.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showSaveObservationSheet(BuildContext context) async {
    final palette = AppPalette.of(context);
    String guessedSpecies = 'Wildlife';
    final queryLower = result.query.toLowerCase();
    if (queryLower.contains('elephant')) {
      guessedSpecies = 'Elephant';
    } else if (queryLower.contains('bird')) {
      guessedSpecies = 'Bird';
    } else if (queryLower.contains('lion')) {
      guessedSpecies = 'Lion';
    } else if (queryLower.contains('antelope')) {
      guessedSpecies = 'Antelope';
    } else if (queryLower.contains('bear')) {
      guessedSpecies = 'Bear';
    } else if (queryLower.contains('human') || queryLower.contains('people')) {
      guessedSpecies = 'Human';
    } else if (result.query.isNotEmpty) {
      guessedSpecies =
          result.query.split(' ').first.capitalizeFirst ?? result.query;
    }

    final speciesController = TextEditingController(text: guessedSpecies);
    final notesController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    const suggestions = [
      'Elephant',
      'Lion',
      'Bird',
      'Bear',
      'Antelope',
      'Giraffe',
      'Human',
    ];

    final shouldSave = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setState) {
          return Container(
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                20 + MediaQuery.viewInsetsOf(sheetContext).bottom,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: palette.divider,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: palette.surfaceVariant,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.bookmark_add_outlined,
                              color: palette.primary,
                              size: 21,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Save observation',
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.4,
                                    color: palette.text,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'Add a species and optional field notes.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: palette.secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Close',
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: palette.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.play_circle_outline_rounded,
                              color: palette.primary,
                              size: 19,
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                '${result.formattedTimestamp}  ·  ${result.videoFileName}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: palette.secondaryText,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Species',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: palette.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 7),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: suggestions.map((species) {
                            final selected =
                                speciesController.text.trim().toLowerCase() ==
                                species.toLowerCase();
                            return Padding(
                              padding: const EdgeInsets.only(right: 7),
                              child: ChoiceChip(
                                label: Text(species),
                                selected: selected,
                                showCheckmark: false,
                                selectedColor: palette.surfaceVariant,
                                side: BorderSide(
                                  color: selected
                                      ? palette.primary
                                      : palette.divider,
                                ),
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: selected
                                      ? palette.primary
                                      : palette.secondaryText,
                                ),
                                onSelected: (_) {
                                  setState(() {
                                    speciesController.text = species;
                                  });
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 11),
                      TextFormField(
                        controller: speciesController,
                        textCapitalization: TextCapitalization.words,
                        onChanged: (_) => setState(() {}),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Enter a species or animal category.'
                            : null,
                        decoration: const InputDecoration(
                          labelText: 'Species or animal category',
                          hintText: 'e.g. Elephant, Bird, Lion',
                          prefixIcon: Icon(Icons.pets_outlined, size: 20),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: notesController,
                        minLines: 2,
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Field notes (optional)',
                          hintText: 'Add a detail you want to remember',
                          prefixIcon: Icon(Icons.notes_outlined, size: 20),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        icon: const Icon(Icons.bookmark_add_outlined, size: 19),
                        label: const Text('Save to observations'),
                        onPressed: () {
                          if (!formKey.currentState!.validate()) return;
                          Navigator.of(sheetContext).pop(true);
                        },
                      ),
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        child: const Text('Not now'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );

    final speciesName = speciesController.text.trim();
    final notes = notesController.text.trim();
    speciesController.dispose();
    notesController.dispose();
    if (shouldSave != true) return;

    final researchService = Get.find<ResearchService>();
    final observation = ObservationModel(
      id: 'obs_${DateTime.now().millisecondsSinceEpoch}',
      species: speciesName,
      videoId: result.id,
      videoName: result.videoFileName,
      videoPath: result.videoPath,
      timestampMs: result.timestampMs,
      formattedTimestamp: result.formattedTimestamp,
      searchQuery: result.query,
      createdAt: DateTime.now(),
      thumbnailUrl: result.thumbnailUrl,
      notes: notes.isEmpty ? null : notes,
    );

    try {
      final success = await researchService.saveObservation(observation);
      if (success) {
        Get.snackbar(
          'Observation saved',
          'Saved "$speciesName" at ${result.formattedTimestamp}.',
          backgroundColor: palette.surfaceVariant,
          colorText: palette.success,
          icon: Icon(Icons.check_circle_rounded, color: palette.success),
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );
      } else {
        Get.snackbar(
          'Already saved',
          'This observation is already in your research records.',
          backgroundColor: palette.surfaceVariant,
          colorText: palette.warning,
          icon: Icon(Icons.info_rounded, color: palette.warning),
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );
      }
    } catch (error) {
      Get.snackbar(
        'Could not save observation',
        'Please try again. $error',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    }
  }
}
