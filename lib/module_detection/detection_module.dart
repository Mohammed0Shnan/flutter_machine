
import 'package:f_m/abstracts/module/my_module.dart';
import 'package:f_m/module_detection/screen/object_selection_screen.dart';
import 'package:flutter/material.dart';

import 'detection_routes.dart';

class DetectionModule extends MyModule {

  final ObjectSelectionScreen _selectionScreen;
  DetectionModule(this._selectionScreen ) ;

  @override
  Map<String, WidgetBuilder> getRoutes() {
    return {DetectionRoutes.SELECTION_SCREEN : (context) => _selectionScreen};
  }
}