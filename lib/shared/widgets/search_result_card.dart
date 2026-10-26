import 'package:flutter/material.dart';

import 'dart:io';

import 'package:get/get.dart';

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

  Widget _buildThumbnail() {
    final url = result.thumbnailUrl;
    if (url == null || url.isEmpty) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFFF7FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Icon(
          Icons.image_not_supported_rounded,
          color: Color(0xFFA0AEC0),
          size: 24,
        ),
      );
    }

    final isLocal = !url.startsWith('http') && !url.startsWith('https');

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFFEDF2F7),
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
              _buildThumbnail(),
              const SizedBox(width: 12),

              // Title and metadata details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (result.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        result.description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF718096),
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
                            color: const Color(0xFF1B4D3E),
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
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
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
                              color: const Color(0xFFEBF8FF),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFFBEE3F8),
                              ),
                            ),
                            child: Text(
                              'Match: ${result.scoreText}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2B6CB0),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Text(
                            result.videoFileName,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFFA0AEC0),
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
                      label: const Text(
                        'Save Observation',
                        style: TextStyle(fontSize: 11),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1B4D3E),
                        side: const BorderSide(color: Color(0xFF1B4D3E)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => _showSaveObservationDialog(context),
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
                        color: const Color(0xFF1B4D3E),
                        size: 20,
                      ),
                      onPressed: () => discoveryService.toggleBookmark(result),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7FAFC),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: Color(0xFF1B4D3E),
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

  Future<void> _showSaveObservationDialog(BuildContext context) async {
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

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            contentPadding: const EdgeInsets.all(20),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B4D3E).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.bookmark_add_rounded,
                    color: Color(0xFF1B4D3E),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Save Field Observation',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        'Record timestamped finding',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.play_circle_fill_rounded,
                            color: Color(0xFF1B4D3E),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '@ ${result.formattedTimestamp} in ${result.videoFileName}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF334155),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Quick Species Suggestions:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: suggestions.map((s) {
                          final isSelected =
                              speciesController.text.trim().toLowerCase() ==
                              s.toLowerCase();
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(s),
                              selected: isSelected,
                              selectedColor: const Color(0xFF1B4D3E),
                              labelStyle: TextStyle(
                                fontSize: 11,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF334155),
                              ),
                              onSelected: (_) {
                                setState(() {
                                  speciesController.text = s;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: speciesController,
                      textCapitalization: TextCapitalization.words,
                      onChanged: (_) => setState(() {}),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Enter a species or animal category.'
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Species / Animal Category',
                        hintText: 'e.g. Elephant, Bird, Lion',
                        prefixIcon: Icon(Icons.pets_rounded, size: 20),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Field Notes (optional)',
                        hintText: 'e.g. Observed near the water source',
                        prefixIcon: Icon(Icons.notes_rounded, size: 20),
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actionsPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('Save Record'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B4D3E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;
                  Navigator.pop(dialogContext, true);
                },
              ),
            ],
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
          backgroundColor: const Color(0xFFF0FDF4),
          colorText: const Color(0xFF15803D),
          icon: const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF15803D),
          ),
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );
      } else {
        Get.snackbar(
          'Already saved',
          'This observation is already in your research records.',
          backgroundColor: const Color(0xFFFFFBEB),
          colorText: const Color(0xFFB45309),
          icon: const Icon(Icons.info_rounded, color: Color(0xFFB45309)),
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
