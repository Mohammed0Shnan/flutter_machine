
import 'package:flutter/material.dart';

class BouncingPressEffect extends StatefulWidget {
  final Widget child;
  final double minScale;
  const BouncingPressEffect(
      {super.key, required this.child, this.minScale = .8});

  @override
  State<BouncingPressEffect> createState() => BouncingPressEffectState();
}

class BouncingPressEffectState extends State<BouncingPressEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  @override
  void initState() {
    controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 300,
      ),
      reverseDuration: const Duration(
        milliseconds: 150,
      ),
    )..addListener(() {
        setState(() {});
      });

    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  double scale = 1;

  @override
  Widget build(BuildContext context) {
    scale = (1 - controller.value).clamp(widget.minScale, 1);
    return Listener(
      onPointerDown: (event) {
        controller.forward();
      },
      onPointerUp: (event) {
        controller.reset();
      },
      child: Transform.scale(scale: scale, child: widget.child),
    );
  }
}




















