class Document {
  int id;
  String filename;
  String path;
  String createdAt;
  String updatedAt;
  String? deletedAt;

  Document({
    required this.id,
    required this.filename,
    required this.path,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['ID'],
      filename: json['filename'],
      path: json['path'],
      createdAt: json['CreatedAt'],
      updatedAt: json['UpdatedAt'],
      deletedAt: json['DeletedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ID': id,
      'filename': filename,
      'path': path,
      'CreatedAt': createdAt,
      'UpdatedAt': updatedAt,
      'DeletedAt': deletedAt,
    };
  }
}

class FileInfo {
  Document document;
  String url;
  int size;

  FileInfo({
    required this.document,
    required this.url,
    required this.size,
  });

  factory FileInfo.fromJson(Map<String, dynamic> json) {
    return FileInfo(
      document: Document.fromJson(json['document']),
      url: json['url'],
      size: json['size'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'document': document.toJson(),
      'url': url,
      'size': size,
    };
  }
}

List<FileInfo> parseFileInfoList(List<dynamic> jsonList) {
  return jsonList.map((json) => FileInfo.fromJson(json)).toList();
}
