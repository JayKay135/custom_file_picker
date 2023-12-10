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

      // set parent references
      setParentReferences(file);

      runApp(
        MaterialApp(
          themeMode: ThemeMode.dark,
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: FilePickerWidget(windowController: WindowController.fromWindowId(windowId), file: file),
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

  static void setParentReferences(FileData fileData) {
    for (FileData child in fileData.children) {
      child.parent = fileData;

      setParentReferences(child);
    }
  }

  static Future<void> openSecondaryWindow(FileData file, Function(FileData) onSelectedFile) async {
    final window = await DesktopMultiWindow.createWindow(jsonEncode({
      'file': file,
    }));
    window
      ..setFrame(const Offset(0, 0) & const Size(800, 450))
      ..center()
      ..setTitle('File Picker')
      ..show();

    DesktopMultiWindow.setMethodHandler((call, fromWindowId) async {
      switch (call.method) {
        case "open":
          Map<String, dynamic> data = jsonDecode(call.arguments);
          onSelectedFile(FileData.fromJson(data));
      }

      // debugPrint('${call.method} ${call.arguments} $fromWindowId');
      return "";
    });
  }
}
