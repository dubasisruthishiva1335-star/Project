class UploadedFileModel {
  final String id;
  final String title;
  final String fileName;
  final String storagePath;
  final String publicUrl;
  final String fileType;
  final int fileSize;
  final String? uploadedBy;
  final DateTime createdAt;

  UploadedFileModel({
    required this.id,
    required this.title,
    required this.fileName,
    required this.storagePath,
    required this.publicUrl,
    required this.fileType,
    required this.fileSize,
    this.uploadedBy,
    required this.createdAt,
  });

  factory UploadedFileModel.fromMap(Map<String, dynamic> map) {
    final fileNameStr = map['file_name'] as String? ?? 'file';
    final extension = fileNameStr.contains('.') ? fileNameStr.split('.').last.toLowerCase() : 'file';
    return UploadedFileModel(
      id: (map['id'] ?? DateTime.now().millisecondsSinceEpoch.toString()).toString(),
      title: fileNameStr.contains('.') ? fileNameStr.split('.').first : fileNameStr,
      fileName: fileNameStr,
      storagePath: fileNameStr,
      publicUrl: map['file_url'] as String? ?? map['fileUrl'] as String? ?? '',
      fileType: extension,
      fileSize: (map['file_size'] ?? map['fileSize'] ?? 0) as int,
      uploadedBy: map['user_id'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': uploadedBy,
      'file_url': publicUrl,
      'file_name': fileName,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get fileSizeFormatted {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
