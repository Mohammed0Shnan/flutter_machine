import 'dart:io';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:f_m/module_detection/bloc/mediation_bloc.dart';
import 'package:f_m/module_detection/models/recognition.dart';
import 'package:f_m/module_detection/models/screen_params.dart';
import 'package:f_m/module_detection/bloc/camera_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum ObjectDetectionStatus {
  initial,
  detecting,
  inPosition,
  notInPosition,
  imageCaptured,
}

enum DirectionStatus { left, right, closer, farther, center, unknown }

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
class ObjectDetectionCubit extends Cubit<ObjectDetectionState>
    implements DetectionBaseBloc {
  final String flag = 'object_detection_cubit';
  final Mediator mediator;

  ObjectDetectionCubit({required this.mediator})
      : super(ObjectDetectionState(status: ObjectDetectionStatus.initial)) {
    mediator.registerBloc(this);
  }

  // Handle object detection logic
  void detectObject(Recognition recognition) {
    if (_isObjectInPosition(recognition)) {
      emit(state.copyWith(
          status: ObjectDetectionStatus.inPosition,
          message: "Object in position!"));
    } else {
      Map<String, dynamic> direction = _getDirection(recognition);
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

  // Map<String,dynamic> _getDirection(Recognition recognition) {
  //   // Access the bounding box (location)
  //   final Rect location = recognition.location;
  //
  //   // Get the object's center x-coordinate
  //   final double objectCenterX = location.left + (location.width / 2);
  //
  //   // Define frame width based on ScreenParams
  //   final double frameWidth = ScreenParams.screenPreviewSize.width;
  //
  //   // Define thresholds for regions
  //   const double leftThresholdFactor = 0.33;
  //   const double rightThresholdFactor = 0.66;
  //
  //   final double leftThreshold = frameWidth * leftThresholdFactor;
  //   final double rightThreshold = frameWidth * rightThresholdFactor;
  //   print('===================> ${leftThreshold} <=======================');
  //   print('===================> ${rightThreshold} <=======================');
  //   print('===================> ${rightThreshold} <=======================');
  //   if (recognition.score > 0.8) {
  //     return {'message':'Move farther','direction':DirectionStatus.farther };
  //   }
  //  else if (recognition.score < 0.8 && recognition.score > 0.66 ) {
  //     return {'message':'Move closer','direction':DirectionStatus.closer };
  //   }
  //  else if (objectCenterX > leftThreshold) {
  //     return {'message':'Move right','direction':DirectionStatus.right };
  //   } else if (objectCenterX < rightThreshold) {
  //     return {'message':'Move left','direction':DirectionStatus.left };
  //   }
  //
  //   return {'message':'Move center','direction':DirectionStatus.center };
  //
  // }
  //
  // Map<String, dynamic> _getDirection(Recognition recognition) {
  //   // Access the bounding box (location)
  //   final Rect location = recognition.location;
  //
  //   // Get the object's center x-coordinate
  //   final double objectCenterX = location.left + (location.width / 2);
  //
  //   // Define frame width based on ScreenParams
  //   final double frameWidth = ScreenParams.screenPreviewSize.width;
  //
  //   // Define thresholds for regions
  //   const double leftThresholdFactor = 0.33;
  //   const double rightThresholdFactor = 0.66;
  //
  //   final double leftThreshold = frameWidth * leftThresholdFactor;
  //   final double rightThreshold = frameWidth * rightThresholdFactor;
  //
  //   // Define a center tolerance (range considered "center")
  //   const double centerToleranceFactor = 0.1;
  //   final double centerLeft = frameWidth * (0.5 - centerToleranceFactor);
  //   final double centerRight = frameWidth * (0.5 + centerToleranceFactor);
  //
  //   // Include distance-related logic using bounding box size
  //   const double fartherThreshold = 0.1; // Smaller objects are farther away
  //   const double closerThreshold = 0.3; // Larger objects are closer
  //
  //   final double objectSizeFactor = location.width / frameWidth;
  //
  //   if (recognition.score > 0.8 && objectSizeFactor < fartherThreshold) {
  //     return {'message': 'Move farther', 'direction': DirectionStatus.farther};
  //   } else if (recognition.score > 0.66 && objectSizeFactor > closerThreshold) {
  //     return {'message': 'Move closer', 'direction': DirectionStatus.closer};
  //   } else if (objectCenterX >= centerLeft && objectCenterX <= centerRight) {
  //     return {'message': 'Object is centered', 'direction': DirectionStatus.center};
  //   } else if (objectCenterX < leftThreshold) {
  //     return {'message': 'Move left', 'direction': DirectionStatus.left};
  //   } else if (objectCenterX > rightThreshold) {
  //     return {'message': 'Move right', 'direction': DirectionStatus.right};
  //   }
  //
  //   return {'message': 'Adjust position', 'direction': DirectionStatus.unknown};
  // }

  Map<String, dynamic> _getDirection(Recognition recognition) {
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

    // Define a center tolerance (range considered "center")
    const double centerToleranceFactor = 0.1;
    final double centerLeft = frameWidth * (0.5 - centerToleranceFactor);
    final double centerRight = frameWidth * (0.5 + centerToleranceFactor);

    // Include distance-related logic using bounding box size
    const double fartherThreshold = 0.1; // Smaller objects are farther away
    const double closerThreshold = 0.3; // Larger objects are closer

    final double objectSizeFactor = location.width / frameWidth;

    // Check if the object is within the center tolerance first
    if (objectCenterX >= centerLeft && objectCenterX <= centerRight) {
      if (recognition.score > 0.8 && objectSizeFactor < fartherThreshold) {
        return {
          'message': 'Move farther',
          'direction': DirectionStatus.farther
        };
      } else if (recognition.score > 0.66 &&
          objectSizeFactor > closerThreshold) {
        return {'message': 'Move closer', 'direction': DirectionStatus.closer};
      } else {
        return {
          'message': 'Object is centered',
          'direction': DirectionStatus.center
        };
      }
    }

    // If not centered, determine other directions
    if (objectCenterX < leftThreshold) {
      return {'message': 'Move left', 'direction': DirectionStatus.left};
    } else if (objectCenterX > rightThreshold) {
      return {'message': 'Move right', 'direction': DirectionStatus.right};
    }

    // Default fallback
    return {'message': 'Adjust position', 'direction': DirectionStatus.unknown};
  }

  @override
  String getFlag() => flag;

  @override
  void handleEvent(String event, Object? data) {
    if (event == 'initialized') {
      emit(state.copyWith(
        controller: (data! as Map)['data'],
      ));
    } else if (event == 'error') {
      emit(state.copyWith(
        controller: null,
      ));
    }
  }
}
