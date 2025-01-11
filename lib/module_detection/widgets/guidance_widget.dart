import 'dart:io';
import 'dart:math';
import 'package:f_m/main.dart';
import 'package:f_m/module_detection/bloc/object_detect_bloc.dart';
import 'package:f_m/module_detection/screen/capture_display_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';

class GuidanceWidget extends StatefulWidget {
  const GuidanceWidget({super.key});

  @override
  State<GuidanceWidget> createState() => _GuidanceWidgetState();
}

class _GuidanceWidgetState extends State<GuidanceWidget> with SingleTickerProviderStateMixin {
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
    )..repeat(reverse: true); // Continuous bounce effect
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ObjectDetectionCubit, ObjectDetectionState>(
      bloc: context.read<ObjectDetectionCubit>(),
      builder: (context, state) {
        if (state.controller == null) {
          return const CircularProgressIndicator();
        }
        if (state.status == ObjectDetectionStatus.detecting) {
          _guidanceMessage = state.objectName ?? '...';
        } else if (state.status == ObjectDetectionStatus.notInPosition) {
          _guidanceMessage = state.message ?? "Adjust position...";
          _updateArrowDirection(state.direction!);
        } else if (state.status == ObjectDetectionStatus.inPosition) {
          _guidanceMessage = state.message ?? '';
          _captureImage(state.controller!);
        }

        return Column(
          children: [
            if(state.direction != null )
            _buildGuidanceMessage(_guidanceMessage),
            Container(
              color: Colors.black,
              padding: const EdgeInsets.all(5),
              child: const SizedBox.shrink(),
            ),
          ],
        );
      },
    );

  }

  void _updateArrowDirection(DirectionStatus newDirection) {
    double targetRotationAngle = 0.0;

    switch (newDirection) {
      case DirectionStatus.closer:
        targetRotationAngle = 0.0;
        break;
      case DirectionStatus.farther:
        targetRotationAngle = pi;
        break;
      case DirectionStatus.left:
        targetRotationAngle = -pi / 2;
        break;
      case DirectionStatus.right:
        targetRotationAngle = pi / 2;
        break;
      case DirectionStatus.center:
      case DirectionStatus.unknown:
        targetRotationAngle = 0.0;
        break;
    }

    // Update state to reflect the new angle and direction
    setState(() {
      _rotationAngle = targetRotationAngle;
      direction = newDirection;
    });
  }

  Offset _calculateTranslation(DirectionStatus direction) {
    double horizontalOffset = 0.0;
    double verticalOffset = 0.0;

    switch (direction) {
      case DirectionStatus.closer:
        horizontalOffset = 50 * _arrowController.value;
        verticalOffset = 50 * _arrowController.value;
        break;
      case DirectionStatus.farther:
        verticalOffset = -100 * _arrowController.value;
        break;
      case DirectionStatus.left:
        horizontalOffset = -100 * _arrowController.value;
        break;
      case DirectionStatus.right:
        horizontalOffset = 100 * _arrowController.value;
        break;
      case DirectionStatus.center:
      case DirectionStatus.unknown:
        horizontalOffset = 0.0;
        verticalOffset = 0.0;
        break;
    }

    return Offset(horizontalOffset, verticalOffset);
  }

  Future<void> _captureImage(CameraController controller) async {
    try {
      final image = await controller.takePicture();
      print('===========> Photo Captured <===========');
      _navigateToCapturedImageScreen(image);
    } catch (e) {
      print("Error capturing image: $e");
    }
  }

  void _navigateToCapturedImageScreen(XFile image) {
    final file = File(image.path);
    final objectType = "Object Type";
    final timestamp = DateTime.now().toString();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CapturedImageScreen(
          image: file,
          objectType: objectType,
          timestamp: timestamp,
        ),
      ),
    );
  }

  Widget _buildGuidanceMessage(String message) {
  Offset offset =  _calculateTranslation(direction);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FadeTransition(
          opacity: _arrowController.drive(CurveTween(curve: Curves.easeInOut)),
          child: Transform(
            transform: Matrix4.identity()
              ..rotateZ(_rotationAngle)
              ..translate(
                offset.dx,
                offset.dy,
              ),
            child: Icon(
              Icons.arrow_upward,
              size: 60,
              color: Colors.red,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
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
