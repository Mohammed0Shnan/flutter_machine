import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'mediation_bloc.dart';

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

class CameraCubit extends Cubit<CameraState> implements DetectionBaseBloc {
  final String flag = 'camera_cubit';
  final Mediator mediator;

  CameraCubit({required this.mediator})
      : super(CameraState(state: CameraStateEnum.initial)) {
    mediator.registerBloc(this);
  }

  Future<void> initializeCamera(CameraController? controller) async {
    emit(state.copyWith(state: CameraStateEnum.loading));
    mediator.notify('loading', {}, this);
    if (controller == null) {
      emit(state.copyWith(
          state: CameraStateEnum.error, errorMessage: "No cameras available"));
      mediator.notify('error', {'data': state.errorMessage}, this);
    } else {
      emit(state.copyWith(
          state: CameraStateEnum.initialized, controller: controller));
      mediator.notify('initialized', {'data': state.controller}, this);
    }
  }

  @override
  String getFlag() => flag;

  @override
  void handleEvent(String event, Object? data) {
  }
}
