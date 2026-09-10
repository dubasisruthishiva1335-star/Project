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
    final rawName = (map['fileName'] ?? map['file_name'] ?? map['name'] ?? map['title'] ?? 'Uploaded File').toString();
    final cleanTitle = (map['title'] ?? rawName.split('.').first).toString();
    final rawUrl = (map['url'] ?? map['fileUrl'] ?? map['file_url'] ?? map['filePath'] ?? map['storagePath'] ?? '').toString();
    
    String ext = 'pdf';
    if (rawName.contains('.')) {
      ext = rawName.split('.').last.toLowerCase();
    } else if (rawUrl.contains('.')) {
      final seg = rawUrl.split('?').first.split('.').last.toLowerCase();
      if (seg.length <= 4) ext = seg;
    }

    int parsedSize = 2500000;
    final rawSize = map['fileSize'] ?? map['file_size'];
    if (rawSize is int) {
      parsedSize = rawSize;
    } else if (rawSize is String) {
      final numPart = double.tryParse(rawSize.replaceAll(RegExp(r'[^0-9.]'), ''));
      if (numPart != null) {
        if (rawSize.toUpperCase().contains('MB')) {
          parsedSize = (numPart * 1024 * 1024).toInt();
        } else if (rawSize.toUpperCase().contains('KB')) {
          parsedSize = (numPart * 1024).toInt();
        } else {
          parsedSize = numPart.toInt();
        }
      }
    }

    DateTime parsedDate = DateTime.now();
    final rawDate = map['createdAt'] ?? map['created_at'] ?? map['uploadedAt'] ?? map['addedAt'];
    if (rawDate != null) {
      parsedDate = DateTime.tryParse(rawDate.toString()) ?? DateTime.now();
    }

    return UploadedFileModel(
      id: (map['id'] ?? map['_id'] ?? DateTime.now().millisecondsSinceEpoch.toString()).toString(),
      title: cleanTitle,
      fileName: rawName,
      storagePath: rawUrl,
      publicUrl: rawUrl,
      fileType: ext,
      fileSize: parsedSize,
      uploadedBy: (map['author'] ?? map['user_id'] ?? 'Admin Cloud').toString(),
      createdAt: parsedDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'file_name': fileName,
      'storage_path': storagePath,
      'file_url': publicUrl,
      'file_type': fileType,
      'file_size': fileSize,
      'user_id': uploadedBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get fileSizeFormatted {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
