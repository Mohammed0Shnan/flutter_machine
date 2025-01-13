import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:camera/camera.dart';
import 'package:f_m/module_detection/bloc/object_detect_bloc.dart';
import 'package:f_m/module_detection/models/screen_params.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as image_lib;
import 'package:f_m/module_detection/models/recognition.dart';
import 'package:f_m/utils/image_utils.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

enum _Codes {
  init,
  busy,
  ready,
  detect,
  result,
}

class _Command {
  const _Command(this.code, {this.args});

  final _Codes code;
  final List<Object>? args;
}

class Detector {
  static late var screenSize;
  static const String _modelPath = 'assets/models/ssd_mobilenet.tflite';
  static const String _labelPath = 'assets/models/ssd_mobilenet.txt';

  Detector._(this._isolate, this._interpreter, this._labels);

  final Isolate _isolate;
  late final Interpreter _interpreter;
  late final List<String> _labels;

  late final SendPort _sendPort;

  bool _isReady = false;

  // // Similarly, StreamControllers are stored in a queue so they can be handled
  // // asynchronously and serially.
  final StreamController<Map<String, dynamic>> resultsStream =
      StreamController<Map<String, dynamic>>();

  /// Open the database at [path] and launch the server on a background isolate..
  static Future<Detector> start() async {
    final ReceivePort receivePort = ReceivePort();
    // sendPort - To be used by service Isolate to send message to our ReceiverPort
    final Isolate isolate =
        await Isolate.spawn(_DetectorServer._run, receivePort.sendPort);

    final Detector result = Detector._(
      isolate,
      await _loadModel(),
      await _loadLabels(),
    );
    receivePort.listen((message) {
      result._handleCommand(message as _Command);
    });
    return result;
  }

  static Future<Interpreter> _loadModel() async {
    final interpreterOptions = InterpreterOptions();

    // Use XNNPACK Delegate
    if (Platform.isAndroid) {
      interpreterOptions.addDelegate(XNNPackDelegate());
    }

    return Interpreter.fromAsset(
      _modelPath,
      options: interpreterOptions..threads = 4,
    );
  }

  static Future<List<String>> _loadLabels() async {
    return (await rootBundle.loadString(_labelPath)).split('\n');
  }

  /// Starts CameraImage processing
  void processFrame(CameraImage cameraImage) {
    if (_isReady) {
      _sendPort.send(_Command(_Codes.detect, args: [cameraImage]));
    }
  }

  /// Handler invoked when a message is received from the port communicating
  /// with the database server.
  void _handleCommand(_Command command) {
    switch (command.code) {
      case _Codes.init:
        _sendPort = command.args?[0] as SendPort;
        RootIsolateToken rootIsolateToken = RootIsolateToken.instance!;
        _sendPort.send(_Command(_Codes.init, args: [
          rootIsolateToken,
          _interpreter.address,
          _labels,
        ]));
      case _Codes.ready:
        _isReady = true;
      case _Codes.busy:
        _isReady = false;
      case _Codes.result:
        _isReady = true;
        resultsStream.add(command.args?[0] as Map<String, dynamic>);
      default:
        debugPrint('Detector unrecognized command: ${command.code}');
    }
  }

  /// Kills the background isolate and its detector server.
  void stop() {
    _isolate.kill();
  }

  Future<DirectionStatus> calculateDirection({
    required double left,
    required double top,
    required double right,
    required double bottom,
    required double frameWidth,
    required double frameHeight,
  }) async {
    List<double> fromLTRB = [left, top, right, bottom, frameWidth, frameHeight];
    print('{{{{====================eedeeeee=======================}}}');

    print(fromLTRB);
    try {
      // return _calculateDirection(fromLTRB);
      return await compute(_calculateDirection, fromLTRB);
    } catch (e) {
      print('{{{{====================$e=======================}}}');
      return DirectionStatus.unknown;
    }
  }

  DirectionStatus _calculateDirection(List<double> fromLTRB) {
    final Rect location =
        Rect.fromLTRB(fromLTRB[0], fromLTRB[1], fromLTRB[2], fromLTRB[3]);

    // Get the object's center coordinates
    final double objectCenterX = location.left + (location.width / 2);
    final double objectCenterY = location.top + (location.height / 2);

    // Define frame dimensions based on ScreenParams
    final double frameWidth = fromLTRB[4];
    final double frameHeight = fromLTRB[5];

    // Define thresholds for horizontal regions
    const double leftThresholdFactor = 0.33;
    const double rightThresholdFactor = 0.66;
    final double leftThreshold = frameWidth * leftThresholdFactor;
    final double rightThreshold = frameWidth * rightThresholdFactor;

    // Define thresholds for vertical regions
    const double topThresholdFactor = 0.33;
    const double bottomThresholdFactor = 0.66;
    final double topThreshold = frameHeight * topThresholdFactor;
    final double bottomThreshold = frameHeight * bottomThresholdFactor;

    // Define a center tolerance (range considered "center")
    const double centerToleranceFactor = 0.1;
    final double centerLeft = frameWidth * (0.5 - centerToleranceFactor);
    final double centerRight = frameWidth * (0.5 + centerToleranceFactor);
    final double centerTop = frameHeight * (0.5 - centerToleranceFactor);
    final double centerBottom = frameHeight * (0.5 + centerToleranceFactor);

    // Check if the object is within the center tolerance
    if (objectCenterX >= centerLeft &&
        objectCenterX <= centerRight &&
        objectCenterY >= centerTop &&
        objectCenterY <= centerBottom) {
      return DirectionStatus.center;
    }

    // If not centered, determine vertical and horizontal directions
    if (objectCenterY < topThreshold) {
      return DirectionStatus.up;
    } else if (objectCenterY > bottomThreshold) {
      return DirectionStatus.down;
    }

    if (objectCenterX < leftThreshold) {
      return DirectionStatus.left;
    } else if (objectCenterX > rightThreshold) {
      return DirectionStatus.right;
    }

    // Default fallback (should not usually reach here)
    return DirectionStatus.unknown;
  }

// Map<String,dynamic> _getDirection(Recognition recognition) {
//   // Access the bounding box (location)
//   final Rect location = recognition.location;
//
//   // Get the object's center x-coordinate
//   final double objectCenterX = location.left + (location.width / 2);
//
//   // Define frame width based on ScreenParams
//   final double frameWidth = ScreenParams.screenPreviewSize.width;
//
//   // Define thresholds for regions
//   const double leftThresholdFactor = 0.33;
//   const double rightThresholdFactor = 0.66;
//
//   final double leftThreshold = frameWidth * leftThresholdFactor;
//   final double rightThreshold = frameWidth * rightThresholdFactor;
//   print('===================> ${leftThreshold} <=======================');
//   print('===================> ${rightThreshold} <=======================');
//   print('===================> ${rightThreshold} <=======================');
//   if (recognition.score > 0.8) {
//     return {'message':'Move farther','direction':DirectionStatus.farther };
//   }
//  else if (recognition.score < 0.8 && recognition.score > 0.66 ) {
//     return {'message':'Move closer','direction':DirectionStatus.closer };
//   }
//  else if (objectCenterX > leftThreshold) {
//     return {'message':'Move right','direction':DirectionStatus.right };
//   } else if (objectCenterX < rightThreshold) {
//     return {'message':'Move left','direction':DirectionStatus.left };
//   }
//
//   return {'message':'Move center','direction':DirectionStatus.center };
//
// }
//
// Map<String, dynamic> _getDirection(Recognition recognition) {
//   // Access the bounding box (location)
//   final Rect location = recognition.location;
//
//   // Get the object's center x-coordinate
//   final double objectCenterX = location.left + (location.width / 2);
//
//   // Define frame width based on ScreenParams
//   final double frameWidth = ScreenParams.screenPreviewSize.width;
//
//   // Define thresholds for regions
//   const double leftThresholdFactor = 0.33;
//   const double rightThresholdFactor = 0.66;
//
//   final double leftThreshold = frameWidth * leftThresholdFactor;
//   final double rightThreshold = frameWidth * rightThresholdFactor;
//
//   // Define a center tolerance (range considered "center")
//   const double centerToleranceFactor = 0.1;
//   final double centerLeft = frameWidth * (0.5 - centerToleranceFactor);
//   final double centerRight = frameWidth * (0.5 + centerToleranceFactor);
//
//   // Include distance-related logic using bounding box size
//   const double fartherThreshold = 0.1; // Smaller objects are farther away
//   const double closerThreshold = 0.3; // Larger objects are closer
//
//   final double objectSizeFactor = location.width / frameWidth;
//
//   if (recognition.score > 0.8 && objectSizeFactor < fartherThreshold) {
//     return {'message': 'Move farther', 'direction': DirectionStatus.farther};
//   } else if (recognition.score > 0.66 && objectSizeFactor > closerThreshold) {
//     return {'message': 'Move closer', 'direction': DirectionStatus.closer};
//   } else if (objectCenterX >= centerLeft && objectCenterX <= centerRight) {
//     return {'message': 'Object is centered', 'direction': DirectionStatus.center};
//   } else if (objectCenterX < leftThreshold) {
//     return {'message': 'Move left', 'direction': DirectionStatus.left};
//   } else if (objectCenterX > rightThreshold) {
//     return {'message': 'Move right', 'direction': DirectionStatus.right};
//   }
//
//   return {'message': 'Adjust position', 'direction': DirectionStatus.unknown};
// }
}

/// This is where we use the new feature Background Isolate Channels, which
/// allows us to use plugins from background isolates.
class _DetectorServer {
  /// Input size of image (height = width = 300)
  static const int mlModelInputSize = 300;

  /// Result confidence threshold
  static const double confidence = 0.3;
  Interpreter? _interpreter;
  List<String>? _labels;

  _DetectorServer(this._sendPort);

  final SendPort _sendPort;

  /// The main entrypoint for the background isolate sent to [Isolate.spawn].
  static void _run(SendPort sendPort) {
    ReceivePort receivePort = ReceivePort();
    final _DetectorServer server = _DetectorServer(sendPort);
    receivePort.listen((message) async {
      final _Command command = message as _Command;
      await server._handleCommand(command);
    });
    sendPort.send(_Command(_Codes.init, args: [receivePort.sendPort]));
  }

  /// Handle the [command] received from the [ReceivePort].
  Future<void> _handleCommand(_Command command) async {
    switch (command.code) {
      case _Codes.init:
        RootIsolateToken rootIsolateToken =
            command.args?[0] as RootIsolateToken;

        BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);
        _interpreter = Interpreter.fromAddress(command.args?[1] as int);
        _labels = command.args?[2] as List<String>;
        _sendPort.send(const _Command(_Codes.ready));
      case _Codes.detect:
        _sendPort.send(const _Command(_Codes.busy));
        _convertCameraImage(command.args?[0] as CameraImage);
      default:
        debugPrint('_DetectorService unrecognized command ${command.code}');
    }
  }

  void _convertCameraImage(CameraImage cameraImage) {
    var preConversionTime = DateTime.now().millisecondsSinceEpoch;

    convertCameraImageToImage(cameraImage).then((image) {
      if (image != null) {
        if (Platform.isAndroid) {
          image = image_lib.copyRotate(image, angle: 90);
        }

        final results = analyseImage(image, preConversionTime);
        _sendPort.send(_Command(_Codes.result, args: [results]));
      }
    });
  }

  Map<String, dynamic> analyseImage(
      image_lib.Image? image, int preConversionTime) {
    var conversionElapsedTime =
        DateTime.now().millisecondsSinceEpoch - preConversionTime;

    var preProcessStart = DateTime.now().millisecondsSinceEpoch;

    /// Pre-process the image
    /// Resizing image for model [300, 300]
    final imageInput = image_lib.copyResize(
      image!,
      width: mlModelInputSize,
      height: mlModelInputSize,
    );

    // Creating matrix representation, [300, 300, 3]
    final imageMatrix = List.generate(
      imageInput.height,
      (y) => List.generate(
        imageInput.width,
        (x) {
          final pixel = imageInput.getPixel(x, y);
          return [pixel.r, pixel.g, pixel.b];
        },
      ),
    );

    var preProcessElapsedTime =
        DateTime.now().millisecondsSinceEpoch - preProcessStart;

    var inferenceTimeStart = DateTime.now().millisecondsSinceEpoch;

    final output = _runInference(imageMatrix);

    // Location
    final locationsRaw = output.first.first as List<List<double>>;

    final List<Rect> locations = locationsRaw
        .map((list) => list.map((value) => (value * mlModelInputSize)).toList())
        .map((rect) => Rect.fromLTRB(rect[1], rect[0], rect[3], rect[2]))
        .toList();

    // Classes
    final classesRaw = output.elementAt(1).first as List<double>;
    final classes = classesRaw.map((value) => value.toInt()).toList();

    // Scores
    final scores = output.elementAt(2).first as List<double>;

    // Number of detections
    final numberOfDetectionsRaw = output.last.first as double;
    final numberOfDetections = numberOfDetectionsRaw.toInt();

    final List<String> classification = [];
    for (var i = 0; i < numberOfDetections; i++) {
      classification.add(_labels![classes[i]]);
    }

    /// Generate recognitions
    List<Recognition> recognitions = [];
    for (int i = 0; i < numberOfDetections; i++) {
      // Prediction score
      var score = scores[i];
      // Label string
      var label = classification[i];

      if (score > confidence) {
        recognitions.add(
          Recognition(i, label, score, locations[i]),
        );
      }
    }

    var inferenceElapsedTime =
        DateTime.now().millisecondsSinceEpoch - inferenceTimeStart;

    var totalElapsedTime =
        DateTime.now().millisecondsSinceEpoch - preConversionTime;

    return {
      "recognitions": recognitions,
      "stats": <String, String>{
        'Conversion time:': conversionElapsedTime.toString(),
        'Pre-processing time:': preProcessElapsedTime.toString(),
        'Inference time:': inferenceElapsedTime.toString(),
        'Total prediction time:': totalElapsedTime.toString(),
        'Frame': '${image.width} X ${image.height}',
      },
    };
  }

  /// Object detection main function
  List<List<Object>> _runInference(
    List<List<List<num>>> imageMatrix,
  ) {
    // Set input tensor [1, 300, 300, 3]
    final input = [imageMatrix];

    // Set output tensor
    // Locations: [1, 10, 4]
    // Classes: [1, 10],
    // Scores: [1, 10],
    // Number of detections: [1]
    final output = {
      0: [List<List<num>>.filled(10, List<num>.filled(4, 0))],
      1: [List<num>.filled(10, 0)],
      2: [List<num>.filled(10, 0)],
      3: [0.0],
    };

    _interpreter!.runForMultipleInputs([input], output);
    return output.values.toList();
  }
}
