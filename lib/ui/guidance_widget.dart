import 'dart:io';
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
  late Animation<Offset> _arrowAnimation;
  String _guidanceMessage = "Detecting object...";

  @override
  void initState() {
    super.initState();
    _arrowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _arrowAnimation = Tween<Offset>(begin: Offset.zero, end: Offset.zero).animate(
      CurvedAnimation(parent: _arrowController, curve: Curves.easeInOut),
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
                _guidanceMessage = "Detecting ${state.objectName}...";
              } else if (state.status == ObjectDetectionStatus.notInPosition) {
                _guidanceMessage = state.message ?? "Adjust position...";
                _updateArrowDirection(state.direction ?? "center");
              } else if (state.status == ObjectDetectionStatus.inPosition) {
                _guidanceMessage = "Object in position!";
                _updateArrowDirection("center");
                // _captureImage(state.controller!);
              }

              return SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }


  void _updateArrowDirection(String direction) {
    Offset begin = Offset.zero;
    Offset end = Offset.zero;

    if (direction == "closer") {
      begin = Offset(0, -0.5);
      end = Offset(0, -0.5);
    } else if (direction == "farther") {
      begin = Offset(0, 0.5);
      end = Offset(0, 0.5);
    }


    _arrowAnimation = Tween<Offset>(begin: begin, end: end).animate(
      CurvedAnimation(parent: _arrowController, curve: Curves.easeInOut),
    );
    _arrowController.repeat();

  }

  Future<void> _captureImage(CameraController controller) async {
    try {
      final image = await controller.takePicture();
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _arrowAnimation,
          builder: (context, child) {
            return SlideTransition(
              position: _arrowAnimation,
              child: Icon(Icons.arrow_upward, size: 60, color: Colors.red),
            );
          },
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


