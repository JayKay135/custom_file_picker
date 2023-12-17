import 'dart:convert';
import 'package:collection/collection.dart';

class FileData {
  String name;
  String extension;
  DateTime lastChanged;

  List<FileData> children;

  bool isFolder;

  FileData? parent;

  FileData(
    this.name,
    this.extension,
    this.lastChanged,
    this.isFolder,
    this.children,
  );

  FileData copy() {
    return FileData(name, extension, lastChanged.copyWith(), isFolder, children.map((e) => e.copy()).toList());
  }

  static FileData createFolder(String name, DateTime lastChanged, List<FileData> children) {
    FileData fileData = FileData(name, "", lastChanged, true, children);

    // set parent reference for children
    for (FileData file in children) {
      file.parent = fileData;
    }

    // TODO: Order children alphabetically

    return fileData;
  }

  FileData.createFile(this.name, this.extension, this.lastChanged)
      : children = [],
        isFolder = false;

  static FileData createFileFromFileName(
    String fileName,
    DateTime lastChanged,
  ) {
    int dotIndex = fileName.lastIndexOf('.');

    String name = dotIndex == -1 ? fileName : fileName.substring(0, dotIndex);
    String extension = dotIndex == -1 ? '' : fileName.substring(dotIndex + 1);

    return FileData(name, extension, lastChanged, false, []);
  }

  String getPath() {
    return parent != null ? "${parent!.getPath()}/$name" : name;
  }

  FileData? getFileFromPath(String path) {
    List<String> hierarchy = path.split('/');

    FileData? current = this;
    int index = 0;

    while (current!.name == hierarchy[index]) {
      index++;

      current = current.children.firstWhereOrNull((element) => element.name == hierarchy[index]);
      if (index == hierarchy.length - 1) {
        return current;
      }

      if (current == null) {
        return null;
      }
    }

    return null;
  }

  FileData.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        extension = json['extension'],
        lastChanged = DateTime.fromMillisecondsSinceEpoch(json['lastChanged'] as int),
        isFolder = json['isFolder'],
        children = (jsonDecode(json['children']) as List<dynamic>).map((childJson) => FileData.fromJson(childJson as Map<String, dynamic>)).toList();

  Map<String, dynamic> toJson() => {
        'name': name,
        'extension': extension,
        'lastChanged': lastChanged.millisecondsSinceEpoch,
        'isFolder': isFolder,
        'children': jsonEncode(children),
      };
}
