import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/recognition.dart';
enum CameraStateEnum {
  initial,
  loading,
  initialized,
  error,
}
// Camera States
class CameraState {
  final CameraStateEnum state;
  final CameraController? controller;
  final String? errorMessage;

  CameraState({required this.state, this.controller, this.errorMessage});
}

// CameraCubit
class CameraCubit extends Cubit<CameraState> {
  CameraCubit() : super(CameraState(state: CameraStateEnum.initial));

  Future<void> initializeCamera() async {
    emit(CameraState(state: CameraStateEnum.loading));

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        emit(CameraState(state: CameraStateEnum.error, errorMessage: "No cameras available"));
        return;
      }

      final controller = CameraController(cameras[0], ResolutionPreset.high);
      await controller.initialize();

      emit(CameraState(state: CameraStateEnum.initialized, controller: controller));
    } catch (e) {
      emit(CameraState(state: CameraStateEnum.error, errorMessage: "Failed to initialize camera: $e"));
    }
  }
}
