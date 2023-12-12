import 'dart:math';

import 'package:flutter/material.dart';

class SplitViewWidget extends StatefulWidget {
  const SplitViewWidget({
    super.key,
    required this.widgets,
    this.sizesChanged,
  });

  final List<Widget> widgets;
  final Function(List<double>)? sizesChanged;

  @override
  State<SplitViewWidget> createState() => _SplitViewWidgetState();
}

class _SplitViewWidgetState extends State<SplitViewWidget> {
  final double dividerSize = 3;
  final double minWidth = 50;

  /// The sizes of the split view widgets before the dragging started
  late List<double> startSizes;

  /// Used sizes for the split view widgets during dragging
  late List<double?> sizes;

  late List<bool> dragging;

  late double maxSize;

  double totalDelta = 0.0;

  @override
  void initState() {
    sizes = List.generate(widget.widgets.length, (index) => null);
    dragging = List.generate(widget.widgets.length - 1, (index) => false);

    super.initState();
  }

  List<Widget> _createListContent(BoxConstraints constraints) {
    maxSize = constraints.maxWidth - dividerSize * (widget.widgets.length - 1);

    List<Widget> newWidgets = [];

    for (int i = 0; i < widget.widgets.length; i++) {
      sizes[i] ??= 220;
      // maxSize / widget.widgets.length;

      if (sizes[i] != 0) {
        newWidgets.add(
          SizedBox(
            width: sizes[i]!,
            height: constraints.maxHeight,
            child: Align(
              alignment: Alignment.centerLeft,
              child: widget.widgets[i],
            ),
          ),
        );
      }

      // insert dividers that control the split size
      if (i < widget.widgets.length - 1) {
        newWidgets.add(
          Stack(
            children: [
              // this is the actual line that changes width
              Container(
                color: dragging[i] ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outlineVariant,
                width: dragging[i] ? dividerSize : 1,
                height: double.infinity,
              ),
              // this is the MouseRegion that always has a width of 3
              MouseRegion(
                cursor: SystemMouseCursors.resizeLeftRight,
                child: GestureDetector(
                  // behavior: HitTestBehavior.translucent,
                  child: Container(
                    color: Colors.transparent,
                    width: dividerSize,
                    height: double.infinity,
                  ),
                  onPanStart: (DragStartDetails details) {
                    setState(() {
                      dragging[i] = true;

                      startSizes = List.of(sizes.map((e) => e!));
                    });
                  },
                  onPanUpdate: (DragUpdateDetails details) {
                    setState(() {
                      totalDelta += details.delta.dx;

                      // double newWidth1 = (startSizes[i] + totalDelta).clamp(minWidth, maxSize - minWidth);
                      // double newWidth2 = (startSizes[i + 1] - totalDelta).clamp(minWidth, maxSize - newWidth1);

                      // // ensure total size doesn't exceed maxSize
                      // if (newWidth1 + newWidth2 <= startSizes[i] + startSizes[i + 1]) {
                      //   sizes[i] = newWidth1;
                      //   sizes[i + 1] = newWidth2;
                      // }

                      double newWidth1 = (startSizes[i] + totalDelta).clamp(minWidth, maxSize - minWidth);
                      double newWidth2 = (startSizes[i + 1] - totalDelta).clamp(minWidth, maxSize - minWidth);

                      // ensure total size doesn't exceed maxSize
                      if (newWidth1 + newWidth2 <= startSizes[i] + startSizes[i + 1]) {
                        // + 0.01
                        sizes[i] = newWidth1;
                        sizes[i + 1] = newWidth2;
                      }

                      // double newWidth1 = (startSizes[i] + totalDelta).clamp(minWidth, maxSize - minWidth);
                      // double newWidth2 = startSizes[i + 1] - totalDelta;

                      // // if the width of the right widget is below the threshold, adjust its size
                      // if (newWidth2 < 200) {
                      //   newWidth2 = newWidth2.clamp(minWidth, maxSize - newWidth1);
                      //   sizes[i + 1] = newWidth2;
                      // }

                      // // ensure total size doesn't exceed maxSize
                      // if (newWidth1 + newWidth2 <= startSizes[i] + startSizes[i + 1]) {
                      //   sizes[i] = newWidth1;
                      // }
                    });

                    widget.sizesChanged?.call(sizes.map((e) => e!).toList());
                  },
                  onPanEnd: (DragEndDetails details) {
                    setState(() {
                      dragging[i] = false;

                      totalDelta = 0.0;
                    });
                  },
                ),
              ),
            ],
          ),
        );
      }
    }

    return newWidgets;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: _createListContent(constraints),
        );
      },
    );
  }
}
