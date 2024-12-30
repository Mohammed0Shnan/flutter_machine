import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/recognition.dart';
import 'camera_cubit.dart';  // Add the import for CameraCubit

enum ObjectDetectionStatus {
  initial,
  detecting,
  inPosition,
  notInPosition,
  imageCaptured,
}

class ObjectDetectionState {
  final ObjectDetectionStatus status;
  final String? objectName;
  final String? message;
  final String? direction;
  final CameraController? controller;
  final File? capturedImage;

  ObjectDetectionState({
    required this.status,
    this.objectName,
    this.message,
    this.direction,
    this.controller,
    this.capturedImage,
  });

  ObjectDetectionState copyWith({
    ObjectDetectionStatus? status,
    String? objectName,
    String? message,
    String? direction,
    CameraController? controller,
    File? capturedImage,
  }) {
    return ObjectDetectionState(
      status: status ?? this.status,
      objectName: objectName ?? this.objectName,
      message: message ?? this.message,
      direction: direction ?? this.direction,
      controller: controller ?? this.controller,
      capturedImage: capturedImage ?? this.capturedImage,
    );
  }
}

// ObjectDetectionCubit
class ObjectDetectionCubit extends Cubit<ObjectDetectionState> {
  final CameraCubit cameraCubit;

  ObjectDetectionCubit({required this.cameraCubit})
      : super(ObjectDetectionState(status: ObjectDetectionStatus.initial)) {
    // Listen to camera state updates
    cameraCubit.stream.listen((cameraState) {
      if (cameraState.state == CameraStateEnum.initialized) {
        emit(state.copyWith(
          controller: cameraState.controller,
        ));
      } else if (cameraState.state == CameraStateEnum.error) {
        emit(state.copyWith(
          controller: null,
        ));
      }
    });
  }

  // Handle object detection logic
  void detectObject(Recognition recognition) {
    if (_isObjectInPosition(recognition)) {
      emit(state.copyWith(
        status: ObjectDetectionStatus.inPosition,
      ));
    } else {
      print('000000000000000000000000000000000000000');
      print(recognition);
      String direction = _getDirection(recognition);
      emit(state.copyWith(
        status: ObjectDetectionStatus.notInPosition,
        message: "Move closer or farther",
        direction: direction,
      ));
    }
  }

  void objectNotDetected() {
    emit(state.copyWith(
      status: ObjectDetectionStatus.detecting,
      objectName: "Detecting object...",
    ));
  }

  Future<void> captureImage() async {
    final capturedImage = await _captureImage();
    emit(state.copyWith(
      status: ObjectDetectionStatus.imageCaptured,
      capturedImage: capturedImage,
    ));
  }

  bool _isObjectInPosition(Recognition recognition) {
    return recognition.score > 0.5;  // The object is considered in position if the recognition score is greater than 0.5
  }

  String _getDirection(Recognition recognition) {
    if (recognition.score < 0.3) {
      return "closer";  // The object is too far away, ask the user to move closer
    } else if (recognition.score > 0.7) {
      return "farther";  // The object is too close, ask the user to move farther
    } else {
      return "center";  // The object is in an ideal position (centered)
    }
  }

  Future<File> _captureImage() async {
    // Simulating an image capture process
    return File('path_to_image');  // Replace with actual image capture logic
  }
}
