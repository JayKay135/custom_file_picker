import 'dart:convert';
import 'package:custom_file_picker/src/file_picker_widget.dart';
import 'package:custom_file_picker/src/file_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:desktop_multi_window/desktop_multi_window.dart';

import '../custom_file_picker.dart';

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
      if (saveAs) {
        suggestedFile = FileData.fromJson(data["suggestedFile"]);
      }

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

  static Future<void> open(FileData fileHistory, Function(String) onSelectedFile) async {
    final window = await DesktopMultiWindow.createWindow(jsonEncode({
      'file': fileHistory,
      'saveAs': false,
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

  static Future<void> saveAs(
    FileData fileHistory,
    FileData suggestedFile,
    Function(String) onSelectedFile,
  ) async {
    _removeFiles(fileHistory);

    final window = await DesktopMultiWindow.createWindow(jsonEncode({
      'file': fileHistory,
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
}
