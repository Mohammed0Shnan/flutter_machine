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
  String _guidanceMessage = "";
  late double _rotationAngle;
late DirectionStatus direction ;
  late ObjectDetectionCubit detectBloc;
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
        BlocBuilder
        <ObjectDetectionCubit, ObjectDetectionState>(
            bloc: context.read<ObjectDetectionCubit>(),
            builder: (context, state) {
             if(  state.direction  == null){
               return SizedBox.shrink();
             }
             direction =  state.direction!;
             return _buildGuidanceMessage(_guidanceMessage);
          }
        ),
        Container(
          color: Colors.black,
          padding: EdgeInsets.all(5),
          child: BlocBuilder
          <ObjectDetectionCubit, ObjectDetectionState>(
            bloc: context.read<ObjectDetectionCubit>(),
            builder: (context, state) {
              if (state.controller == null) {
                return const CircularProgressIndicator();
              }
              if (state.status == ObjectDetectionStatus.detecting) {
                _guidanceMessage = state.objectName??'...';
              } else if (state.status == ObjectDetectionStatus.notInPosition) {
                _guidanceMessage = state.message ?? "Adjust position...";
                direction = state.direction!;
                _updateArrowDirection(direction);
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
      _rotationAngle = rotationAngle;
  }
  // Function to calculate the position offset based on the direction
  Offset _calculateTranslation(DirectionStatus direction) {
    double horizontalOffset = 0.0;
    double verticalOffset = 0.0;

    switch (direction) {
      case DirectionStatus.closer:
        horizontalOffset = 50 * _arrowController.value; // Moving closer, horizontal
        verticalOffset = 50 * _arrowController.value;   // Moving closer, vertical
        break;
      case DirectionStatus.farther:
        horizontalOffset =0.0; // Moving farther, horizontal
        verticalOffset = -100 * _arrowController.value;   // Moving farther, vertical
        break;
      case DirectionStatus.left:
        horizontalOffset = -100 * _arrowController.value; // Moving left, horizontal
        verticalOffset = 0.0; // No vertical movement
        break;
      case DirectionStatus.right:
        horizontalOffset = 100 * _arrowController.value; // Moving right, horizontal
        verticalOffset = 0.0; // No vertical movement
        break;
      case DirectionStatus.center:
      case DirectionStatus.unknown:
        horizontalOffset = 0.0; // No horizontal movement
        verticalOffset = 0.0;   // No vertical movement
        break;
    }
    return Offset(horizontalOffset, verticalOffset); // Return calculated offsets
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
            scale: 1 + 0.1 * _arrowController.value, // Scale animation
            child: Transform.rotate(
              angle: _rotationAngle, // Rotation animation based on direction
              child: Transform.translate(
                // Position translation based on direction
                offset: _calculateTranslation(direction), // Call the translation function here
                child: Icon(
                  Icons.arrow_upward,
                  size: 60,
                  color: Colors.red,
                ),
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


