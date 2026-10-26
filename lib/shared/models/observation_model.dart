class ObservationModel {
  final String id;
  final String species;
  final String videoId;
  final String videoName;
  final String videoPath;
  final int timestampMs;
  final String formattedTimestamp;
  final String searchQuery;
  final DateTime createdAt;
  final String? thumbnailUrl;
  final String? notes;

  const ObservationModel({
    required this.id,
    required this.species,
    required this.videoId,
    required this.videoName,
    required this.videoPath,
    required this.timestampMs,
    required this.formattedTimestamp,
    required this.searchQuery,
    required this.createdAt,
    this.thumbnailUrl,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'species': species,
      'videoId': videoId,
      'videoName': videoName,
      'videoPath': videoPath,
      'timestampMs': timestampMs,
      'formattedTimestamp': formattedTimestamp,
      'searchQuery': searchQuery,
      'createdAt': createdAt.toIso8601String(),
      'thumbnailUrl': thumbnailUrl,
      'notes': notes,
    };
  }

  factory ObservationModel.fromJson(Map<String, dynamic> json) {
    final tsMs = (json['timestampMs'] as num?)?.toInt() ?? 0;
    final formattedTs = json['formattedTimestamp']?.toString();

    return ObservationModel(
      id: json['id']?.toString() ?? '',
      species: json['species']?.toString() ?? '',
      videoId: json['videoId']?.toString() ?? '',
      videoName: json['videoName']?.toString() ?? '',
      videoPath: json['videoPath']?.toString() ?? '',
      timestampMs: tsMs,
      formattedTimestamp: (formattedTs != null && formattedTs.isNotEmpty)
          ? formattedTs
          : '${(tsMs ~/ 1000 ~/ 60).toString().padLeft(2, '0')}:${((tsMs ~/ 1000) % 60).toString().padLeft(2, '0')}',
      searchQuery: json['searchQuery']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      thumbnailUrl: json['thumbnailUrl']?.toString(),
      notes: json['notes']?.toString(),
    );
  }
}
