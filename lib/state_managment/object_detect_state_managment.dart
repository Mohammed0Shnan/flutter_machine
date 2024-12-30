import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/recognition.dart';
import 'camera_cubit.dart';  // Add the import for CameraCubit

// Object Detection States
abstract class ObjectDetectionState {}

class ObjectDetectionInitial extends ObjectDetectionState {}

class ObjectDetecting extends ObjectDetectionState {
  final String objectName;
  ObjectDetecting(this.objectName);
}

class ObjectInPosition extends ObjectDetectionState {}

class ObjectNotInPosition extends ObjectDetectionState {
  final String message;
  final String direction;  // Added direction property
  ObjectNotInPosition(this.message, this.direction);  // Constructor now accepts direction
}

class ImageCaptured extends ObjectDetectionState {
  final File capturedImage;
  ImageCaptured(this.capturedImage);
}

// ObjectDetectionCubit
class ObjectDetectionCubit extends Cubit<ObjectDetectionState> {
  final CameraCubit cameraCubit;

  ObjectDetectionCubit({required this.cameraCubit}) : super(ObjectDetectionInitial()) {
    // Listen to camera state updates
    cameraCubit.stream.listen((cameraState) {
      if (cameraState.state == CameraStateEnum.initialized) {
        emit(ObjectDetecting("Initializing object detection..."));
      } else if (cameraState.state == CameraStateEnum.error) {
        emit(ObjectDetectionInitial());  // Reset state on error
      }
    });
  }

  // Handle object detection logic
  void detectObject(Recognition recognition) {
    if (_isObjectInPosition(recognition)) {
      emit(ObjectInPosition());  // Object is in position
    } else {
      String direction = _getDirection(recognition);
      emit(ObjectNotInPosition("Move closer or farther", direction));  // Object not in position
    }
  }

  // When no object is detected
  void objectNotDetected() {
    emit(ObjectDetecting("Detecting object..."));
  }

  // Capture image
  Future<void> captureImage() async {
    final capturedImage = await _captureImage();
    emit(ImageCaptured(capturedImage));
  }

  // Helper method to check if object is in position
  bool _isObjectInPosition(Recognition recognition) {
    return recognition.score > 0.5;  // The object is considered in position if the recognition score is greater than 0.5
  }

  // Determine direction for guidance
  String _getDirection(Recognition recognition) {
    if (recognition.score < 0.3) {
      return "closer";  // The object is too far away, ask the user to move closer
    } else if (recognition.score > 0.7) {
      return "farther";  // The object is too close, ask the user to move farther
    } else {
      return "center";  // The object is in an ideal position (centered)
    }
  }

  // Simulate image capture process
  Future<File> _captureImage() async {
    // Simulating an image capture process
    return File('path_to_image');  // Replace with actual image capture logic
  }
}
