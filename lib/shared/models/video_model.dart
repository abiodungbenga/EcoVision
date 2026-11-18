import '../../core/constants/app_constants.dart';

enum VideoStatus { idle, selected, uploading, indexing, indexed, error }

class VideoModel {
  final String id;
  final String fileName;
  final String filePath;
  final int sizeBytes;
  final int? lastModifiedMs;
  final String? ownerUserId;
  final String? apiKeyProfileId;
  final VideoStatus status;
  final bool isUploaded;
  final String? indexJobId;
  final String? errorMessage;
  final double uploadProgress;
  final String collectionName;

  /// Stream this video was uploaded to. Each video gets its own stream so a
  /// search never returns moments belonging to a different file. Built by
  /// `VideoService.buildStreamName`; the default is only a fallback for
  /// videos constructed without one.
  final String streamName;

  const VideoModel({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.sizeBytes,
    this.lastModifiedMs,
    this.ownerUserId,
    this.apiKeyProfileId,
    this.status = VideoStatus.idle,
    this.isUploaded = false,
    this.indexJobId,
    this.errorMessage,
    this.uploadProgress = 0.0,
    this.collectionName = AppConstants.defaultCollectionName,
    this.streamName = AppConstants.defaultStreamName,
  });

  bool get isIndexed => status == VideoStatus.indexed;
  bool get isUploading => status == VideoStatus.uploading;
  bool get isIndexing => status == VideoStatus.indexing;

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fileName': fileName,
    'filePath': filePath,
    'sizeBytes': sizeBytes,
    'lastModifiedMs': lastModifiedMs,
    'ownerUserId': ownerUserId,
    'apiKeyProfileId': apiKeyProfileId,
    'status': status.name,
    'isUploaded': isUploaded,
    'indexJobId': indexJobId,
    'errorMessage': errorMessage,
    'uploadProgress': uploadProgress,
    'collectionName': collectionName,
    'streamName': streamName,
  };

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    final statusName = json['status'] as String? ?? VideoStatus.selected.name;
    final status = VideoStatus.values.firstWhere(
      (value) => value.name == statusName,
      orElse: () =>
          throw FormatException('Unknown video status "$statusName".'),
    );
    return VideoModel(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      filePath: json['filePath'] as String,
      sizeBytes: json['sizeBytes'] as int,
      lastModifiedMs: json['lastModifiedMs'] as int?,
      ownerUserId: json['ownerUserId'] as String?,
      apiKeyProfileId: json['apiKeyProfileId'] as String?,
      status: status,
      isUploaded:
          json['isUploaded'] as bool? ??
          status == VideoStatus.indexing || status == VideoStatus.indexed,
      indexJobId: json['indexJobId'] as String?,
      errorMessage: json['errorMessage'] as String?,
      uploadProgress: (json['uploadProgress'] as num?)?.toDouble() ?? 0,
      collectionName:
          json['collectionName'] as String? ??
          AppConstants.defaultCollectionName,
      streamName:
          json['streamName'] as String? ?? AppConstants.defaultStreamName,
    );
  }

  VideoModel copyWith({
    String? id,
    String? fileName,
    String? filePath,
    int? sizeBytes,
    int? lastModifiedMs,
    String? ownerUserId,
    String? apiKeyProfileId,
    VideoStatus? status,
    bool? isUploaded,
    String? indexJobId,
    String? errorMessage,
    double? uploadProgress,
    String? collectionName,
    String? streamName,
  }) {
    return VideoModel(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      lastModifiedMs: lastModifiedMs ?? this.lastModifiedMs,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      apiKeyProfileId: apiKeyProfileId ?? this.apiKeyProfileId,
      status: status ?? this.status,
      isUploaded: isUploaded ?? this.isUploaded,
      indexJobId: indexJobId ?? this.indexJobId,
      errorMessage: errorMessage ?? this.errorMessage,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      collectionName: collectionName ?? this.collectionName,
      streamName: streamName ?? this.streamName,
    );
  }
}
