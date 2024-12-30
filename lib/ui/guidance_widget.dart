import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart'; // Add the camera package import

import '../main.dart';
import '../state_managment/object_detect_state_managment.dart';
import 'capture_display_screen.dart';

class GuidanceWidget extends StatefulWidget {
  const GuidanceWidget({Key? key}) : super(key: key);

  @override
  _GuidanceWidgetState createState() => _GuidanceWidgetState();
}

class _GuidanceWidgetState extends State<GuidanceWidget> with TickerProviderStateMixin {
  late AnimationController _arrowController;
  late Animation<Offset> _arrowAnimation;
  String _guidanceMessage = "Detecting object...";
  CameraController? _cameraController;  // Make it nullable
  List<CameraDescription>? _cameras;  // To store available cameras

  @override
  void initState() {
    super.initState();
    _initializeArrowAnimation();
    _initializeCamera();
  }

  // Initialize camera
  Future<void> _initializeCamera() async {
    // Get the list of available cameras
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _cameraController = CameraController(_cameras![0], ResolutionPreset.low);
      await _cameraController!.initialize();  // Initialize the camera
      setState(() {});  // Rebuild the widget after the camera is initialized
    } else {
      print("No cameras available.");
    }
  }

  void _initializeArrowAnimation() {
    _arrowController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _arrowAnimation = Tween<Offset>(begin: Offset(0, 0), end: Offset(0, 0)).animate(CurvedAnimation(parent: _arrowController, curve: Curves.easeInOut));
    _arrowController.repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());  // Show loading while the camera is initializing
    }

    return BlocBuilder<ObjectDetectionCubit, ObjectDetectionState>(
      bloc: detectBloc,
      builder: (context, state) {
        if (state is ObjectDetecting) {
          _guidanceMessage = "Detecting ${state.objectName}...";
        } else if (state is ObjectNotInPosition) {
          _guidanceMessage = state.message;
          _updateArrowDirection(state.direction);
        } else if (state is ObjectInPosition) {
          _guidanceMessage = "Object in position!";
          _updateArrowDirection("center");
          _captureImage(); // Trigger the image capture when the object is in position
        }

        return _buildGuidanceMessage(_guidanceMessage);
      },
    );
  }

  void _updateArrowDirection(String direction) {
    if (direction == "closer") {
      _arrowAnimation = Tween<Offset>(begin: Offset(0, -0.5), end: Offset(0, -0.5)).animate(CurvedAnimation(parent: _arrowController, curve: Curves.easeInOut));
    } else if (direction == "farther") {
      _arrowAnimation = Tween<Offset>(begin: Offset(0, 0.5), end: Offset(0, 0.5)).animate(CurvedAnimation(parent: _arrowController, curve: Curves.easeInOut));
    } else {
      _arrowAnimation = Tween<Offset>(begin: Offset(0, 0), end: Offset(0, 0)).animate(CurvedAnimation(parent: _arrowController, curve: Curves.easeInOut));
    }
    _arrowController.forward();
  }

  void _captureImage() async {
    if (_cameraController != null) {
      try {
        final image = await _cameraController!.takePicture();  // Capture image from camera controller
        if (image != null) {
          _navigateToCapturedImageScreen(image); // Navigate to the captured image screen
        }
      } catch (e) {
        print("Error capturing image: $e");
      }
    }
  }

  void _navigateToCapturedImageScreen(XFile image) {
    final file = File(image.path);
    final objectType = "Object Type"; // Replace with actual object type
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
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _arrowController,
          builder: (context, child) {
            return SlideTransition(position: _arrowAnimation, child: Icon(Icons.arrow_upward, size: 60, color: Colors.red));
          },
        ),
        Positioned(
          bottom: 50,
          child: FadeTransition(
            opacity: _arrowController,
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _arrowController.dispose();
    super.dispose();
  }
}
