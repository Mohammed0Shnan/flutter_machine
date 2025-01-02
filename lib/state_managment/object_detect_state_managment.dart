import 'dart:io';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:f_m/models/screen_params.dart';
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
enum DirectionStatus {
  left,
  right,
  closer,
  farther,
  center,
}

class ObjectDetectionState {
  final ObjectDetectionStatus status;
  final String? objectName;
  final String? message;
  final DirectionStatus? direction;
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
    DirectionStatus? direction,
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
        message: "Object in position!"
      ));
    } else {
      Map<String , dynamic> direction = _getDirection(recognition);
      emit(state.copyWith(
        status: ObjectDetectionStatus.notInPosition,
        message: direction['message'],
        direction: direction['direction'],
      ));
    }
  }

  void objectNotDetected(String objectName) {
    emit(state.copyWith(
      status: ObjectDetectionStatus.detecting,
      objectName: "Detecting $objectName...",
    ));
  }


  bool _isObjectInPosition(Recognition recognition) {
    return recognition.score > 0.9;
  }

  Map<String,dynamic> _getDirection(Recognition recognition) {
    // Access the bounding box (location)
    final Rect location = recognition.location;

    // Get the object's center x-coordinate
    final double objectCenterX = location.left + (location.width / 2);

    // Define frame width based on ScreenParams
    final double frameWidth = ScreenParams.screenPreviewSize.width;

    // Define thresholds for regions
    const double leftThresholdFactor = 0.33;
    const double rightThresholdFactor = 0.66;

    final double leftThreshold = frameWidth * leftThresholdFactor;
    final double rightThreshold = frameWidth * rightThresholdFactor;
    print('===================> ${leftThreshold} <=======================');
    print('===================> ${rightThreshold} <=======================');

    if (objectCenterX < leftThreshold) {
      return {'message':'Move right','direction':DirectionStatus.right };
    } else if (objectCenterX > rightThreshold) {
      return {'message':'Move left','direction':DirectionStatus.left };
    }
    if (recognition.score < 0.6) {
      return {'message':'Move closer','direction':DirectionStatus.closer };
    } else if (recognition.score > 0.8) {
      return {'message':'Move farther','direction':DirectionStatus.farther };
    }
    return {'message':'Move center','direction':DirectionStatus.center };

  }



}
