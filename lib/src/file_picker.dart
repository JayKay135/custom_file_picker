import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';

import '../custom_file_picker.dart';
import 'file_picker_widget.dart';

class FilePicker {
  final Widget mainApp;
  final List<String> args;

  static const bool showExtension = true;

  FilePicker(
    this.args,
    this.mainApp, {
    ThemeData? theme,
    ThemeData? darkTheme,
  }) {
    if (args.firstOrNull == "multi_window") {
      int windowId = int.parse(args[1]);
      Map<String, dynamic> data = jsonDecode(args[2]);

      // List<FileData> files = (data["files"] as List<dynamic>).map((e) => FileData.fromJson(e)).toList();
      FileData file = FileData.fromJson(data["file"]);
      bool saveAs = data["saveAs"];

      FileData? suggestedFile;
      List<String>? extensions;

      if (saveAs) {
        suggestedFile = FileData.fromJson(data["suggestedFile"]);
      } else {
        extensions = (data["extensions"] as List<dynamic>).map((e) => e as String).toList();
      }

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
            ),
          ),
          theme: theme,
          darkTheme: darkTheme,
          // theme: ThemeData(
          //   useMaterial3: true,
          //   colorScheme: ColorScheme.fromSeed(
          //     brightness: Brightness.light,
          //     seedColor: Colors.blue,
          //   ),
          // ),
          // darkTheme: ThemeData(
          //   useMaterial3: true,
          //   colorScheme: ColorScheme.fromSeed(
          //     brightness: Brightness.dark,
          //     seedColor: Colors.blue,
          //   ),
          // ),
        ),
      );
    } else {
      runApp(mainApp);
    }
  }

  static void _setParentReferences(FileData fileData) {
    for (FileData child in fileData.children) {
      child.parent = fileData;

      // continue search
      _setParentReferences(child);
    }
  }

  /// Recursively removes all files that are not folders
  static void _removeFiles(FileData fileData) {
    fileData.children.removeWhere((element) => !element.isFolder);

    // continue search
    for (FileData child in fileData.children) {
      _removeFiles(child);
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
  ///
  /// Example usage:
  /// ```dart
  /// FilePicker.open(fileHistory, ['txt', 'pdf'], (String filePath) {
  ///   print('Selected file: $filePath');
  /// });
  /// ```
  static Future<void> open(FileData fileHistory, List<String> extensions, Function(String) onSelectedFile) async {
    FileData files = fileHistory.copy();
    _keepOnlyExtension(files, extensions);

    final window = await DesktopMultiWindow.createWindow(jsonEncode({
      'file': files,
      'saveAs': false,
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
          // Map<String, dynamic> data = jsonDecode(call.arguments);
          // onSelectedFile(FileData.fromJson(data));
          onSelectedFile(call.arguments);
      }

      // debugPrint('${call.method} ${call.arguments} $fromWindowId');
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
  ///
  /// Example usage:
  /// ```dart
  /// FilePicker.open(fileHistory, ['txt', 'pdf'], (String filePath) {
  ///   print('Selected file: $filePath');
  /// });
  /// ```
  static Future<void> openAsync(
    FileData fileHistory,
    List<String> extensions,
    Future<FileData> Function(String) getFileData,
    Function(String) onSelectedFile,
  ) async {
    FileData files = fileHistory.copy();
    _keepOnlyExtension(files, extensions);

    final window = await DesktopMultiWindow.createWindow(jsonEncode({
      'file': files,
      'saveAs': false,
      'extensions': extensions,
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
          return jsonEncode(newFileData);

        case "open":
          // Map<String, dynamic> data = jsonDecode(call.arguments);
          // onSelectedFile(FileData.fromJson(data));
          onSelectedFile(call.arguments);
          break;
      }

      // debugPrint('${call.method} ${call.arguments} $fromWindowId');
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
  /// FilePicker.saveAs(fileHistory, suggestedFile, (path) {
  ///   // Handle the selected file path
  /// });
  /// ```
  static Future<void> saveAs(FileData fileHistory, FileData suggestedFile, Function(String) onSelectedFile) async {
    FileData files = fileHistory.copy();
    _removeFiles(files);

    final window = await DesktopMultiWindow.createWindow(jsonEncode({
      'file': files,
      'saveAs': true,
      'suggestedFile': suggestedFile,
    }));
    window
      ..setFrame(const Offset(0, 0) & const Size(800, 450))
      ..center()
      ..setTitle('File Picker')
      ..show();

    DesktopMultiWindow.setMethodHandler((call, fromWindowId) async {
      switch (call.method) {
        case "saveAs":
          // Map<String, dynamic> data = jsonDecode(call.arguments);
          // onSelectedFile(FileData.fromJson(data));
          onSelectedFile(call.arguments);
      }

      // debugPrint('${call.method} ${call.arguments} $fromWindowId');
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
  /// FilePicker.saveAs(fileHistory, suggestedFile, (path) {
  ///   // Handle the selected file path
  /// });
  /// ```
  static Future<void> saveAsAsync(
    FileData fileHistory,
    FileData suggestedFile,
    Future<FileData> Function(String) getFileData,
    Function(String) onSelectedFile,
  ) async {
    FileData files = fileHistory.copy();
    _removeFiles(files);

    final window = await DesktopMultiWindow.createWindow(jsonEncode({
      'file': files,
      'saveAs': true,
      'suggestedFile': suggestedFile,
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
          _removeFiles(newFileData);
          return jsonEncode(newFileData);

        case "saveAs":
          // Map<String, dynamic> data = jsonDecode(call.arguments);
          // onSelectedFile(FileData.fromJson(data));
          onSelectedFile(call.arguments);
          break;
      }

      // debugPrint('${call.method} ${call.arguments} $fromWindowId');
      return "";
    });
  }
}
