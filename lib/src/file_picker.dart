import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';

import 'file_picker_widget.dart';
import '../custom_file_picker.dart';

/// A class that provides file picking functionality.
class FilePicker {
  FilePicker(
    List<String> args,
    Widget mainApp, {
    ThemeData? theme,
    ThemeData? darkTheme,
  }) {
    if (args.firstOrNull == "multi_window") {
      int windowId = int.parse(args[1]);
      Map<String, dynamic> data = jsonDecode(args[2]);

      // List<FileData> files = (data["files"] as List<dynamic>).map((e) => FileData.fromJson(e)).toList();
      FileData file = FileData.fromJson(data["file"]);

      // Retrieve parent hierarchy through path data
      FileData parent = file;
      List<String> parents = (data["path"] as String).split("/");
      for (int i = parents.length - 2; i >= 0; i--) {
        parent.parent = FileData.createFolder(parents[i], DateTime.now(), [parent]);
        parent = parent.parent!;
      }

      bool saveAs = data["saveAs"];

      FileData? suggestedFile;
      List<String>? extensions;

      if (saveAs) {
        suggestedFile = FileData.fromJson(data["suggestedFile"]);
      } else {
        extensions = (data["extensions"] as List<dynamic>).map((e) => e as String).toList();
      }

      bool showExtension = data.containsKey("showExtension") && data["showExtension"];
      bool async = data.containsKey("async") && data["async"];

      // set parent references
      _setParentReferences(file);

      runApp(
        MaterialApp(
          themeMode: ThemeMode.dark,
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: FilePickerWidget(
              windowController: WindowController.fromWindowId(windowId),
              file: file,
              saveAs: saveAs,
              suggestedFile: suggestedFile,
              extensions: extensions,
              async: async,
              showExtension: showExtension,
            ),
          ),
          theme: theme,
          darkTheme: darkTheme,
        ),
      );
    } else {
      runApp(mainApp);
    }
  }

  /// Sets the parent references for the given [fileData].
  static void _setParentReferences(FileData fileData) {
    for (FileData child in fileData.children) {
      child.parent = fileData;

      // continue search
      _setParentReferences(child);
    }
  }

  /// Recursively removes all files that are not folders except files with extensionss that are listed in the [extensionExceptions]
  static void _removeFiles(FileData fileData, List<String> extensionExceptions) {
    fileData.children.removeWhere((element) => !element.isFolder && !extensionExceptions.contains(element.extension));

    // continue search
    for (FileData child in fileData.children) {
      _removeFiles(child, extensionExceptions);
    }
  }

  /// Recursively removes all files that don't have one of the allowed extensions
  static void _keepOnlyExtension(FileData fileData, List<String> extension) {
    fileData.children.removeWhere((element) => !element.isFolder && !extension.contains(element.extension));

    // continue search
    for (FileData child in fileData.children) {
      _keepOnlyExtension(child, extension);
    }
  }

  /// Opens the file picker dialog and allows the user to select a file.
  ///
  /// [fileHistory] : Is used to specify the initial directory or file that should be displayed in the file picker dialog.
  /// [extensions] : Is a list of file extensions that the user is allowed to select.
  /// [onSelectedFile] : Is a callback function that will be called when the user selects a file. It takes a single parameter, which is the path of the selected file.
  /// [showExtension] : Whether or not the file extension will be displayed
  ///
  /// Example usage:
  /// ```dart
  /// FilePicker.open(fileHistory, ['txt', 'pdf'], (String path) {
  ///   // Handle the selected file path
  /// });
  /// ```
  static Future<void> open(
    FileData fileHistory,
    List<String> extensions,
    Function(String path) onSelectedFile, {
    bool showExtension = true,
  }) async {
    FileData files = fileHistory.copy();
    _keepOnlyExtension(files, extensions);

    final window = await DesktopMultiWindow.createWindow(jsonEncode({
      'file': files,
      'path': files.getPath(),
      'saveAs': false,
      'showExtension': showExtension,
      'extensions': extensions,
    }));
    window
      ..setFrame(const Offset(0, 0) & const Size(800, 450))
      ..center()
      ..setTitle('File Picker')
      ..show();

    DesktopMultiWindow.setMethodHandler((call, fromWindowId) async {
      switch (call.method) {
        case "open":
          onSelectedFile(call.arguments);
      }

      return "";
    });
  }

  /// Opens the file picker dialog and allows the user to select a file.
  /// It triggers the [getFileData] future whenever a new folder hierarchie is selected.
  /// This way not the complete history data must be provided straight away.
  /// But rather the actually required data is requested during runtime.
  ///
  /// [fileHistory] : Is used to specify the initial directory or file that should be displayed in the file picker dialog.
  /// [extensions] : Is a list of file extensions that the user is allowed to select.
  /// [onSelectedFile] : Is a callback function that will be called when the user selects a file. It takes a single parameter, which is the path of the selected file.
  /// [showExtension] : Whether or not the file extension will be displayed
  ///
  /// Example usage:
  /// ```dart
  /// FilePicker.openAsync(fileHistory, ['txt', 'pdf'], (String path) async {
  ///   print("returning files for: $path");
  ///   return FileData ...
  /// }, (String path) {
  ///   // Handle the selected file path
  /// });
  /// ```
  static Future<void> openAsync(
    FileData fileHistory,
    List<String> extensions,
    Future<FileData> Function(String path) getFileData,
    Function(String path) onSelectedFile, {
    bool showExtension = true,
  }) async {
    FileData files = fileHistory.copy();
    _keepOnlyExtension(files, extensions);

    final window = await DesktopMultiWindow.createWindow(jsonEncode({
      'file': files,
      'path': files.getPath(),
      'saveAs': false,
      'extensions': extensions,
      'showExtension': showExtension,
      'async': true,
    }));
    window
      ..setFrame(const Offset(0, 0) & const Size(800, 450))
      ..center()
      ..setTitle('File Picker')
      ..show();

    DesktopMultiWindow.setMethodHandler((call, fromWindowId) async {
      switch (call.method) {
        case "getFileData":
          FileData newFileData = (await getFileData(call.arguments)).copy();
          _keepOnlyExtension(newFileData, extensions);
          return jsonEncode({'file': newFileData, 'path': newFileData.getPath()});

        case "open":
          onSelectedFile(call.arguments);
          break;
      }

      return "";
    });
  }

  /// Saves the selected file as a new file.
  ///
  /// [fileHistory] : Represents the history of previously selected files.
  /// [suggestedFile] : Represents the file that is suggested to be saved.
  /// [onSelectedFile] : Is a callback function that is called when a file is selected.
  ///
  /// Example usage:
  /// ```dart
  /// FilePicker.saveAs(fileHistory, suggestedFile, (String path) {
  ///   // Handle the selected file path
  /// });
  /// ```
  static Future<void> saveAs(
    FileData fileHistory,
    FileData suggestedFile,
    Function(String path) onSelectedFile, {
    bool showExtension = true,
  }) async {
    FileData files = fileHistory.copy();
    _removeFiles(files, [suggestedFile.extension!]);

    final window = await DesktopMultiWindow.createWindow(jsonEncode({
      'file': files,
      'path': files.getPath(),
      'saveAs': true,
      'suggestedFile': suggestedFile,
      'showExtension': showExtension,
    }));
    window
      ..setFrame(const Offset(0, 0) & const Size(800, 450))
      ..center()
      ..setTitle('File Picker')
      ..show();

    DesktopMultiWindow.setMethodHandler((call, fromWindowId) async {
      switch (call.method) {
        case "saveAs":
          onSelectedFile(call.arguments);
      }

      return "";
    });
  }

  /// Saves the selected file as a new file.
  /// It triggers the [getFileData] future whenever a new folder hierarchie is selected.
  /// This way not the complete history data must be provided straight away.
  /// But rather the actually required data is requested during runtime.
  ///
  /// [fileHistory] : Represents the history of previously selected files.
  /// [suggestedFile] : Represents the file that is suggested to be saved.
  /// [onSelectedFile] : Is a callback function that is called when a file is selected.
  ///
  /// Example usage:
  /// ```dart
  /// FilePicker.saveAsAsync(fileHistory, suggestedFile, (String path) async {
  ///   print("returning files for: $path");
  ///   return FileData ...
  /// }, (String path) {
  ///   // Handle the selected file path
  /// });
  /// ```
  static Future<void> saveAsAsync(
    FileData fileHistory,
    FileData suggestedFile,
    Future<FileData> Function(String path) getFileData,
    Function(String path) onSelectedFile, {
    bool showExtension = true,
  }) async {
    FileData files = fileHistory.copy();
    _removeFiles(files, [suggestedFile.extension!]);

    final window = await DesktopMultiWindow.createWindow(jsonEncode({
      'file': files,
      'path': files.getPath(),
      'saveAs': true,
      'suggestedFile': suggestedFile,
      'showExtension': showExtension,
      'async': true,
    }));
    window
      ..setFrame(const Offset(0, 0) & const Size(800, 450))
      ..center()
      ..setTitle('File Picker')
      ..show();

    DesktopMultiWindow.setMethodHandler((call, fromWindowId) async {
      switch (call.method) {
        case "getFileData":
          FileData newFileData = (await getFileData(call.arguments)).copy();
          _removeFiles(newFileData, [suggestedFile.extension!]);
          return jsonEncode({'file': newFileData, 'path': newFileData.getPath()});

        case "saveAs":
          onSelectedFile(call.arguments);
          break;
      }

      return "";
    });
  }
}
