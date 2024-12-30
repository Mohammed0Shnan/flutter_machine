import 'package:f_m/ui/object_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:f_m/models/screen_params.dart';
import 'package:f_m/ui/detector_widget.dart';

/// [HomeView] stacks [DetectorWidget]
class HomeView extends StatelessWidget {
  final String selectedObject;

  const HomeView({Key? key, required this.selectedObject}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Image.asset(
          'assets/images/tfl_logo.png',
          fit: BoxFit.contain,
        ),
      ),
      body:  DetectorWidget(selectedObject: selectedObject),
    );
  }
}
