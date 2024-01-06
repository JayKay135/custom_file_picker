import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/widgets.dart';

import 'custom_button.dart';
import 'file_widget.dart';
import 'split_view_widget.dart';
import '../custom_file_picker.dart';

/// The widget that actually builds the file picker visually
class FilePickerWidget extends StatefulWidget {
  FilePickerWidget({
    super.key,
    required this.windowController,
    required this.file,
    this.saveAs = false,
    this.suggestedFile,
    this.extensions,
    this.async = false,
    this.showExtension = true,
  }) {
    selectedFile = null;
  }

  final WindowController windowController;

  /// To visualize file data
  final FileData file;

  /// Whether this a file saving or opening picker widget
  final bool saveAs;

  /// Data for suggested file name for file saving
  final FileData? suggestedFile;

  /// List of allowed extensions for file selection
  final List<String>? extensions;

  /// Wether this is an async file picker or not
  final bool async;

  /// Whether to show extensions for files or not
  final bool showExtension;

  /// Lastly selected file
  static FileData? selectedFile;

  @override
  State<FilePickerWidget> createState() => _FilePickerWidgetState();
}

class _FilePickerWidgetState extends State<FilePickerWidget> {
  late FileData _openedFile;
  List<double>? sizes;

  late bool _deselectAll;

  late TextEditingController _textEditingController;

  late bool _waitingForData;

  /// Creates the header widget for the file picker.
  ///
  /// This method takes a [FileData] object as a parameter and returns a widget
  /// that represents the header for the file picker. The header typically contains
  /// information about the selected file.
  ///
  /// Example usage:
  /// ```dart
  /// Widget headerWidget = _createHeader(fileData);
  /// ```
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

  /// Creates the content widget for the given [file].
  Widget _createContent(FileData file) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Stack(
        children: [
          Column(
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
                    WidgetsBinding.instance.addPostFrameCallback(
                      (_) => setState(() {
                        this.sizes = sizes;
                      }),
                    );
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
                physics: const NeverScrollableScrollPhysics(),
                itemCount: file.children.length,
                itemBuilder: (BuildContext context, int index) {
                  return FileWidget(
                    fileData: file.children[index],
                    sizes: sizes, // ?? List.generate(3, (index) => context.size!.width / 3),
                    deselect: _deselectAll,
                    showExtension: widget.showExtension,
                    onDoubleTab: () async {
                      if (file.children[index].isFolder) {
                        if (widget.async) {
                          setState(() {
                            _waitingForData = true;
                          });

                          var json = await DesktopMultiWindow.invokeMethod(
                            0,
                            "getFileData",
                            file.children[index].getPath(),
                            // jsonEncode(FilePickerWidget.selectedFile!.toJson()),
                          );

                          FileData fileData = FileData.fromJson(jsonDecode(json));
                          for (FileData child in fileData.children) {
                            child.parent = fileData;
                          }

                          file.children[index] = fileData;
                          fileData.parent = file;
                        }

                        setState(() {
                          _openedFile = file.children[index];

                          _waitingForData = false;
                          _deselectAll = true;
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
                  behavior: HitTestBehavior.deferToChild,
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  widget.saveAs
                      ? Expanded(
                          child: TextField(
                            controller: _textEditingController,
                            decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                          ),
                        )
                      : const SizedBox(),
                  widget.saveAs
                      ? Container(
                          padding: const EdgeInsets.all(7),
                          margin: const EdgeInsets.only(left: 5),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(".${widget.suggestedFile!.extension}"),
                        )
                      : const SizedBox(),
                  widget.saveAs ? const SizedBox(width: 10) : const SizedBox(),
                  ElevatedButton(
                      onPressed: () async {
                        if (!widget.saveAs && FilePickerWidget.selectedFile != null) {
                          // remove children data to decrease String size
                          FilePickerWidget.selectedFile!.children = [];

                          await DesktopMultiWindow.invokeMethod(
                            0,
                            "open",
                            "${FilePickerWidget.selectedFile!.getPath()}.${FilePickerWidget.selectedFile!.extension}",
                            // jsonEncode(FilePickerWidget.selectedFile!.toJson()),
                          );

                          widget.windowController.close();
                        } else if (widget.saveAs) {
                          // int dotIndex = _textEditingController.text.lastIndexOf('.');

                          // String name = dotIndex == -1 ? _textEditingController.text : _textEditingController.text.substring(0, dotIndex);
                          // String extension = dotIndex == -1 ? '' : _textEditingController.text.substring(dotIndex + 1);

                          // widget.suggestedFile!.name = name;
                          // widget.suggestedFile!.extension = extension;

                          widget.suggestedFile!.name = _textEditingController.text;

                          if (file.children.firstWhereOrNull((element) => element.name == widget.suggestedFile!.name) != null) {
                            // choosen name identical to already exisiting file
                            _showFileAlreadyExistsScreen(
                                "${widget.suggestedFile!.name}${widget.suggestedFile!.isFolder ? "" : ".${widget.suggestedFile!.extension}"}", () async {
                              widget.suggestedFile!.parent = _openedFile;

                              await DesktopMultiWindow.invokeMethod(
                                0,
                                "saveAs",
                                "${widget.suggestedFile!.getPath()}.${widget.suggestedFile!.extension}",
                                // jsonEncode(widget.suggestedFile!.toJson()),
                              );

                              widget.windowController.close();
                            });
                          } else {
                            widget.suggestedFile!.parent = _openedFile;

                            await DesktopMultiWindow.invokeMethod(
                              0,
                              "saveAs",
                              "${widget.suggestedFile!.getPath()}.${widget.suggestedFile!.extension}",
                              // jsonEncode(widget.suggestedFile!.toJson()),
                            );

                            widget.windowController.close();
                          }
                        }
                      },
                      child: Text(widget.saveAs ? "Save As" : "Open")),
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
          // Positioned(
          //   bottom: 0,
          //   child: SizedBox(
          //     width: MediaQuery.of(context).size.width - 20,
          //     child:

          //   ),
          // ),
          // Positioned(
          //   bottom: 0,
          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.end,
          //     // scrollDirection: Axis.horizontal,
          //     // primary: false,
          //     // physics: NeverScrollableScrollPhysics(),
          //     children: [
          //       widget.saveAs
          //           ? Expanded(
          //               child: TextField(
          //                 controller: _textEditingController,
          //                 decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
          //               ),
          //             )
          //           : const SizedBox(),
          //       widget.saveAs
          //           ? Container(
          //               padding: const EdgeInsets.all(7),
          //               margin: const EdgeInsets.only(left: 5),
          //               decoration: BoxDecoration(
          //                 color: Theme.of(context).colorScheme.secondaryContainer,
          //                 borderRadius: BorderRadius.circular(10),
          //               ),
          //               child: Text(".${widget.suggestedFile!.extension}"),
          //             )
          //           : const SizedBox(),
          //       widget.saveAs ? const SizedBox(width: 10) : const SizedBox(),
          //       ElevatedButton(
          //           onPressed: () async {
          //             if (!widget.saveAs && FilePickerWidget.selectedFile != null) {
          //               // remove children data to decrease String size
          //               FilePickerWidget.selectedFile!.children = [];

          //               await DesktopMultiWindow.invokeMethod(
          //                 0,
          //                 "open",
          //                 "${FilePickerWidget.selectedFile!.getPath()}.${FilePickerWidget.selectedFile!.extension}",
          //                 // jsonEncode(FilePickerWidget.selectedFile!.toJson()),
          //               );

          //               widget.windowController.close();
          //             } else if (widget.saveAs) {
          //               // int dotIndex = _textEditingController.text.lastIndexOf('.');

          //               // String name = dotIndex == -1 ? _textEditingController.text : _textEditingController.text.substring(0, dotIndex);
          //               // String extension = dotIndex == -1 ? '' : _textEditingController.text.substring(dotIndex + 1);

          //               // widget.suggestedFile!.name = name;
          //               // widget.suggestedFile!.extension = extension;

          //               widget.suggestedFile!.name = _textEditingController.text;

          //               if (file.children.firstWhereOrNull((element) => element.name == widget.suggestedFile!.name) != null) {
          //                 // choosen name identical to already exisiting file
          //                 _showFileAlreadyExistsScreen(
          //                     "${widget.suggestedFile!.name}${widget.suggestedFile!.isFolder ? "" : ".${widget.suggestedFile!.extension}"}", () async {
          //                   widget.suggestedFile!.parent = _openedFile;

          //                   await DesktopMultiWindow.invokeMethod(
          //                     0,
          //                     "saveAs",
          //                     "${widget.suggestedFile!.getPath()}.${widget.suggestedFile!.extension}",
          //                     // jsonEncode(widget.suggestedFile!.toJson()),
          //                   );

          //                   widget.windowController.close();
          //                 });
          //               } else {
          //                 widget.suggestedFile!.parent = _openedFile;

          //                 await DesktopMultiWindow.invokeMethod(
          //                   0,
          //                   "saveAs",
          //                   "${widget.suggestedFile!.getPath()}.${widget.suggestedFile!.extension}",
          //                   // jsonEncode(widget.suggestedFile!.toJson()),
          //                 );

          //                 widget.windowController.close();
          //               }
          //             }
          //           },
          //           child: Text(widget.saveAs ? "Save As" : "Open")),
          //       const SizedBox(width: 10),
          //       ElevatedButton(
          //           onPressed: () {
          //             widget.windowController.close();
          //           },
          //           child: const Text("Cancel")),
          //       const SizedBox(width: 10),
          //     ],
          //   ),
          // ),
          _waitingForData
              ? Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              : const SizedBox(),
        ],
      ),
    );
  }

  /// Shows a screen indicating that the file with the given [fileName] already exists.
  ///
  /// This method is used to display a screen to the user indicating that a file with the same name already exists.
  /// The user is given the option to replace the existing file by calling the [onReplace] function.
  ///
  /// Example usage:
  /// ```dart
  /// _showFileAlreadyExistsScreen('example.txt', () {
  ///   // Replace the existing file logic
  /// });
  /// ```
  Future<void> _showFileAlreadyExistsScreen(String fileName, Function onReplace) async {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              "\"$fileName\" already exists",
            ),
            content: const Text(
              "A file or folder with the same name already exists in this location.\nReplacing it will overwrite its current contents.",
            ),
            actions: <Widget>[
              TextButton(
                  style: TextButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primaryContainer),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    "Cancel",
                    style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
                  )),
              TextButton(
                style: TextButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.errorContainer),
                onPressed: () {
                  Navigator.of(context).pop();

                  onReplace();
                },
                child: Text(
                  "Replace",
                  style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                ),
              ),
            ],
          );
        });
  }

  @override
  void initState() {
    _openedFile = widget.file;

    _deselectAll = false;

    _textEditingController = TextEditingController(text: widget.saveAs ? widget.suggestedFile!.name : "");

    _waitingForData = false;

    super.initState();
  }

  @override
  void dispose() {
    _textEditingController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _createContent(_openedFile);
  }
}
