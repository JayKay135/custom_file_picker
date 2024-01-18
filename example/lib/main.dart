import 'package:flutter/material.dart';
import 'package:custom_file_picker/custom_file_picker.dart';

void main(List<String> args) {
  ThemeData theme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      brightness: Brightness.light,
      seedColor: Colors.blue,
    ),
  );

  ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      brightness: Brightness.dark,
      seedColor: Colors.blue,
    ),
  );

  FilePicker(
    args,
    MainApp(theme: theme, darkTheme: darkTheme),
    theme: theme,
    darkTheme: darkTheme,
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key, this.theme, this.darkTheme});

  final ThemeData? theme;
  final ThemeData? darkTheme;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      themeMode: ThemeMode.dark,
      theme: theme,
      darkTheme: darkTheme,
      debugShowCheckedModeBanner: false,
      home: const Scaffold(
        body: TestWidget(),
      ),
    );
  }
}

class TestWidget extends StatefulWidget {
  const TestWidget({super.key});

  @override
  State<TestWidget> createState() => _TestWidgetState();
}

class _TestWidgetState extends State<TestWidget> {
  final FileData file = FileData.createFolder(
    "data",
    DateTime.now(),
    [
      FileData.createFolder("images", DateTime.now(), [
        FileData.createFileFromFileName("next_img.png", DateTime.now()),
        FileData.createFileFromFileName("something.txt", DateTime.now()),
        FileData.createFolder("files", DateTime.now(), [
          FileData.createFileFromFileName("idk.xml", DateTime.now()),
          FileData.createFileFromFileName("something.png", DateTime.now()),
          FileData.createFileFromFileName("test.txt", DateTime.now()),
        ]),
      ]),
      FileData.createFileFromFileName("test.xml", DateTime.now()),
      FileData.createFileFromFileName("idk.urdf", DateTime.now()),
    ],
  );

  final FileData suggestedFile = FileData.createFile("newFile", "txt", DateTime.now());

  FileData removeChildrensChildren(FileData fileData) {
    for (FileData subFile in fileData.children) {
      subFile.children = [];
    }

    return fileData;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () {
              FilePicker.open(file, ["xml", "png"], (String path) {
                print("selected: $path");
              }, context: context);
            },
            child: const Text("Open File"),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              FilePicker.saveAs(file, suggestedFile, (String path) {
                print("selected: $path");
              }, context: context);
            },
            child: const Text("Save As"),
          ),
          const Divider(height: 20, thickness: 3),
          ElevatedButton(
            onPressed: () {
              FilePicker.openAsync(removeChildrensChildren(file.copy()), ["xml", "png"], (String path) async {
                print("returning files for: $path");

                await Future.delayed(const Duration(seconds: 2));

                FileData? subData = file.getFileFromPath(path);
                return removeChildrensChildren(subData!.copy());
              }, (String path) {
                print("selected: $path");
              }, context: context);
            },
            child: const Text("Open File Async"),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              FilePicker.saveAsAsync(removeChildrensChildren(file.copy()), suggestedFile, (String path) async {
                // print("returning files for: $path");

                await Future.delayed(const Duration(seconds: 2));

                FileData? subData = file.getFileFromPath(path);
                return removeChildrensChildren(subData!.copy());
              }, (String path) {
                print("selected: $path");
              }, context: context);
            },
            child: const Text("Save As Async"),
          ),
        ],
      ),
    );
  }
}
