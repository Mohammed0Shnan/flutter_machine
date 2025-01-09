import 'dart:io';
 import 'package:camera/camera.dart';
import 'package:f_m/module_detection/bloc/mediation_bloc.dart';
import 'package:f_m/module_detection/models/recognition.dart';
import 'package:f_m/module_detection/service/detector_service.dart';
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
  late Detector service;

  ObjectDetectionCubit({required this.mediator })
      : super(ObjectDetectionState(status: ObjectDetectionStatus.initial)) {
    mediator.registerBloc(this);
  }

  initService(Detector service){
    this.service = service;
  }

  // Handle object detection logic
  void detectObject(Recognition recognition) {
    if (_isObjectInPosition(recognition)) {
      emit(state.copyWith(
          status: ObjectDetectionStatus.inPosition,
          message: "Object in position!"));
    } else {
      Map<String, dynamic> direction = service.calculateDirection(recognition);
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
