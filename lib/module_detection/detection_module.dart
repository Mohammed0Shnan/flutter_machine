
import 'package:f_m/abstracts/module/my_module.dart';
import 'package:f_m/module_detection/screen/detector_screen.dart';
import 'package:flutter/material.dart';

import 'detection_routes.dart';

class DetectionModule extends MyModule {

  final DetectorScreen _detectorScreen;
  DetectionModule(this._detectorScreen ) ;

  @override
  Map<String, WidgetBuilder> getRoutes() {
    return {DetectionRoutes.DETECTOR_SCREEN : (context) => _detectorScreen};
  }
}