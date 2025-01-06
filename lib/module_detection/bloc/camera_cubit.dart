import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/recognition.dart';

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

  CameraState({
    required this.state,
    this.controller,
    this.errorMessage,
  });

  // Implementing the copyWith method
  CameraState copyWith({
    CameraStateEnum? state,
    CameraController? controller,
    String? errorMessage,
  }) {
    return CameraState(
      state: state ?? this.state,
      controller: controller ?? this.controller,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
// CameraCubit
class CameraCubit extends Cubit<CameraState> {
  CameraCubit() : super(CameraState(state: CameraStateEnum.initial));

  Future<void> initializeCamera(CameraController? controller) async {
    emit(state.copyWith( state: CameraStateEnum.loading));
    if (controller == null) {
      emit(state.copyWith( state: CameraStateEnum.error, errorMessage: "No cameras available"));
    } else {

      emit(state.copyWith(  state: CameraStateEnum.initialized, controller: controller));
    }
  }
}
