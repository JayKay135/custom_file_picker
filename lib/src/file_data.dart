import 'dart:convert';
import 'package:collection/collection.dart';

/// Data class for holding file information.
///
/// Used for creating files and folders.
/// Refer to the named constructors [FileData.createFile] and [FileData.createFolder] for creating such.
class FileData {
  /// The name of the folder or file (excluding extension).
  String name;

  /// The extension of the file. `null` if the class represents a folder.
  String? extension;

  /// The time when the file/ folder was lastly modified.
  DateTime lastModified;

  /// Empty if the class represents a file. Contains otherwise child references if it is a folder.
  List<FileData> children;

  /// Keeps track of the data state: [FileData] instances can either be files or folders
  bool isFolder;

  /// Reference to possible parent [FileData]. Is null when the class instance is a singular [FileData] object or a root folder.
  FileData? parent;

  FileData(
    this.name,
    this.extension,
    this.lastModified,
    this.isFolder,
    this.children, {
    this.parent,
  });

  /// Creates a copy of the current [FileData] instance which removes all memory references to the old instance.
  FileData copy() {
    return FileData(
      name,
      extension,
      lastModified.copyWith(),
      isFolder,
      children.map((e) => e.copy()).toList(),
      parent: parent,
    );
  }

  /// Creates a folder [FileData] object
  static FileData createFolder(String name, DateTime lastModified, List<FileData> children) {
    FileData fileData = FileData(name, null, lastModified, true, children);

    // set parent reference for children
    for (FileData file in children) {
      file.parent = fileData;
    }

    // TODO: Order children alphabetically

    return fileData;
  }

  /// Creates a file [FileData] object
  FileData.createFile(this.name, this.extension, this.lastModified)
      : children = [],
        isFolder = false;

  /// Creates a file [FileData] object where the fileName contains the extension e.g. "test.txt"
  static FileData createFileFromFileName(
    String fileName,
    DateTime lastModified,
  ) {
    int dotIndex = fileName.lastIndexOf('.');

    String name = dotIndex == -1 ? fileName : fileName.substring(0, dotIndex);
    String extension = dotIndex == -1 ? '' : fileName.substring(dotIndex + 1);

    return FileData(name, extension, lastModified, false, []);
  }

  /// Returns the folder path based on itst position in the file hierarchy
  String getPath() {
    return parent != null ? "${parent!.getPath()}/$name" : name;
  }

  /// Retrieves a [FileData] object from the given [path].
  ///
  /// Returns `null` if no file is found at the specified path.
  FileData? getFileFromPath(String path) {
    List<String> hierarchy = path.split('/');

    if (hierarchy.length == 1 && hierarchy.first == name) {
      return this;
    }

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
        lastModified = DateTime.parse(json['lastModified'] as String),
        isFolder = json['isFolder'],
        children = json.containsKey('children')
            ? (jsonDecode(json['children']) as List<dynamic>).map((childJson) => FileData.fromJson(childJson as Map<String, dynamic>)).toList()
            : [];

  Map<String, dynamic> toJson() => {
        'name': name,
        'extension': extension,
        'lastModified': lastModified.toIso8601String(),
        'isFolder': isFolder,
        'children': jsonEncode(children),
      };
}
