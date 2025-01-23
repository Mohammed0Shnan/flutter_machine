import 'dart:async';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:f_m/module_detection/bloc/object_detect_bloc.dart';
import 'package:f_m/module_detection/screen/capture_display_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'count_down_animation.dart';

class GuidanceWidget extends StatefulWidget {
  const GuidanceWidget({super.key});

  @override
  State<GuidanceWidget> createState() => _GuidanceWidgetState();
}

class _GuidanceWidgetState extends State<GuidanceWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _arrowController;
  late double _rotationAngle;
  late DirectionStatus direction;
  late ObjectDetectionCubit detectBloc;
  String _guidanceMessage = "";

  @override
  void initState() {
    super.initState();
    _rotationAngle = 0.0;
    direction = DirectionStatus.unknown;

    _arrowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )
      ..repeat(reverse: true)
      ..addListener(() {
        setState(() {});
      });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ObjectDetectionCubit>().state;
    if (state.controller == null) {
      return const CircularProgressIndicator();
    }
    if (state.status == ObjectDetectionStatus.detecting) {
      _guidanceMessage = '${state.objectName} detection...' ?? '';
    } else if (state.status == ObjectDetectionStatus.notInPosition) {
      _guidanceMessage = state.message ?? "Adjust position...";
      _updateArrowDirection(state.direction!);
    } else if (state.status == ObjectDetectionStatus.inPosition) {
      _guidanceMessage = '${state.message}, don\'t move!' ?? '';
    }
    return _buildGuidanceMessage(_guidanceMessage, state);
  }

  Future<void> _captureImage(
      {required XFile image,
      required Rect boundingBox,
      required String objectName}) async {
    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CapturedImageScreen(
            image: image,
            boundingBox: boundingBox,
            objectName: objectName,
          ),
        ),
      );
    } catch (e) {
      debugPrint("Error capturing image: $e");
    } finally {}
  }

  void _updateArrowDirection(DirectionStatus newDirection) {
    double targetRotationAngle = 0.0;
    // Set rotation angle based on direction
    switch (newDirection) {
      case DirectionStatus.left:
        targetRotationAngle = -pi / 2;
        break;
      case DirectionStatus.right:
        targetRotationAngle = pi / 2;
        break;
      case DirectionStatus.up:
        targetRotationAngle = 0;
        break;
      case DirectionStatus.down:
        targetRotationAngle = -pi;
        break;
      case DirectionStatus.center:
      case DirectionStatus.unknown:
        targetRotationAngle = 0.0;
        break;
    }
    // Update the rotation angle and direction
    _rotationAngle = targetRotationAngle;
    direction = newDirection;
  }

  Offset _calculateTranslation(DirectionStatus direction) {
    double horizontalOffset = 0.0;
    double verticalOffset = 0.0;
    switch (direction) {
      case DirectionStatus.left:
        horizontalOffset = -80;
        break;
      case DirectionStatus.right:
        horizontalOffset = 80;
        break;
      case DirectionStatus.up:
        verticalOffset = 80;
        break;
      case DirectionStatus.down:
        verticalOffset = -80;
        break;
      case DirectionStatus.center:
      case DirectionStatus.unknown:
        horizontalOffset = 0.0;
        verticalOffset = 0.0;
        break;
    }
    return Offset(horizontalOffset, verticalOffset);
  }

  Widget _buildGuidanceMessage(String message, ObjectDetectionState state) {
    Offset offset = _calculateTranslation(direction);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 10),
        Text(
          message,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        state.status == ObjectDetectionStatus.inPosition
            ? CountdownAnimation(
                onCountdownComplete: () async {
                  try{
                    state.controller?.pausePreview();
                    context.read<ObjectDetectionCubit>().capture();
                    XFile? capturedImage = await state.controller?.takePicture();
                    await state.controller?.resumePreview();

                    _captureImage(
                        image: capturedImage!,
                        boundingBox: state.boundingBox!,
                        objectName: state.objectName!);
                  }catch(e){
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:   Text(
                      "Error occurred while capturing, move to detect!",
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),));
                  }

                },
              )
            : AnimatedBuilder(
                animation: _arrowController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      offset.dx * _arrowController.value,
                      offset.dy * _arrowController.value,
                    ),
                    child: Hero(
                      tag: 'hero_camera_icon',
                      child: direction == DirectionStatus.unknown
                          ? SizedBox.shrink()
                          : Transform.rotate(
                              angle: _rotationAngle,
                              child: Icon(
                                Icons.arrow_upward,
                                size: 60,
                                color: Colors.red,
                              ),
                            ),
                    ),
                  );
                },
              ),
      ],
    );
  }

  @override
  void dispose() {
    _arrowController.dispose();
    super.dispose();
  }
}
