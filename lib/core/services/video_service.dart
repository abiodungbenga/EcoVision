import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:localstore/localstore.dart';

import '../../shared/models/video_model.dart';
import '../errors/app_exception.dart';

class VideoService extends GetxService {
  /// Max length VModal accepts for a stream name.
  static const int _streamNameMax = 80;
  static const String _streamPrefix = 'vid_';
  static const String _videoCollection = 'uploaded_videos';
  static const String _settingsCollection = 'video_library_settings';
  static const String _activeVideoDocument = 'active_video';

  final Localstore _db = Localstore.instance;
  final Completer<void> _historyLoadCompleter = Completer<void>();
  Object? _historyLoadError;

  final isHistoryLoaded = false.obs;
  Future<void> get historyLoaded => _historyLoadCompleter.future;

  /// Builds a per-video stream name that VModal will accept.
  ///
  /// Each video gets its own stream so a search only ever returns moments from
  /// the selected video. The SDK validates stream names against
  /// `^[A-Za-z0-9_]+$` (max 80 chars) and throws `ValidationException`
  /// otherwise, so dots, dashes and spaces in the filename must all be folded
  /// to underscores — `bear video.mp4` becomes `vid_bear_video_mp4_<id>`.
  static String buildStreamName(String fileName, String id) {
    final suffix = '_$id';
    final budget = _streamNameMax - _streamPrefix.length - suffix.length;

    var base = fileName
        .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');

    if (budget <= 0) return 'vid$suffix';
    if (base.length > budget) base = base.substring(0, budget);
    base = base.replaceAll(RegExp(r'_+$'), '');

    // Filenames that sanitize to nothing (e.g. "日本語.mp4") still need a
    // unique, valid stream.
    return base.isEmpty ? 'vid$suffix' : '$_streamPrefix$base$suffix';
  }

  final Rxn<VideoModel> _currentVideo = Rxn<VideoModel>();
  VideoModel? get currentVideo => _currentVideo.value;

  final RxList<VideoModel> _videoHistory = <VideoModel>[].obs;
  RxList<VideoModel> get videoHistory => _videoHistory;

  @override
  void onInit() {
    super.onInit();
    unawaited(_loadVideoHistory());
  }

  Future<void> _loadVideoHistory() async {
    try {
      final items = await _db.collection(_videoCollection).get();
      final loadedVideos = <VideoModel>[];
      if (items != null) {
        for (final entry in items.entries) {
          try {
            loadedVideos.add(
              VideoModel.fromJson(Map<String, dynamic>.from(entry.value)),
            );
          } catch (error, stackTrace) {
            _historyLoadError ??= error;
            developer.log(
              'Skipping invalid saved video "${entry.key}".',
              name: 'VideoService',
              error: error,
              stackTrace: stackTrace,
            );
          }
        }
      }

      loadedVideos.sort((a, b) => b.id.compareTo(a.id));
      _videoHistory.assignAll(loadedVideos);

      final activeVideo = await _db
          .collection(_settingsCollection)
          .doc(_activeVideoDocument)
          .get();
      if (activeVideo != null) {
        final activeId = activeVideo['videoId'] as String?;
        _currentVideo.value = loadedVideos.firstWhereOrNull(
          (video) => video.id == activeId,
        );
      } else {
        _currentVideo.value = loadedVideos.firstWhereOrNull(
          (video) => video.isIndexed,
        );
      }
    } catch (error, stackTrace) {
      _historyLoadError = error;
      developer.log(
        'Could not load the saved video library.',
        name: 'VideoService',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      isHistoryLoaded.value = true;
      _historyLoadCompleter.complete();
    }
  }

  /// Pick a video file from local storage using file_picker.
  Future<VideoModel?> pickVideo({String? apiKeyProfileId}) async {
    await historyLoaded;
    if (_historyLoadError != null) {
      throw StateError(
        'The saved video library could not be loaded '
        '(${_historyLoadError.toString()}). Restart the app before uploading '
        'another file to avoid creating a duplicate.',
      );
    }

    try {
      final result = await FilePicker.pickFiles(type: FileType.video);

      if (result.isEmpty) {
        return null; // User cancelled
      }

      final file = result.first;
      final path = file.path;
      if (path == null || path.trim().isEmpty || !File(path).existsSync()) {
        throw AppException(
          'The selected video file has no valid readable path.',
        );
      }

      final selectedFile = File(path);
      final fileSize = selectedFile.lengthSync();
      final lastModifiedMs = selectedFile
          .lastModifiedSync()
          .millisecondsSinceEpoch;
      final existing = findExistingLocalVideo(
        filePath: path,
        sizeBytes: fileSize,
        lastModifiedMs: lastModifiedMs,
        apiKeyProfileId: apiKeyProfileId,
      );
      if (existing != null) {
        await setCurrentVideo(existing);
        return existing;
      }

      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final video = VideoModel(
        id: id,
        fileName: file.name,
        filePath: path,
        sizeBytes: fileSize,
        lastModifiedMs: lastModifiedMs,
        apiKeyProfileId: apiKeyProfileId,
        status: VideoStatus.selected,
        streamName: buildStreamName(file.name, id),
      );

      await setCurrentVideo(video);
      return video;
    } catch (e) {
      throw AppException('Error selecting video: ${e.toString()}');
    }
  }

  Future<void> setCurrentVideo(VideoModel video) async {
    _currentVideo.value = video;
    final existingIndex = _videoHistory.indexWhere((v) => v.id == video.id);
    if (existingIndex == -1) {
      _videoHistory.add(video);
    } else {
      _videoHistory[existingIndex] = video;
    }
    await _persistVideo(video);
    await _db.collection(_settingsCollection).doc(_activeVideoDocument).set({
      'videoId': video.id,
    });
  }

  VideoModel? findExistingLocalVideo({
    required String filePath,
    required int sizeBytes,
    required int lastModifiedMs,
    String? apiKeyProfileId,
  }) {
    return _videoHistory.firstWhereOrNull(
      (video) =>
          video.filePath == filePath &&
          video.sizeBytes == sizeBytes &&
          video.apiKeyProfileId == apiKeyProfileId &&
          (video.lastModifiedMs == null ||
              video.lastModifiedMs == lastModifiedMs),
    );
  }

  Future<void> updateVideoApiKeyProfile(
    String id,
    String apiKeyProfileId,
  ) async {
    final historyIndex = _videoHistory.indexWhere((video) => video.id == id);
    if (historyIndex == -1) return;

    final updatedVideo = _videoHistory[historyIndex].copyWith(
      apiKeyProfileId: apiKeyProfileId,
    );
    _videoHistory[historyIndex] = updatedVideo;
    if (_currentVideo.value?.id == id) {
      _currentVideo.value = updatedVideo;
    }
    await _persistVideo(updatedVideo);
  }

  Future<void> clearCurrentVideo() async {
    _currentVideo.value = null;
    await _db.collection(_settingsCollection).doc(_activeVideoDocument).set({
      'videoId': null,
    });
  }

  Future<void> updateVideoStatus(
    String id,
    VideoStatus status, {
    String? jobId,
    String? error,
    double? progress,
    bool? isUploaded,
  }) async {
    final historyIndex = _videoHistory.indexWhere((video) => video.id == id);
    final previous = historyIndex == -1 ? null : _videoHistory[historyIndex];
    final shouldPersist =
        previous != null &&
        (previous.status != status ||
            jobId != null ||
            error != null ||
            isUploaded != null);

    if (_currentVideo.value?.id == id) {
      _currentVideo.value = _currentVideo.value!.copyWith(
        status: status,
        isUploaded: isUploaded,
        indexJobId: jobId ?? _currentVideo.value?.indexJobId,
        errorMessage: error,
        uploadProgress: progress ?? _currentVideo.value?.uploadProgress,
      );
    }

    if (historyIndex != -1) {
      final updatedVideo = _videoHistory[historyIndex].copyWith(
        status: status,
        isUploaded: isUploaded,
        indexJobId: jobId ?? _videoHistory[historyIndex].indexJobId,
        errorMessage: error,
        uploadProgress: progress ?? _videoHistory[historyIndex].uploadProgress,
      );
      _videoHistory[historyIndex] = updatedVideo;
      if (shouldPersist) await _persistVideo(updatedVideo);
    }
  }

  Future<void> _persistVideo(VideoModel video) {
    return _db.collection(_videoCollection).doc(video.id).set(video.toJson());
  }
}
