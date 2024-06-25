// file_info.dart
class Document {
  String id;
  String filename;
  String path;

  Document({
    required this.id,
    required this.filename,
    required this.path,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['_id'],
      filename: json['filename'],
      path: json['path'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'filename': filename,
      'path': path,
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
