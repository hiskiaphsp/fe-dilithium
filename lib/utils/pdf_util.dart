// document_utils.dart
import 'package:fe/data/models/document.dart';

List extractUrlAndFileName(List<FileInfo> fileInfoList) {
  List<String> dataUrl = [];
  List<String> dataFileName = [];

  for (var fileInfo in fileInfoList) {
    dataUrl.add(fileInfo.url);
    dataFileName.add(fileInfo.document.filename);
  }

  return [dataUrl, dataFileName];
}
