import 'dart:async';

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
  final ObjectDetectionCubit detectionBloc;
  final CameraCubit cameraBloc;

  const DetectorScreen(
      {super.key, required this.detectionBloc, required this.cameraBloc});

  @override
  State<DetectorScreen> createState() => _DetectorScreenState();
}

class _DetectorScreenState extends State<DetectorScreen>
    with WidgetsBindingObserver {
  late String selectedObject;

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initStateAsync();
  }

  void _initStateAsync() async {
    _initializeCamera();

    int lastFrameTime = 0;
    const int frameIntervalMs = 100;
    Detector.start().then((instance) {
      setState(() {
        _detector = instance;
        widget.detectionBloc.initService(instance);
        _subscription = instance.resultsStream.stream.listen((values) {
          final currentTime = DateTime.now().millisecondsSinceEpoch;
          if (currentTime - lastFrameTime < frameIntervalMs) {
            return;
          }
          lastFrameTime = currentTime;
          if (values['recognitions'] != results || values['stats'] != stats) {
            setState(() {
              results = values['recognitions'];
              stats = values['stats'];
            });
          }
        });
      });
    });
  }

  void _initializeCamera() async {
    cameras = await availableCameras();
    // cameras[0] for back-camera
    _cameraController = CameraController(
      cameras[0],
      ResolutionPreset.low,
      enableAudio: false,
    )..initialize().then((_) async {
        widget.cameraBloc.initializeCamera(_cameraController);
        await _cameraController!.startImageStream(onLatestImageAvailable);
        ScreenParams.previewSize = _cameraController!.value.previewSize!;
        setState(() {});
      });
  }

  // void _initializeCamera() async {
  //   cameras = await availableCameras();
  //   final frontCameraIndex = cameras.indexWhere(
  //         (camera) => camera.lensDirection == CameraLensDirection.front,
  //   );
  //
  //   if (frontCameraIndex == -1) {
  //     print("No front camera found!");
  //     return;
  //   }
  //
  //   // Use the front camera
  //   _cameraController = CameraController(
  //     cameras[frontCameraIndex],
  //     ResolutionPreset.low,
  //     enableAudio: false,
  //   )..initialize().then((_) async {
  //     widget.cameraBloc.initializeCamera(_cameraController);
  //     await _cameraController!.startImageStream(onLatestImageAvailable);
  //     ScreenParams.previewSize = _cameraController!.value.previewSize!;
  //     setState(() {});
  //   }
  //   );
  // }
  @override
  Widget build(BuildContext context) {
    selectedObject = ModalRoute.of(context)!.settings.arguments as String;

    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const SizedBox.shrink();
    }

    var aspect = .9 / _cameraController!.value.aspectRatio;

    return MultiBlocProvider(
      providers: [
        BlocProvider<ObjectDetectionCubit>(create: (_) => widget.detectionBloc),
        BlocProvider<CameraCubit>(create: (_) => widget.cameraBloc),
      ],
      child: Scaffold(
        body: SizedBox(
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
                child: _buildBoundingBoxes(context,aspect),
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
                child: _statsWidget(aspect),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statsWidget(double aspect) => (stats != null)
      ? AspectRatio(
          aspectRatio:aspect *.1 ,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: stats!.entries
                    .map((e) => SizedBox(
                          height: 40,
                          width: double.infinity,
                          child: Row(
                            children: [
                              Text(
                                "${e.key}  ",
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700),
                              ),
                              Text(
                                e.value,
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.red),
                              )
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
        )
      : const SizedBox.shrink();

  /// Returns Stack of bounding boxes
  Widget _buildBoundingBoxes(
    BuildContext context,
      double aspect
  ) {
    if (results == null || _cameraController == null) {
      return const SizedBox.shrink();
    }
    final filteredResults =
        results!.where((box) => box.label.trim() == selectedObject).toList();
    if (filteredResults.isNotEmpty) {
      widget.detectionBloc.detectObject(
        recognition:
          filteredResults.first,
          aspect: aspect,
          h: ScreenParams.screenPreviewSize.height,
          w:  ScreenParams.screenPreviewSize.width

         );
    } else {
      widget.detectionBloc.objectNotDetected(selectedObject);
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
    widget.cameraBloc.initializeCamera(null);
    _cameraController?.dispose();
    _detector?.stop();
    _subscription?.cancel();
    super.dispose();
  }
}
