import 'package:get/get.dart';
import 'package:localstore/localstore.dart';

import '../../shared/models/observation_model.dart';
import '../utils/user_data_namespace.dart';

class ResearchService extends GetxService {
  ResearchService({String? userId}) : _userId = userId;

  final _db = Localstore.instance;
  static const String _obsCollection = 'research_observations';
  static const String _searchCollection = 'search_history';
  String? _userId;
  bool _isSignedOutScope = false;
  int _generation = 0;

  String? get _storageUserId => _isSignedOutScope ? 'signed_out' : _userId;

  String _collectionPath(String collectionName) =>
      UserDataNamespace.localCollection(collectionName, _storageUserId);

  final observations = <ObservationModel>[].obs;
  final searchHistory =
      <Map<String, dynamic>>[].obs; // contains 'query' and 'timestamp'

  @override
  void onInit() {
    super.onInit();
    loadAllData();
  }

  Future<void> loadAllData() async {
    final generation = _generation;
    final observationsPath = _collectionPath(_obsCollection);
    final searchPath = _collectionPath(_searchCollection);
    try {
      // Load observations
      final obsItems = await _db.collection(observationsPath).get();
      if (generation != _generation) return;
      if (obsItems != null) {
        final loadedObs = <ObservationModel>[];
        for (final entry in obsItems.entries) {
          try {
            final model = ObservationModel.fromJson(
              Map<String, dynamic>.from(entry.value),
            );
            loadedObs.add(model);
          } catch (_) {
            // Skip broken/ancient entries gracefully
          }
        }
        // Sort newest first
        loadedObs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        if (generation != _generation) return;
        observations.assignAll(loadedObs);
      }

      // Load search history
      final searchItems = await _db.collection(searchPath).get();
      if (generation != _generation) return;
      if (searchItems != null) {
        final loadedSearches = searchItems.entries
            .map((e) => Map<String, dynamic>.from(e.value))
            .toList();
        // Sort newest first
        loadedSearches.sort(
          (a, b) =>
              (b['timestamp'] as String).compareTo(a['timestamp'] as String),
        );
        searchHistory.assignAll(loadedSearches);
      }
    } catch (_) {
      // Fail gracefully
    }
  }

  Future<void> switchUser(String? userId) async {
    if (_userId == userId && (userId != null || _isSignedOutScope)) return;
    _userId = userId;
    _isSignedOutScope = userId == null;
    _generation++;
    observations.clear();
    searchHistory.clear();
    await loadAllData();
  }

  Future<bool> saveObservation(ObservationModel obs) async {
    // Prevent exact duplicate based on species, videoName, and timestampMs
    final exists = observations.any(
      (o) =>
          o.species.toLowerCase() == obs.species.toLowerCase() &&
          o.videoName == obs.videoName &&
          (o.timestampMs - obs.timestampMs).abs() < 1000,
    );

    if (exists) {
      return false; // Already exists
    }

    final generation = _generation;
    await _db
        .collection(_collectionPath(_obsCollection))
        .doc(obs.id)
        .set(obs.toJson());
    if (generation == _generation) observations.insert(0, obs);
    return true;
  }

  Future<void> logSearch(String query) async {
    if (query.trim().isEmpty) return;

    final generation = _generation;
    final collectionPath = _collectionPath(_searchCollection);
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final timestamp = DateTime.now().toIso8601String();
    final searchData = {
      'id': id,
      'query': query.trim(),
      'timestamp': timestamp,
    };

    try {
      await _db.collection(collectionPath).doc(id).set(searchData);
      if (generation == _generation) searchHistory.insert(0, searchData);
    } catch (_) {}
  }

  int getMonthlySearchCount() {
    final now = DateTime.now();
    return searchHistory.where((s) {
      final tsStr = s['timestamp'] as String?;
      if (tsStr == null) return false;
      final date = DateTime.tryParse(tsStr);
      if (date == null) return false;
      return date.year == now.year && date.month == now.month;
    }).length;
  }
}
