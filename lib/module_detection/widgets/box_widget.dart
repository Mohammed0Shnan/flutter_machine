import 'package:flutter/material.dart';
import 'package:f_m/models/recognition.dart';

class BoxWidget extends StatelessWidget {
  final Recognition result;
  const BoxWidget({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    Color color = Colors.primaries[
    (result.label.length + result.label.codeUnitAt(0) + result.id) %
        Colors.primaries.length];

    return Positioned(
      left: result.renderLocation.left,
      top: result.renderLocation.top,
      width: result.renderLocation.width,
      height: result.renderLocation.height,
      child: Container(
        width: result.renderLocation.width,
        height: result.renderLocation.height,
        decoration: BoxDecoration(
            border: Border.all(color: color, width: 3),
            borderRadius: const BorderRadius.all(Radius.circular(5))),
        child: Text(
          result.label,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
