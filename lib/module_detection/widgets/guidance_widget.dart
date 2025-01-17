import 'dart:async';
import 'dart:math';
import 'package:f_m/module_detection/bloc/object_detect_bloc.dart';
import 'package:f_m/module_detection/screen/capture_display_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GuidanceWidget extends StatefulWidget {
  const GuidanceWidget({super.key});

  @override
  State<GuidanceWidget> createState() => _GuidanceWidgetState();
}

class _GuidanceWidgetState extends State<GuidanceWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _arrowController;
  late double _rotationAngle;
  late DirectionStatus direction;
  late ObjectDetectionCubit detectBloc;
  String _guidanceMessage = "";
  Timer? _inPositionTimer;
  bool _isCapturingImage = false;
  int _countdownValue = 2;

  @override
  void initState() {
    super.initState();
    _rotationAngle = 0.0;
    direction = DirectionStatus.unknown;

    _arrowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ObjectDetectionCubit, ObjectDetectionState>(
      bloc: context.read<ObjectDetectionCubit>(),
      builder: (context, state) {
        if (state.controller == null) {
          return const CircularProgressIndicator();
        }

        if (state.status == ObjectDetectionStatus.detecting) {
          _guidanceMessage = state.objectName ?? '...';
        } else if (state.status == ObjectDetectionStatus.notInPosition) {
          _guidanceMessage = state.message ?? "Adjust position...";
          _updateArrowDirection(state.direction!);
        } else if (state.status == ObjectDetectionStatus.inPosition) {
          _guidanceMessage = state.message ?? '';
          _startInPositionTimer(state);
        }

        return state.direction != null
            ? _buildGuidanceMessage(_guidanceMessage)
            : SizedBox.shrink();
      },
    );
  }

  void _startInPositionTimer(ObjectDetectionState state) {

    if (_inPositionTimer?.isActive ?? false) {
      if(state.status != ObjectDetectionStatus.inPosition ){
        _cancelInPositionTimer();
        print('=======>>>>>>>>>>> status is changed');
      }
      return;
    }

    _inPositionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isCapturingImage) {
        timer.cancel();
        _cancelInPositionTimer();

        return;
      } else if (_countdownValue == 0) {
        _isCapturingImage = true;
        timer.cancel();
        print('=======>>>>>>>>>>> image capturing');
        // _captureImage(context,state);
      } else {
        _guidanceMessage = 'Capturing in';
        --_countdownValue;
      }
    });
  }

  void _cancelInPositionTimer() {
    _countdownValue = 2;
    _inPositionTimer?.cancel();
  }

  /// Captures the image and navigates to the next screen
  Future<void> _captureImage(context,ObjectDetectionState state) async {

    try {
      await state.controller?.pausePreview();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CapturedImageScreen(
            controller: state.controller!,
            boundingBox: state.boundingBox!,
            objectName: state.objectName ?? '',
          ),
        ),
      );
    } catch (e) {
      print("Error capturing image: $e");
    } finally {
      _isCapturingImage = false;
    }
  }

  void _updateArrowDirection(DirectionStatus newDirection) {
    double targetRotationAngle = 0.0;

    // Set rotation angle based on direction
    switch (newDirection) {
      case DirectionStatus.left:
        targetRotationAngle = -pi / 2;
        break;
      case DirectionStatus.right:
        targetRotationAngle = pi / 2;
        break;
      case DirectionStatus.up:
        targetRotationAngle = 0; // Arrow points up (rotating -90 degrees)
        break;
      case DirectionStatus.down:
        targetRotationAngle = -pi; // Arrow points down (rotating +90 degrees)
        break;
      case DirectionStatus.center:
      case DirectionStatus.unknown:
        targetRotationAngle = 0.0; // No rotation
        break;
    }

    // Update the rotation angle and direction
    _rotationAngle = targetRotationAngle;
    direction = newDirection;
  }

  Offset _calculateTranslation(DirectionStatus direction) {
    double horizontalOffset = 0.0;
    double verticalOffset = 0.0;

    switch (direction) {
      case DirectionStatus.left:
        horizontalOffset = -80;
        break;
      case DirectionStatus.right:
        horizontalOffset = 80;
        break;
      case DirectionStatus.up:
        verticalOffset = 80;
        break;
      case DirectionStatus.down:
        verticalOffset = -80;
        break;
      case DirectionStatus.center:
      case DirectionStatus.unknown:
        horizontalOffset = 0.0;
        verticalOffset = 0.0;
        break;
    }

    return Offset(horizontalOffset, verticalOffset);
  }

  Widget _buildGuidanceMessage(String message) {
    Offset offset = _calculateTranslation(direction);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 10),
        Text(
          message,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        AnimatedBuilder(
          animation: _arrowController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(
                offset.dx * _arrowController.value,
                offset.dy * _arrowController.value,
              ),
              child: Hero(
                tag: 'hero_camera_icon',
                child: direction == DirectionStatus.center
                    ? Column(
                        children: [
                          Row(
                            children: [
                              Text(message),
                              Text(_countdownValue.toString()),
                            ],
                          ),
                          Icon(
                            Icons.camera,
                            size: 60,
                            color: Colors.red,
                          ),
                        ],
                      )
                    : direction == DirectionStatus.unknown
                        ? SizedBox.shrink()
                        : Transform.rotate(
                            angle: _rotationAngle,
                            child: Icon(
                              Icons.arrow_upward,
                              size: 60,
                              color: Colors.red,
                            ),
                          ),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _arrowController.dispose();
    _cancelInPositionTimer();
    super.dispose();
  }
}
