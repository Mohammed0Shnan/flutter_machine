import 'dart:io';
import 'dart:math';
import 'package:f_m/main.dart';
import 'package:f_m/state_managment/camera_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';

import '../state_managment/object_detect_state_managment.dart';
import 'capture_display_screen.dart';

class GuidanceWidget extends StatefulWidget {
  const GuidanceWidget({super.key});

  @override
  State<GuidanceWidget> createState() => _GuidanceWidgetState();
}

class _GuidanceWidgetState extends State<GuidanceWidget> with SingleTickerProviderStateMixin {
  late AnimationController _arrowController;
  String _guidanceMessage = "";
  late double _rotationAngle;


  @override
  void initState() {
    super.initState();
    _rotationAngle =0.0;
    _arrowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _arrowController.addListener((){
      setState(() {
      });
    });
    _arrowController.repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {

    return Column(
      children: [
        _buildGuidanceMessage(_guidanceMessage),
        Container(
          color: Colors.black,
          padding: EdgeInsets.all(5),
          child: BlocBuilder
          <ObjectDetectionCubit, ObjectDetectionState>(
            bloc: detectBloc,
            builder: (context, state) {
              if (state.controller == null) {
                return const CircularProgressIndicator();
              }

              if (state.status == ObjectDetectionStatus.detecting) {
                _guidanceMessage = state.objectName??'...';
              } else if (state.status == ObjectDetectionStatus.notInPosition) {
                _guidanceMessage = state.message ?? "Adjust position...";
                _updateArrowDirection(state.direction!);
              } else if (state.status == ObjectDetectionStatus.inPosition) {
                _guidanceMessage = state.message??'';
                _captureImage(state.controller!);
              }

              return SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }


  void _updateArrowDirection(DirectionStatus direction) {
    double rotationAngle = 0.0;

    switch (direction) {
      case DirectionStatus.closer:
        rotationAngle = 0.0;
        break;
      case DirectionStatus.farther:
        rotationAngle = pi;
        break;
      case DirectionStatus.left:
        rotationAngle = -pi / 2;
        break;
      case DirectionStatus.right:
        rotationAngle = pi / 2;
        break;
      case DirectionStatus.center:
      case DirectionStatus.unknown:
        rotationAngle = 0.0;
        break;
    }
    setState(() {
      _rotationAngle = rotationAngle;
    });
  }



  Future<void> _captureImage(CameraController controller) async {
    try {
      final image = await controller.takePicture();
      print('===========> Photo Captured <===========');
      // _navigateToCapturedImageScreen(image);
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FadeTransition(
          opacity: _arrowController.drive(CurveTween(curve: Curves.easeInOut)), // Fade animation
          child: Transform.scale(
            scale: 1 + 0.1 * _arrowController.value,
            child: Transform.rotate(
              angle: _rotationAngle,
              child: Icon(
                Icons.arrow_upward,
                size: 60,
                color: Colors.red,
              ),
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


