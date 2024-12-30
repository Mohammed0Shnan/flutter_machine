import 'dart:async';
import 'dart:isolate';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:f_m/models/recognition.dart';
import 'package:f_m/service/detector_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../main.dart';
import '../models/screen_params.dart';
import '../state_managment/object_detect_state_managment.dart';
import 'box_widget.dart';
import 'guidance_widget.dart';

class DetectorWidget extends StatefulWidget {
  final String selectedObject;
  const DetectorWidget({Key? key, required this.selectedObject}) : super(key: key);

  @override
  _DetectorWidgetState createState() => _DetectorWidgetState();
}

class _DetectorWidgetState extends State<DetectorWidget> {
  late List<CameraDescription> cameras;
  CameraController? _cameraController;
  Detector? _detector;
  StreamSubscription? _subscription;
  List<Recognition>? results;
  Map<String, String>? stats;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeObjectDetector();
  }

  void _initializeCamera() async {
    cameras = await availableCameras();
    final frontCameraIndex = cameras.indexWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
    );

    if (frontCameraIndex == -1) {
      print("No front camera found!");
      return;
    }

    _cameraController = CameraController(
      cameras[frontCameraIndex],
      ResolutionPreset.low,
      enableAudio: false,
    )..initialize().then((_) async {
      // Set preview size when the camera is initialized
      ScreenParams.previewSize = Size(
        _cameraController!.value.previewSize!.width,
        _cameraController!.value.previewSize!.height,
      );

      await _cameraController!.startImageStream(_processCameraImage);
      setState(() {});
    });
  }

  void _initializeObjectDetector() async {
    _detector = await Detector.start();
    _subscription = _detector?.resultsStream.stream.listen((values) {
      setState(() {
        results = values['recognitions'];
        stats = values['stats'];
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Check if the camera controller is properly initialized
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const SizedBox.shrink(); // Return empty widget if camera isn't ready
    }

    // Calculate aspect ratio for the camera feed
    var aspect = 1 / _cameraController!.value.aspectRatio;

    return BlocListener<ObjectDetectionCubit, ObjectDetectionState>(
      bloc: detectBloc, // Your ObjectDetectionCubit instance
      listener: (context, state) {
        // You can handle any side effects here if necessary
        // For example, update UI when an object is detected or when guidance messages change
        if (state is ObjectInPosition) {
          // Handle logic when object is detected in the right position
        } else if (state is ObjectNotInPosition) {
          // Handle logic when the object is not in the right position
        } else if (state is ObjectDetecting) {
          // Handle logic when detection is in progress
        }
      },
      child: Stack(
        children: [
          // Camera Preview: Display the live camera feed
          AspectRatio(
            aspectRatio: aspect, // Ensure the camera feed maintains the right aspect ratio
            child: CameraPreview(_cameraController!), // Show the live preview from camera controller
          ),

          // Bounding Boxes: Overlay bounding boxes on top of the camera feed
          AspectRatio(
            aspectRatio: aspect,
            child: _buildBoundingBoxes(context), // This function can draw boxes over detected objects
          ),

          // Optional: Guidance Widget for real-time feedback (e.g., "Move closer", "Object in position")
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: GuidanceWidget(), // This widget provides user guidance during detection
          ),
        ],
      ),
    );
  }

  Widget _buildBoundingBoxes(BuildContext context) {
    if (results == null) return const SizedBox.shrink();

    final filteredResults = results!.where((box) => box.label == widget.selectedObject).toList();

    final cubit = detectBloc;
    if (filteredResults.isNotEmpty) {
      cubit.detectObject(filteredResults.first);
    } else {
      cubit.objectNotDetected();
    }

    return Stack(
      children: filteredResults.map((box) => BoxWidget(result: box)).toList(),
    );
  }

  void _processCameraImage(CameraImage cameraImage) {
    _detector?.processFrame(cameraImage);
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _detector?.stop();
    _subscription?.cancel();
    super.dispose();
  }
}
