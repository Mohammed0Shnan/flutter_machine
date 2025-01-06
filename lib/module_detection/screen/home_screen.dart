import 'package:flutter/material.dart';
import 'package:f_m/module_detection/screen/detector_screen.dart';

/// [HomeView] stacks [DetectorWidget]
class HomeView extends StatelessWidget {
  final String selectedObject;

  const HomeView({super.key, required this.selectedObject});

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
      body:  DetectorScreen(selectedObject: selectedObject),
    );
  }
}
