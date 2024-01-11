import 'package:flutter/material.dart';

/// A custom styled button widget.
class CustomButton extends StatefulWidget {
  const CustomButton({
    super.key,
    required this.iconPath,
    this.interactable = true,
    this.onTab,
  });

  final String iconPath;
  final bool interactable;
  final Function? onTab;

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  late bool hovering;

  @override
  void initState() {
    hovering = false;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.interactable) {
          widget.onTab?.call();
        }
      },
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
          padding: const EdgeInsets.all(4),
          width: 25,
          height: 25,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(5)),
            color: hovering && widget.interactable
                ? Theme.of(context).colorScheme.primary.withOpacity(0.05)
                : Colors.transparent,
          ),
          child: Image.asset(widget.iconPath,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withOpacity(widget.interactable ? 1 : 0.2)),
        ),
      ),
    );
  }
}
