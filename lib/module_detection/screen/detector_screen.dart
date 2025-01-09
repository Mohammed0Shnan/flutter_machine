
import 'dart:async';
import 'dart:isolate';

import 'package:camera/camera.dart';
import 'package:f_m/module_detection/bloc/camera_cubit.dart';
import 'package:f_m/module_detection/service/detector_service.dart';
import 'package:f_m/module_detection/widgets/guidance_widget.dart';
import 'package:flutter/material.dart';
import 'package:f_m/module_detection/models/recognition.dart';
import 'package:f_m/module_detection/models/screen_params.dart';
import 'package:f_m/module_detection/widgets/box_widget.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/object_detect_bloc.dart';

/// [DetectorWidget] sends each frame for inference
class DetectorScreen extends StatefulWidget {
  final String selectedObject;

  const DetectorScreen({super.key, required this.selectedObject});

  @override
  State<DetectorScreen> createState() => _DetectorScreenState();
}

class _DetectorScreenState extends State<DetectorScreen>
    with WidgetsBindingObserver {
  /// List of available cameras
  late List<CameraDescription> cameras;

  /// Controller
  CameraController? _cameraController;

  // use only when initialized, so - not null

  /// Object Detector is running on a background [Isolate]. This is nullable
  /// because acquiring a [Detector] is an asynchronous operation. This
  /// value is `null` until the detector is initialized.
  Detector? _detector;
  StreamSubscription? _subscription;

  /// Results to draw bounding boxes
  List<Recognition>? results;

  /// Realtime stats
  Map<String, String>? stats;
  late ObjectDetectionCubit  detectBloc;
  late CameraCubit  cameraBloc;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((c){
      if(mounted){
        detectBloc =  context.read<ObjectDetectionCubit>();
        cameraBloc =  context.read<CameraCubit>();
        _initStateAsync();
      }
    });

  }

  void _initStateAsync() async {
    _initializeCamera();
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
  // void _initializeCamera() async {
  //   cameras = await availableCameras();
  //   // cameras[0] for back-camera
  //   _cameraController = CameraController(
  //     cameras[0],
  //     ResolutionPreset.low,
  //     enableAudio: false,
  //   )..initialize().then((_) async {
  //         detectBloc.cameraCubit.initializeCamera(_cameraController);
  //         await _cameraController!.startImageStream(onLatestImageAvailable);
  //         ScreenParams.previewSize = _cameraController!.value.previewSize!;
  //         setState(() {});
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
      cameraBloc.initializeCamera(_cameraController);
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
  Widget _buildBoundingBoxes(BuildContext context ,) {
    if (results == null) return const SizedBox.shrink();
    final filteredResults = results!.where((box) => box.label.trim() == 'mouse').toList();
    if (filteredResults.isNotEmpty) {
      detectBloc.detectObject(filteredResults.first);
    } else {
      detectBloc.objectNotDetected(widget.selectedObject);
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
    cameraBloc.initializeCamera(null);
    _cameraController?.dispose();
    _detector?.stop();
    _subscription?.cancel();
    super.dispose();
  }
}