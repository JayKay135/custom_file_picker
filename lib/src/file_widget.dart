import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

import 'file_picker_widget.dart';
import 'immediate_multi_tap_gesture_recognizer.dart';
import '../custom_file_picker.dart';

// ignore: must_be_immutable
class FileWidget extends StatefulWidget {
  FileWidget({
    super.key,
    required this.fileData,
    this.onDoubleTab,
    this.sizes,
    this.deselect = false,
    this.showExtension = true,
  }) {
    _globalKey = GlobalKey<_FileWidgetState>();
  }

  final FileData fileData;
  final Function? onDoubleTab;
  final List<double>? sizes;
  final bool deselect;
  final bool showExtension;

  // ignore: library_private_types_in_public_api
  late GlobalKey<_FileWidgetState> _globalKey;

  // ignore: library_private_types_in_public_api
  static _FileWidgetState? lastSelectedFile;

  @override
  State<FileWidget> createState() => _FileWidgetState();
}

class _FileWidgetState extends State<FileWidget> {
  late bool hovering;
  late bool selected;

  @override
  void initState() {
    hovering = false;
    selected = false;

    super.initState();
  }

  void deselect() {
    setState(() {
      selected = false;
    });
  }

  /// Returns the image path for the given [fileData].
  String getImagePath(FileData fileData) {
    if (fileData.isFolder) {
      return 'packages/custom_file_picker/assets/images/folder_icon.png';
    }

    switch (fileData.extension) {
      case "txt":
        return 'packages/custom_file_picker/assets/images/text_icon.png';

      case "png":
      case "jpg":
        return 'packages/custom_file_picker/assets/images/image_icon.png';

      case "urdf":
      case "dae":
      case "xml":
        return 'packages/custom_file_picker/assets/images/urdf_icon.png';

      default:
        return 'packages/custom_file_picker/assets/images/text_icon.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.deselect) {
      selected = false;
    }

    return RawGestureDetector(
      key: widget._globalKey,
      behavior: HitTestBehavior.opaque,
      gestures: {
        ImmediateMultiTapGestureRecognizer: GestureRecognizerFactoryWithHandlers<ImmediateMultiTapGestureRecognizer>(
          () => ImmediateMultiTapGestureRecognizer(
            numberOfTaps: 2,
            tapTimeout: const Duration(milliseconds: 300),
          ),
          (ImmediateMultiTapGestureRecognizer instance) {
            instance
              ..onSingleTap = () {
                setState(() {
                  selected = !selected;

                  if (selected && !widget.fileData.isFolder) {
                    _FileWidgetState? lastFileWidget = FileWidget.lastSelectedFile;
                    FileWidget.lastSelectedFile = this;

                    if (lastFileWidget != null && lastFileWidget.mounted) {
                      lastFileWidget.setState(() {});
                    }
                    FilePickerWidget.selectedFile = FilePickerWidget.selectedFile == widget.fileData ? null : widget.fileData;
                  }
                });
              }
              ..onDoubleTap = () {
                widget.onDoubleTab?.call();
              };
          },
        ),
      },
      // GestureDetector(
      //   onTapDown: (details) {
      //     setState(() {
      //       selected = !selected;
      //
      //       if (selected) {
      //         _FileWidgetState? lastFileWidget = FileWidget.lastSelectedFile;
      //         FileWidget.lastSelectedFile = this;
      //         lastFileWidget?.setState(() {});
      //
      //         FilePickerWidget.selectedFile = FilePickerWidget.selectedFile == widget.fileData ? null : widget.fileData;
      //       }
      //     });
      //   },
      //   onDoubleTap: () {
      //     widget.onDoubleTab?.call();
      //   },
      child: MouseRegion(
        onEnter: (event) {
          setState(() {
            hovering = true;
          });
        },
        onExit: (event) {
          setState(() {
            hovering = false;
          });
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.only(left: 2),
          height: 25,
          decoration: BoxDecoration(
              color: selected
                  ? Theme.of(context).colorScheme.primaryContainer
                  // FileWidget.lastSelectedFile == this
                  //     ? Theme.of(context).colorScheme.primaryContainer
                  //     : Theme.of(context).colorScheme.primaryContainer
                  : hovering
                      ? Theme.of(context).colorScheme.surfaceVariant
                      : Colors.transparent,
              borderRadius: const BorderRadius.all(Radius.circular(2)),
              border: Border.all(color: selected && FileWidget.lastSelectedFile == this ? Theme.of(context).colorScheme.primary : Colors.transparent)),
          child: ListView(
            shrinkWrap: true,
            scrollDirection: Axis.horizontal,
            children: [
              Image.asset(getImagePath(widget.fileData), width: 20),
              const SizedBox(width: 5),
              SizedBox(
                width: widget.sizes != null ? widget.sizes![0] - 20 : 200,
                child: Text(
                  widget.fileData.isFolder ? widget.fileData.name : "${widget.fileData.name}${widget.showExtension ? ".${widget.fileData.extension}" : ""}",
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              (widget.sizes != null ? widget.sizes![1] - 2 : 200) > 10
                  ? SizedBox(
                      width: widget.sizes != null ? widget.sizes![1] - 2 : 200,
                      child: Text(
                        DateFormat("dd.MM.yyyy HH:mm").format(widget.fileData.lastModified),
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  : const SizedBox(),
            ],
          ),
        ),
      ),
    );
  }
}
