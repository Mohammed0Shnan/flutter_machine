import 'package:flutter/material.dart';
import 'package:f_m/module_detection/models/recognition.dart';

class BoxWidget extends StatefulWidget {
  final Recognition result;
  final bool withoutBox;
  final double  positionThreshold;

  const BoxWidget({super.key, required this.result, required this.withoutBox ,this.positionThreshold = 5.0});
  @override
  State<BoxWidget> createState() => _BoxWidgetState();
}

class _BoxWidgetState extends State<BoxWidget> {

  Rect? previousLocation;


  @override
  void initState() {
    super.initState();
    previousLocation = widget.result.location;
  }
  @override
  Widget build(BuildContext context) {
    Color color = Colors.primaries[
    (widget.result.label.length + widget.result.label.codeUnitAt(0) + widget.result.id) %
        Colors.primaries.length
    ];
    final newLocation = widget.result.location;

    bool positionChanged = _hasPositionChanged(previousLocation!, newLocation);

    if (positionChanged) {
      previousLocation = newLocation;
    }
    return AnimatedPositioned(
      duration: Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      left: widget.result.renderLocation.left,
      top: widget.result.renderLocation.top,
      width: widget.result.renderLocation.width,
      height: widget.result.renderLocation.height,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        width: widget.result.renderLocation.width,
        height: widget.result.renderLocation.height,
        decoration: widget.withoutBox
            ? null
            : BoxDecoration(
          border: Border.all(color: color, width: 3),
          borderRadius: BorderRadius.all(Radius.circular(5)),
        ),
        child: Center(
          child: Text(
            widget.result.label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
  bool _hasPositionChanged(Rect oldLocation, Rect newLocation) {
    return (oldLocation.left - newLocation.left).abs() > widget.positionThreshold ||
        (oldLocation.top - newLocation.top).abs() > widget.positionThreshold;
  }
}

