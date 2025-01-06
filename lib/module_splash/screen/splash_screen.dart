
import 'package:f_m/models/screen_params.dart';
import 'package:f_m/module_splash/bloc/splash_bloc.dart';
import 'package:f_m/module_detection/screen/object_selection_screen.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {

  SplashScreen(
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
        await Future.delayed(Duration(seconds: 1));
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => ObjectSelectionScreen()),
              (Route<dynamic> route) => false,
        );
        // Navigator.of(context).pushNamedAndRemoveUntil(route, (route) => false);
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
    return '';
  }

}


