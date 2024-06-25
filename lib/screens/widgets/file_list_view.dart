// file_list_view.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:open_file/open_file.dart';

class FileListView extends StatelessWidget {
  final List<File> fileList;
  final IconData icon;

  FileListView({required this.fileList, required this.icon});

  void openFile(File file) {
    OpenFile.open(file.path);
  }

  @override
  Widget build(BuildContext context) {
    return fileList.isNotEmpty
        ? ListView.builder(
            itemCount: fileList.length,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => openFile(fileList[index]),
                child: Card(
                  child: ListTile(
                    leading: Icon(icon),
                    title: Text(
                      basename(fileList[index].path),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // subtitle: Text(
                    //   '${fileList[index].lengthSync()} bytes',
                    //   maxLines: 1,
                    //   overflow: TextOverflow.ellipsis,
                    // ),
                  ),
                ),
              );
            },
          )
        : Container();
  }
}
