import 'package:flutter/material.dart';

/// A draggable floating action button. Keeps itself within screen bounds.
class DraggableFab extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final double initRight;
  final double initBottom;

  const DraggableFab({
    Key? key,
    required this.child,
    required this.onPressed,
    this.initRight = 16,
    this.initBottom = 24,
  }) : super(key: key);

  @override
  State<DraggableFab> createState() => _DraggableFabState();
}

class _DraggableFabState extends State<DraggableFab> {
  late double right;
  late double bottom;

  @override
  void initState() {
    super.initState();
    right = widget.initRight;
    bottom = widget.initBottom;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      right = (right - details.delta.dx).clamp(
        8.0,
        MediaQuery.of(context).size.width - 56 - 8.0,
      );
      bottom = (bottom - details.delta.dy).clamp(
        8.0,
        MediaQuery.of(context).size.height - 56 - 8.0,
      );
    });
  }

  void _onTap() {
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: right,
      bottom: bottom,
      child: GestureDetector(
        onPanUpdate: _onPanUpdate,
        onTap: _onTap,
        child: Material(
          elevation: 6,
          shape: const CircleBorder(),
          color: Colors.transparent,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color:
                  Theme.of(context).floatingActionButtonTheme.backgroundColor ??
                  Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
            child: Center(child: widget.child),
          ),
        ),
      ),
    );
  }
}
