import 'dart:convert';

import 'package:custom_file_picker/src/custom_button.dart';
import 'package:custom_file_picker/src/split_view_widget.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';

import '../custom_file_picker.dart';
import 'file_widget.dart';

class FilePickerWidget extends StatefulWidget {
  FilePickerWidget({
    super.key,
    required this.windowController,
    required this.file,
  }) {
    selectedFile = null;
  }

  final WindowController windowController;
  final FileData file;

  static FileData? selectedFile;

  @override
  State<FilePickerWidget> createState() => _FilePickerWidgetState();
}

class _FilePickerWidgetState extends State<FilePickerWidget> {
  late FileData _openedFile;
  List<double>? sizes;

  late bool _deselectAll;

  Widget _createHeader(FileData file) {
    List<Widget> content = [];

    // List<String> elements = file.getPath().split('/');
    FileData? fileData = file;

    // for (int i = 0; i < elements.length; i++) {
    //   content.add(Padding(
    //     padding: EdgeInsets.all(10),
    //     child: Text(elements[i]),
    //   ));

    //   if (i < elements.length - 1) {
    //     content.add(Padding(
    //       padding: EdgeInsets.all(00),
    //       child: Icon(Icons.keyboard_arrow_right, size: 15),
    //     ));
    //   }
    // }

    while (fileData != null) {
      FileData? currentFileData = fileData;

      content.add(GestureDetector(
          onTap: () {
            setState(() {
              _openedFile = currentFileData;
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Text(fileData.name),
          )));

      if (fileData.parent != null) {
        content.add(const Padding(
          padding: EdgeInsets.all(00),
          child: Icon(Icons.keyboard_arrow_right, size: 15),
        ));
      }

      fileData = fileData.parent;
    }

    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: content.reversed.toList());
  }

  Widget _createContent(FileData file) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomButton(
                interactable: file.parent != null,
                onTab: () {
                  setState(() {
                    if (_openedFile.parent != null) {
                      _openedFile = _openedFile.parent!;
                    }
                  });
                },
                iconPath: "packages/custom_file_picker/assets/images/arrow.png",
              ),
              _createHeader(_openedFile),
            ],
          ),
          SizedBox(
            height: 30,
            child: SplitViewWidget(
              sizesChanged: (List<double> sizes) {
                setState(() {
                  this.sizes = sizes;
                });
              },
              widgets: [
                Container(
                  padding: const EdgeInsets.only(left: 5),
                  width: double.infinity,
                  child: const Text("Name", overflow: TextOverflow.ellipsis),
                ),
                Container(
                  padding: const EdgeInsets.only(left: 5),
                  width: double.infinity,
                  child: const Text("Date modified", overflow: TextOverflow.ellipsis),
                ),
                // Container(
                //   padding: const EdgeInsets.only(left: 5),
                //   width: double.infinity,
                //   child: const Text("Type", overflow: TextOverflow.ellipsis),
                // ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            itemCount: file.children.length,
            itemBuilder: (BuildContext context, int index) {
              return FileWidget(
                fileData: file.children[index],
                sizes: sizes,
                deselect: _deselectAll,
                onDoubleTab: () async {
                  if (file.children[index].isFolder) {
                    setState(() {
                      _deselectAll = true;
                      _openedFile = file.children[index];
                    });

                    await Future.delayed(const Duration(milliseconds: 100));

                    setState(() {
                      _deselectAll = false;
                    });
                  }
                },
              );
            },
          ),
          Expanded(
            child: GestureDetector(
              onTap: () async {
                setState(() {
                  _deselectAll = true;
                });

                await Future.delayed(const Duration(milliseconds: 100));

                setState(() {
                  _deselectAll = false;
                });
              },
              child: Container(color: Colors.transparent),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                  onPressed: () async {
                    if (FilePickerWidget.selectedFile != null) {
                      // remove children data to decrease String size
                      FilePickerWidget.selectedFile!.children = [];

                      await DesktopMultiWindow.invokeMethod(
                        0,
                        "open",
                        jsonEncode(FilePickerWidget.selectedFile!.toJson()),
                      );

                      widget.windowController.close();
                    }
                  },
                  child: const Text("Open")),
              const SizedBox(width: 10),
              ElevatedButton(
                  onPressed: () {
                    widget.windowController.close();
                  },
                  child: const Text("Cancel")),
              const SizedBox(width: 10),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    _openedFile = widget.file;

    _deselectAll = false;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return _createContent(_openedFile);
  }
}
