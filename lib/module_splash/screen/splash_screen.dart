
import 'package:f_m/module_detection/models/screen_params.dart';
import 'package:f_m/module_detection/detection_routes.dart';
import 'package:f_m/module_splash/bloc/splash_bloc.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {

  const SplashScreen({super.key}
  );
 
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    spalshAnimationBloC.playAnimation();
       WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _getNextRoute().then((route) async{
        Navigator.pushNamedAndRemoveUntil(context, route ,(r)=> false);
      });
    });
  }

  @override
  void dispose() {
    spalshAnimationBloC.close();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    ScreenParams.screenSize = MediaQuery.sizeOf(context);
    return Scaffold(
    );
  }

  Future<String> _getNextRoute() async {
    await Future.delayed(Duration(seconds: 1));
    return DetectionRoutes.SELECTION_SCREEN;
  }

}


