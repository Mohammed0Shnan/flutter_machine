import 'dart:io';
import 'dart:ui';
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

enum DirectionStatus { left, right, center, unknown, up, down }

class ObjectDetectionState {
  final ObjectDetectionStatus status;
  final String? objectName;
  final String? message;
  final DirectionStatus? direction;
  final CameraController? controller;
  final Rect? boundingBox;

  ObjectDetectionState({
    required this.status,
    this.objectName,
    this.message,
    this.direction,
    this.controller,
    this.boundingBox,
  });

  ObjectDetectionState copyWith({
    ObjectDetectionStatus? status,
    String? objectName,
    String? message,
    DirectionStatus? direction,
    CameraController? controller,
    Rect? boundingBox,
  }) {
    return ObjectDetectionState(
      status: status ?? this.status,
      objectName: objectName ?? this.objectName,
      message: message ?? this.message,
      direction: direction ?? this.direction,
      controller: controller ?? this.controller,
      boundingBox: boundingBox ?? this.boundingBox,
    );
  }
}

// ObjectDetectionCubit
class ObjectDetectionCubit extends Cubit<ObjectDetectionState>
    implements DetectionBaseBloc {
  final String flag = 'object_detection_cubit';
  final Mediator mediator;
  late Detector service;

  ObjectDetectionCubit({required this.mediator})
      : super(ObjectDetectionState(status: ObjectDetectionStatus.initial)) {
    mediator.registerBloc(this);
  }

  initService(Detector service) {
    this.service = service;
  }
  void setObjectName(String name)=>  emit(state.copyWith(
     objectName: name));
  // Handle object detection logic
  void detectObject({required Recognition recognition,required aspect,required double w,required double h}) async {

      DirectionStatus res =  service.calculateDirection(
        left: recognition.location.left,
        right: recognition.location.right,
        top: recognition.location.top,
        bottom: recognition.location.bottom,
        aspect: aspect,
        frameWidth: w,
        frameHeight: h,
      );

      if ( res == DirectionStatus.center) {
        emit(state.copyWith(
            status: ObjectDetectionStatus.inPosition,
            boundingBox: recognition.location,
            message: "Object in position",
            direction: res));
      }
      else{
        Map<String, dynamic> direction = {};
        if (res == DirectionStatus.left) {
          direction['message'] = "Move Left";
        } else if (res == DirectionStatus.right) {
          direction['message'] = "Move Right";
        } else if (res == DirectionStatus.up) {
          direction['message'] = "Move Up";
        } else if (res == DirectionStatus.down) {
          direction['message'] = "Move Down";
        } else if (res == DirectionStatus.center) {
          direction['message'] = "Close...";
        }
        else {
          direction['message'] = "Adjust Position";
        }
        direction['direction'] = res == DirectionStatus.center?DirectionStatus.unknown:res;
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
      objectName: objectName,
    ));
  }

  bool _isObjectInPosition(Recognition recognition) {
    return recognition.score > 0.8;
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
