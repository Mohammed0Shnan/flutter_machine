
import 'package:f_m/state_managment/camera_cubit.dart';
import 'package:f_m/state_managment/object_detect_state_managment.dart';
import 'package:f_m/ui/object_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MyApp());
}
var detectBloc = ObjectDetectionCubit(cameraCubit: CameraCubit());
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Live Object Detection TFLite',
        debugShowCheckedModeBanner:
    false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home:  ObjectSelectionScreen(),
      );
}
