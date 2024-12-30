
import 'dart:async';
import 'dart:isolate';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:f_m/models/recognition.dart';
import 'package:f_m/models/screen_params.dart';
import 'package:f_m/service/detector_service.dart';
import 'package:f_m/ui/box_widget.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../main.dart';
import '../state_managment/object_detect_state_managment.dart';
import 'guidance_widget.dart';

/// [DetectorWidget] sends each frame for inference
class DetectorWidget extends StatefulWidget {
  final String selectedObject;

  const DetectorWidget({super.key, required this.selectedObject});

  @override
  State<DetectorWidget> createState() => _DetectorWidgetState();
}

class _DetectorWidgetState extends State<DetectorWidget>
    with WidgetsBindingObserver {
  /// List of available cameras
  late List<CameraDescription> cameras;

  /// Controller
  CameraController? _cameraController;

  // use only when initialized, so - not null
  get _controller => _cameraController;

  /// Object Detector is running on a background [Isolate]. This is nullable
  /// because acquiring a [Detector] is an asynchronous operation. This
  /// value is `null` until the detector is initialized.
  Detector? _detector;
  StreamSubscription? _subscription;

  /// Results to draw bounding boxes
  List<Recognition>? results;

  /// Realtime stats
  Map<String, String>? stats;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initStateAsync();
  }

  void _initStateAsync() async {
    // initialize preview and CameraImage stream
    _initializeCamera();
    // Spawn a new isolate
    Detector.start().then((instance) {
      setState(() {
        _detector = instance;
        _subscription = instance.resultsStream.stream.listen((values) {
          setState(() {
            results = values['recognitions'];
            stats = values['stats'];
          });
        });
      });
    });
  }

  /// Initializes the camera by setting [_cameraController]
  // void _initializeCamera() async {
  //   cameras = await availableCameras();
  //   // cameras[0] for back-camera
  //   _cameraController = CameraController(
  //     cameras[0],
  //     ResolutionPreset.low,
  //     enableAudio: false,
  //   )..initialize().then((_) async {
  //       await _controller.startImageStream(onLatestImageAvailable);
  //       setState(() {});
  //
  //       /// previewSize is size of each image frame captured by controller
  //       ///
  //       /// 352x288 on iOS, 240p (320x240) on Android with ResolutionPreset.low
  //       ScreenParams.previewSize = _controller.value.previewSize!;
  //     });
  // }
  void _initializeCamera() async {
    cameras = await availableCameras();
    final frontCameraIndex = cameras.indexWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
    );

    if (frontCameraIndex == -1) {
      print("No front camera found!");
      return;
    }

    // Use the front camera
    _cameraController = CameraController(
      cameras[frontCameraIndex],
      ResolutionPreset.low,
      enableAudio: false,
    )..initialize().then((_) async {
      detectBloc.cameraCubit.initializeCamera(_cameraController);
      await _cameraController!.startImageStream(onLatestImageAvailable);
      ScreenParams.previewSize = _cameraController!.value.previewSize!;
      setState(() {});
    }

    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const SizedBox.shrink();
    }

    // Calculate aspect ratio for the camera feed
    var aspect = 1 / _cameraController!.value.aspectRatio;

    return SizedBox(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox.expand(),
          AspectRatio(
            aspectRatio: aspect,
            child: CameraPreview(_cameraController!),
          ),
          // _statsWidget(),
          AspectRatio(
            aspectRatio: aspect,
            child: _buildBoundingBoxes(context),
          ),

          Positioned(
            bottom: 350,
            left: 0,
            right: 0,
            child: GuidanceWidget(),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _statsWidget(),
          ),
        ],
      ),
    );
  }


  Widget _statsWidget() => (stats != null)
      ? Align(
    alignment: Alignment.bottomCenter,
    child: Container(
      color: Colors.white.withAlpha(150),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: stats!.entries
              .map((e) => SizedBox(height: 40,width:double.infinity, child: Row(children: [Text("${e.key}  ",style: TextStyle(fontSize: 20,fontWeight: FontWeight.w700),) ,Text(e.value,style: TextStyle(fontSize: 20,fontWeight: FontWeight.w700 ,color: Colors.red),)],),))
      .toList(),
  ),
      ),
    ),
  )
      : const SizedBox.shrink();

  /// Returns Stack of bounding boxes
  Widget _buildBoundingBoxes(BuildContext context) {
    if (results == null) return const SizedBox.shrink();
    print(results);
    final filteredResults = results!.where((box) => box.label == 'mouse').toList();
    if (filteredResults.isNotEmpty) {
      detectBloc.detectObject(filteredResults.first);
    } else {
      detectBloc.objectNotDetected();
    }
    return Stack(
      children: filteredResults.map((box) => BoxWidget(result: box)).toList(),
    );
  }


  /// Callback to receive each frame [CameraImage] perform inference on it
  void onLatestImageAvailable(CameraImage cameraImage) async {
    _detector?.processFrame(cameraImage);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.inactive:
        _cameraController?.stopImageStream();
        _detector?.stop();
        _subscription?.cancel();
        break;
      case AppLifecycleState.resumed:
        _initStateAsync();
        break;
      default:
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    detectBloc.cameraCubit.initializeCamera(null);
    _cameraController?.dispose();
    _detector?.stop();
    _subscription?.cancel();
    super.dispose();
  }
}