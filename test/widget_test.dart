import 'dart:async';

import 'package:features_tour/features_tour.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:network_internet_checker/network_internet_checker.dart';
import 'package:wild_sense/app/app.dart';
import 'package:wild_sense/app/theme/app_theme.dart';
import 'package:wild_sense/core/services/api_key_service.dart';
import 'package:wild_sense/core/services/shared_api_key_provider.dart';
import 'package:wild_sense/core/services/video_service.dart';
import 'package:wild_sense/core/services/vmodal_service.dart';
import 'package:wild_sense/core/utils/duration_utils.dart';
import 'package:wild_sense/core/utils/user_data_namespace.dart';
import 'package:wild_sense/shared/models/search_result_model.dart';
import 'package:wild_sense/shared/models/observation_model.dart';
import 'package:wild_sense/shared/models/video_model.dart';
import 'package:wild_sense/shared/widgets/app_bottom_navigation_bar.dart';
import 'package:wild_sense/shared/widgets/video_card.dart';
import 'package:wild_sense/modules/about/views/about_view.dart';
import 'package:wild_sense/modules/saved_sightings/views/saved_sightings_view.dart';

void main() {
  testWidgets('EcoVision app smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    FeaturesTour.setGlobalConfig(
      preDialogConfig: PreDialogConfig(enabled: false),
    );
    final checker = _FakeInternetChecker();
    await tester.pumpWidget(
      EcoVisionApp(
        initialThemeMode: AdaptiveThemeMode.dark,
        internetChecker: checker,
      ),
    );
    await tester.pump();
    checker.emit(InternetStatus.connected);
    await tester.pump();
    expect(find.text('Connection restored'), findsNothing);
    checker.emit(InternetStatus.disconnected);
    await tester.pump();
    expect(find.text('No internet connection'), findsOneWidget);
    checker.emit(InternetStatus.connected);
    await tester.pump();
    expect(find.text('Connection restored'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Connection restored'), findsNothing);
    await checker.dispose();
    expect(
      Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
      Brightness.dark,
    );
    expect(find.text('FIELD NOTES, FOUND'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2200));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('EcoVision'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Welcome to EcoVision'), findsOneWidget);
  });

  group('DurationUtils tests', () {
    test('formatDuration formats MM:SS and HH:MM:SS correctly', () {
      expect(
        DurationUtils.formatDuration(const Duration(seconds: 14)),
        '00:14',
      );
      expect(
        DurationUtils.formatDuration(const Duration(minutes: 2, seconds: 37)),
        '02:37',
      );
      expect(
        DurationUtils.formatDuration(
          const Duration(hours: 1, minutes: 5, seconds: 9),
        ),
        '01:05:09',
      );
    });

    test('parseTimestampToDuration parses seconds, milliseconds and clock strings', () {
      // The bare-number path is unit-ambiguous: it reads values over 100000 as
      // milliseconds and anything smaller as seconds. It cannot do better
      // without knowing which key the value came from, which is why
      // SearchResultModel resolves units per key and only falls back to here
      // for clock strings and genuinely ambiguous keys.
      expect(DurationUtils.parseTimestampToDuration(14).inSeconds, 14);
      expect(DurationUtils.parseTimestampToDuration(14.0).inSeconds, 14);
      expect(DurationUtils.parseTimestampToDuration(150000).inSeconds, 150);
      expect(DurationUtils.parseTimestampToDuration('02:37').inSeconds, 157);
      expect(
        DurationUtils.parseTimestampToDuration('01:05:09').inSeconds,
        3909,
      );
      expect(DurationUtils.parseTimestampToDuration(null), Duration.zero);
    });
  });

  group('SearchResultModel tests', () {
    test('resolveTimestamps parses a V-Modal search response hit map', () {
      final hitMap = {
        'title': 'Elephant walking near water',
        'filename': 'wildlife_footage.mp4',
        'ts_unix_13digits': 14000,
        'score_ui': 0.94,
        'description': 'Elephant observed near river edge',
      };

      final result = SearchResultModel.resolveTimestamps(
        [hitMap],
        query: 'elephants near water',
        videoPath: '/path/to/video.mp4',
      ).single;

      expect(result.title, 'Elephant walking near water');
      expect(result.formattedTimestamp, '00:14');
      expect(result.timestampDuration.inSeconds, 14);
      expect(result.scoreText, '94.0%');
      expect(result.videoFileName, 'wildlife_footage.mp4');
    });

    test('absolute epoch timestamps become offsets from the earliest hit', () {
      // What the backend really sends: ts_unix_13digits is wall-clock ms, not
      // an in-video offset. Seeking to it directly overshot by ~54 years, so
      // the player skipped the seek and every moment played from 00:00.
      const base = 1700000000000;
      final hits = [
        {'title': 'first', 'ts_unix_13digits': base},
        {'title': 'later', 'ts_unix_13digits': base + 12000},
        {'title': 'latest', 'ts_unix_13digits': base + 65500},
      ];

      final results = SearchResultModel.resolveTimestamps(
        hits,
        query: 'bear',
        videoPath: '/path/to/video.mp4',
      );

      expect(results.map((r) => r.formattedTimestamp).toList(), [
        '00:00',
        '00:12',
        '01:05',
      ]);
      expect(results.every((r) => r.isTimestampApproximate), isTrue);
      expect(results.every((r) => r.hasTimestamp), isTrue);
      // The raw epoch is preserved: images.getUrl needs exactly this value.
      expect(results[1].absoluteTimestampMs, base + 12000);
    });

    test('relative keys win over absolute ones and stay exact', () {
      final results = SearchResultModel.resolveTimestamps(
        [
          {
            'title': 'hit',
            'start_time': 42.5,
            'ts_unix_13digits': 1700000000000,
          },
        ],
        query: 'bear',
        videoPath: '/path/to/video.mp4',
      );

      expect(results.single.timestampDuration.inMilliseconds, 42500);
      expect(results.single.isTimestampApproximate, isFalse);
    });

    test('a hit with no timestamp is flagged instead of claiming 00:00', () {
      final results = SearchResultModel.resolveTimestamps(
        [
          {'title': 'hit', 'score_ui': 0.8},
        ],
        query: 'bear',
        videoPath: '/path/to/video.mp4',
      );

      expect(results.single.hasTimestamp, isFalse);
      expect(results.single.formattedTimestamp, '--:--');
      expect(results.single.timestampDuration, Duration.zero);
    });

    test('SearchResultModel.fromJson handles null and missing legacy schema fields safely', () {
      final legacyJson = <String, dynamic>{
        'id': 'legacy_1',
        'query': 'lion',
        'title': 'Lion roar',
      };

      final model = SearchResultModel.fromJson(legacyJson);
      expect(model.id, 'legacy_1');
      expect(model.hasTimestamp, isTrue);
      expect(model.timestampMs, 0);
      expect(model.formattedTimestamp, '00:00');
    });

    test(
      'multiple hits in one video are resolved as individual moment results',
      () {
        final hits = [
          {'title': 'Bear fishing', 'start_time': 10, 'filename': 'nature.mp4'},
          {'title': 'Bear eating', 'start_time': 45, 'filename': 'nature.mp4'},
          {
            'title': 'Bear resting',
            'start_time': 120,
            'filename': 'nature.mp4',
          },
        ];

        final results = SearchResultModel.resolveTimestamps(
          hits,
          query: 'bear',
          videoPath: '/path/nature.mp4',
        );

        expect(results.length, 3);
        expect(results[0].formattedTimestamp, '00:10');
        expect(results[1].formattedTimestamp, '00:45');
        expect(results[2].formattedTimestamp, '02:00');
      },
    );
  });

  test('saved sightings filters combine search, video, and timestamp', () {
    final sightings = SearchResultModel.resolveTimestamps(
      [
        {
          'title': 'Elephant by the river',
          'filename': 'river.mp4',
          'start_time': 18,
        },
        {
          'title': 'Elephant in the grassland',
          'filename': 'savannah.mp4',
          'start_time': 42,
        },
        {'title': 'Elephant without a timecode', 'filename': 'river.mp4'},
      ],
      query: 'elephant',
      videoPath: '/path/to/video.mp4',
    );

    final filtered = filterSavedSightings(
      sightings,
      query: 'elephant',
      videoFileName: 'river.mp4',
      timestampFilter: SavedTimestampFilter.timestamped,
    );

    expect(filtered.length, 1);
    expect(filtered.single.title, 'Elephant by the river');
  });

  group('CollectionReadiness tests', () {
    CollectionReadiness readiness({
      List<String> versions = const <String>[],
      List<String> modalities = const <String>['vid_img_emb'],
      bool inferred = false,
    }) {
      return CollectionReadiness(
        exists: true,
        searchSources: const <String>['image'],
        versionLancedb: null,
        modalityTypes: modalities,
        lancedbVersions: versions,
        sourcesWereInferred: inferred,
      );
    }

    test('candidateVersions walks newest to oldest, then the default', () {
      // createIndex defaults to version: 'new_version', so every index run
      // mints a new version. The newest can be advertised before its table is
      // written, and asking for an unwritten table 404s the whole search.
      final versions = readiness(
        versions: const <String>['v0', 'v2', 'V10', 'v3', 'invalid'],
      ).candidateVersions;

      expect(versions, <int?>[10, 3, 2, null]);
    });

    test('candidateVersions is just the default when none are advertised', () {
      expect(readiness().candidateVersions, <int?>[null]);
    });

    test('candidateVersions dedupes and caps the walk', () {
      final versions = readiness(
        versions: const <String>['v1', 'v1', 'v2', 'v3', 'v4', 'v5'],
      ).candidateVersions;

      expect(versions.length, CollectionReadiness.maxVersionAttempts + 1);
      expect(versions, <int?>[5, 4, 3, null]);
    });

    test('isSearchable does not depend on an advertised version', () {
      // This is the regression that mattered: gating search on a nullable
      // version refused to search collections that were in fact indexed.
      expect(readiness().versionLancedb, isNull);
      expect(readiness().isSearchable, isTrue);
    });

    test('isIndexPublished requires a real version and real modality', () {
      expect(readiness().isIndexPublished, isFalse);

      final published = CollectionReadiness(
        exists: true,
        searchSources: const <String>['image'],
        versionLancedb: 2,
        modalityTypes: const <String>['vid_img_emb'],
        lancedbVersions: const <String>['v2'],
      );
      expect(published.isIndexPublished, isTrue);

      // An inferred source is a guess, so it must not confirm publication.
      expect(readiness(inferred: true).isIndexPublished, isFalse);
    });
  });

  group('VideoService.buildStreamName tests', () {
    test('sanitizes to the characters V-Modal accepts', () {
      // ContentScope._normalize rejects anything outside [A-Za-z0-9_].
      final name = VideoService.buildStreamName('bear video.mp4', '1699999999');
      expect(name, matches(RegExp(r'^[A-Za-z0-9_]+$')));
      expect(name, 'vid_bear_video_mp4_1699999999');
    });

    test('stays within the 80 character limit', () {
      final name = VideoService.buildStreamName(
        '${'a' * 200}.mp4',
        '1699999999',
      );
      expect(name.length, lessThanOrEqualTo(80));
      expect(name, endsWith('_1699999999'));
    });

    test('falls back when the file name sanitizes to nothing', () {
      expect(VideoService.buildStreamName('...', '42'), 'vid_42');
    });
  });

  group('ObservationModel tests', () {
    test('ObservationModel.fromJson handles null and missing legacy schema fields safely', () {
      final legacyJson = <String, dynamic>{
        'id': 'obs_123',
        'species': 'Giraffe',
      };

      final obs = ObservationModel.fromJson(legacyJson);
      expect(obs.id, 'obs_123');
      expect(obs.species, 'Giraffe');
      expect(obs.timestampMs, 0);
      expect(obs.formattedTimestamp, '00:00');
    });
  });

  group('Video library tests', () {
    test('saved upload metadata retains its stream and uploaded state', () {
      final video = VideoModel(
        id: '123',
        fileName: 'wildlife.mp4',
        filePath: r'C:\videos\wildlife.mp4',
        sizeBytes: 2048,
        status: VideoStatus.indexed,
        isUploaded: true,
        indexJobId: 'job-1',
        apiKeyProfileId: 'account-a',
        streamName: 'wildlife_123',
      );

      final restored = VideoModel.fromJson(video.toJson());

      expect(restored.isUploaded, isTrue);
      expect(restored.status, VideoStatus.indexed);
      expect(restored.streamName, video.streamName);
      expect(restored.indexJobId, video.indexJobId);
      expect(restored.apiKeyProfileId, 'account-a');
    });

    test('an already saved local video is found by path and file size', () {
      final service = VideoService();
      final video = VideoModel(
        id: '123',
        fileName: 'wildlife.mp4',
        filePath: r'C:\videos\wildlife.mp4',
        sizeBytes: 2048,
        status: VideoStatus.indexed,
        isUploaded: true,
        streamName: 'wildlife_123',
      );
      service.videoHistory.add(video);

      expect(
        service.findExistingLocalVideo(
          filePath: video.filePath,
          sizeBytes: video.sizeBytes,
          lastModifiedMs: 1000,
        ),
        same(video),
      );
      expect(
        service.findExistingLocalVideo(
          filePath: video.filePath,
          sizeBytes: video.sizeBytes + 1,
          lastModifiedMs: 1000,
        ),
        isNull,
      );
    });

    test('a local file is reused only for the API key that uploaded it', () {
      final service = VideoService();
      final video = VideoModel(
        id: '123',
        fileName: 'wildlife.mp4',
        filePath: r'C:\videos\wildlife.mp4',
        sizeBytes: 2048,
        apiKeyProfileId: 'account-a',
        status: VideoStatus.indexed,
        isUploaded: true,
      );
      service.videoHistory.add(video);

      expect(
        service.findExistingLocalVideo(
          filePath: video.filePath,
          sizeBytes: video.sizeBytes,
          lastModifiedMs: 1000,
          apiKeyProfileId: 'account-a',
        ),
        same(video),
      );
      expect(
        service.findExistingLocalVideo(
          filePath: video.filePath,
          sizeBytes: video.sizeBytes,
          lastModifiedMs: 1000,
          apiKeyProfileId: 'account-b',
        ),
        isNull,
      );
    });
  });

  group('API key retention tests', () {
    test(
      'temporary keys expire and the same key keeps its device profile',
      () async {
        final store = _MemorySecureValueStore();
        final vmodal = _FakeVModalService();
        var now = DateTime(2026, 11, 17);
        final service = ApiKeyService(
          vmodalService: vmodal,
          storage: store,
          clock: () => now,
        );

        await service.initialize();
        await service.save('example-secret', ApiKeyRetention.oneDay);
        final profileId = service.apiKeyProfileId;
        expect(service.expiresAt, DateTime(2026, 11, 18));
        expect(vmodal.configuredKey, 'example-secret');

        service.onClose();
        now = now.add(const Duration(days: 2));
        final restoredService = ApiKeyService(
          vmodalService: _FakeVModalService(),
          storage: store,
          clock: () => now,
        );
        await restoredService.initialize();

        expect(restoredService.credentialExpired.value, isTrue);
        expect(restoredService.hasSavedCredential.value, isFalse);
        expect(store.values.containsKey('vmodal_api_credential'), isFalse);

        await restoredService.save('example-secret', ApiKeyRetention.permanent);
        expect(restoredService.apiKeyProfileId, profileId);
        expect(restoredService.expiresAt, isNull);
        await restoredService.revoke();
        expect(restoredService.hasSavedCredential.value, isFalse);
        expect(store.values.containsKey('vmodal_api_credential'), isFalse);
        expect(
          store.values.containsKey('vmodal_api_fingerprint_secret'),
          isTrue,
        );
        restoredService.onClose();
      },
    );
  });

  test('shared and personal API keys can be switched independently', () async {
    final store = _MemorySecureValueStore();
    final provider = _FakeSharedApiKeyProvider('free-key');
    final vmodal = _FakeVModalService();
    final service = ApiKeyService(
      vmodalService: vmodal,
      storage: store,
      sharedApiKeyProvider: provider,
    );

    await service.initialize();
    expect(service.isUsingSharedKey.value, isTrue);
    expect(vmodal.configuredKey, 'free-key');

    await service.save('personal-key', ApiKeyRetention.permanent);
    expect(service.isUsingSharedKey.value, isFalse);
    expect(vmodal.configuredKey, 'personal-key');
    await service.useSharedKey();
    expect(service.isUsingSharedKey.value, isTrue);
    expect(service.hasSavedCredential.value, isTrue);
    expect(vmodal.configuredKey, 'free-key');

    provider.apiKey = 'rotated-key';
    await service.useSharedKey();
    expect(vmodal.configuredKey, 'rotated-key');

    service.onClose();
    final restoredVModal = _FakeVModalService();
    final restoredService = ApiKeyService(
      vmodalService: restoredVModal,
      storage: store,
      sharedApiKeyProvider: provider,
    );
    await restoredService.initialize();
    expect(restoredService.isUsingSharedKey.value, isTrue);
    expect(restoredVModal.configuredKey, 'rotated-key');

    await restoredService.usePersonalKey();
    expect(restoredService.isUsingSharedKey.value, isFalse);
    expect(restoredVModal.configuredKey, 'personal-key');
    restoredService.onClose();
  });

  test(
    'saved personal API keys use separate Firebase user namespaces',
    () async {
      final store = _MemorySecureValueStore();
      final vmodal = _FakeVModalService();
      final service = ApiKeyService(
        vmodalService: vmodal,
        storage: store,
        userId: 'user-a',
      );

      await service.initialize();
      await service.save('user-a-key', ApiKeyRetention.permanent);
      await service.switchUser('user-b');
      expect(service.hasSavedCredential.value, isFalse);
      expect(vmodal.configuredKey, isNull);
      await service.save('user-b-key', ApiKeyRetention.permanent);

      await service.switchUser('user-a');
      expect(vmodal.configuredKey, 'user-a-key');
      expect(service.hasSavedCredential.value, isTrue);
      expect(
        UserDataNamespace.localCollection('uploaded_videos', 'user-a'),
        isNot(UserDataNamespace.localCollection('uploaded_videos', 'user-b')),
      );
      final collectionService = VModalService()..setUserId('uid123');
      expect(collectionService.currentCollectionName, 'ecovision_uid123');
      service.onClose();
    },
  );

  testWidgets('video card actions wrap at narrow widths', (tester) async {
    final video = VideoModel(
      id: '123',
      fileName: 'wildlife.mp4',
      filePath: r'C:\videos\wildlife.mp4',
      sizeBytes: 2048,
      status: VideoStatus.selected,
      streamName: 'wildlife_123',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 260,
              child: VideoCard(video: video, onUploadTap: () {}),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('mobile bottom navigation fits a narrow screen', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 320,
          height: 640,
          child: const Scaffold(
            bottomNavigationBar: AppBottomNavigationBar(selectedIndex: 0),
          ),
        ),
      ),
    );

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Upload'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Research'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('About page explains the wildlife research workflow', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.lightTheme, home: const AboutView()),
    );

    expect(find.text('About EcoVision'), findsOneWidget);
    expect(find.text('How it works'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Made for research workflows'),
      300,
    );
    expect(find.text('Made for research workflows'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Explore the project on GitHub'),
      300,
    );
    expect(find.text('Explore the project on GitHub'), findsOneWidget);
  });
}

class _MemorySecureValueStore implements SecureValueStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }
}

class _FakeVModalService extends VModalService {
  String? configuredKey;

  @override
  bool get isConfigured => configuredKey != null;

  @override
  String get apiKey => configuredKey ?? '';

  @override
  Future<bool> configure(String apiKey, {String? projectId}) async {
    configuredKey = apiKey;
    return true;
  }

  @override
  Future<void> clearConfiguration() async {
    configuredKey = null;
  }
}

class _FakeSharedApiKeyProvider implements SharedApiKeyProvider {
  _FakeSharedApiKeyProvider(this.apiKey);

  String? apiKey;

  @override
  Future<String?> fetchApiKey() async => apiKey;
}

class _FakeInternetChecker extends InternetChecker {
  final StreamController<InternetStatus> _controller =
      StreamController<InternetStatus>.broadcast();
  InternetStatus? _status;

  @override
  InternetStatus? get lastStatus => _status;

  @override
  Stream<InternetStatus> get onStatusChange => _controller.stream;

  @override
  Future<InternetStatus> checkNow() async =>
      _status ?? InternetStatus.connected;

  void emit(InternetStatus status) {
    _status = status;
    _controller.add(status);
  }

  Future<void> dispose() => _controller.close();
}
