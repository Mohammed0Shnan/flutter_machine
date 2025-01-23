import 'dart:async';

import 'package:camera/camera.dart';
import 'package:f_m/module_detection/bloc/camera_cubit.dart';
import 'package:f_m/module_detection/service/detector_service.dart';
import 'package:f_m/module_detection/widgets/custom_app_bar.dart';
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
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late String? selectedObject;
  late List<CameraDescription> cameras;
  CameraController? _cameraController;
  Detector? _detector;
  StreamSubscription? _subscription;
  List<Recognition>? results;
  Map<String, String>? stats;
  late bool _isFlashing;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _isFlashing = false;
    _initStateAsync();
  }

  void _triggerFlashEffect() {
    setState(() {
      _isFlashing = true;
    });

    Timer(const Duration(seconds: 1), () {
      setState(() {
        _isFlashing = false;
      });
    });
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
  //     (camera) => camera.lensDirection == CameraLensDirection.front,
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
  //       widget.cameraBloc.initializeCamera(_cameraController);
  //       await _cameraController!.startImageStream(onLatestImageAvailable);
  //       ScreenParams.previewSize = _cameraController!.value.previewSize!;
  //       setState(() {});
  //     });
  // }

  @override
  Widget build(BuildContext context) {
    selectedObject = ModalRoute.of(context)!.settings.arguments as String;
    if (selectedObject != null) {
      widget.detectionBloc.setObjectName(selectedObject!);
    }
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const SizedBox.shrink();
    }

    var aspect = .95 / _cameraController!.value.aspectRatio;

    return MultiBlocProvider(
      providers: [
        BlocProvider<ObjectDetectionCubit>.value(value: widget.detectionBloc),
        BlocProvider<CameraCubit>.value(value: widget.cameraBloc),
      ],
      child: BlocListener<ObjectDetectionCubit, ObjectDetectionState>(
        listener: (context, state) {
          if (state.status == ObjectDetectionStatus.imageCaptured) {
            _triggerFlashEffect();
          }
        },
        child: SafeArea(
          top: true,
          child: Scaffold(
            body: Stack(
              clipBehavior: Clip.none,
              children: [
                SizedBox.expand(),

                ///! Camera Preview
                AspectRatio(
                  aspectRatio: aspect,
                  child: CameraPreview(_cameraController!),
                ),

                ///! Bounding Box
                AspectRatio(
                  aspectRatio: aspect,
                  child: _buildBoundingBoxes(context, aspect),
                ),

                ///! App Bar
                Positioned(
                    top: 0,
                    left: 0,
                    child: CustomAppBar(title: 'Detection Screen ')),

                ///! Guidance And States
                Align(
                  alignment: Alignment.bottomCenter,
                  child: AspectRatio(
                    aspectRatio: aspect * 1.65,
                    child: Container(
                        padding: EdgeInsets.all(8.0),
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(30),
                                topRight: Radius.circular(30))),
                        child: Column(
                          children: [
                            Expanded(flex: 3, child: GuidanceWidget()),
                            Expanded(flex: 2, child: _statsWidget(aspect))
                          ],
                        )),
                  ),
                ),

                // Flash animation overlay
                if (_isFlashing) _FlashEffect(duration: 1,)
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statsWidget(double aspect) {
    final Size size = MediaQuery.of(context).size;
    return (stats != null)
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: stats!.entries
                .map((e) => Row(
                      children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              "${e.key}  ",
                              style: TextStyle(
                                  fontSize: .02 * size.height,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            e.value,
                            style: TextStyle(
                                fontSize: .02 * size.height,
                                fontWeight: FontWeight.w700,
                                color: Colors.red),
                          ),
                        )
                      ],
                    ))
                .toList(),
          )
        : const SizedBox.shrink();
  }

  Widget _buildBoundingBoxes(BuildContext context, double aspect) {
    if (results == null || _cameraController == null) {
      return const SizedBox.shrink();
    }
    Recognition? recognition = results!.firstWhere(
        (box) => box.label.trim() == selectedObject,
        orElse: () => Recognition.nullObject());
    if (recognition.id != -1) {
      widget.detectionBloc.detectObject(
          recognition: recognition,
          aspect: aspect,
          h: ScreenParams.screenPreviewSize.height,
          w: ScreenParams.screenPreviewSize.width);
    } else {
      widget.detectionBloc.objectNotDetected(selectedObject!);
    }
    final List<BoxWidget> filteredList = results!
        .where((box) => box.label.trim() != selectedObject)
        .map((box) => BoxWidget(result: box, withoutBox: true))
        .toList();
    if (recognition.id != -1) {
      filteredList.insert(
          0,
          BoxWidget(
            result: recognition,
            withoutBox: false,
          ));
    }

    return Stack(
      children: filteredList,
    );
  }

  void onLatestImageAvailable(CameraImage cameraImage) async {
    _detector?.processFrame(cameraImage);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.inactive:
        if (_cameraController != null) {
          _cameraController!.stopImageStream();
        }
        widget.cameraBloc.initializeCamera(null);
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

class _FlashEffect extends StatefulWidget {
  final int duration;
  const _FlashEffect({super.key, required this.duration});

  @override
  State<_FlashEffect> createState() => _FlashEffectState();
}

class _FlashEffectState extends State<_FlashEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    // Initialize the AnimationController
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.duration),
    );

    // Start the animation
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If animation is complete, return an empty widget
    if (_controller.status == AnimationStatus.completed) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // Use the controller's value directly for opacity
          double opacity = 1.0 - _controller.value;

          return Opacity(
            opacity: opacity,
            child: Container(
              color: Colors.white, // Flash color
            ),
          );
        },
      ),
    );
  }
}
