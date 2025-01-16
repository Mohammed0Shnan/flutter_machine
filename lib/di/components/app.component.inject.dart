import 'package:f_m/di/components/app.component.dart';
import 'package:f_m/main.dart';
import 'package:f_m/module_detection/bloc/camera_cubit.dart' as _i1;
import 'package:f_m/module_detection/bloc/mediation_bloc.dart' as _i2;
import 'package:f_m/module_detection/bloc/object_detect_bloc.dart'as _i3;
import 'package:f_m/module_detection/detection_module.dart'as _i4;
import 'package:f_m/module_detection/screen/detector_screen.dart'as _i5;
import 'package:f_m/module_detection/screen/object_selection_screen.dart'as _i6;
import 'package:f_m/module_splash/screen/splash_screen.dart'as _i7;
import 'package:f_m/module_splash/splash_module.dart'as _i8;

import '../../module_splash/bloc/splash_bloc.dart';

class AppComponentInjector implements AppComponent {
  AppComponentInjector._();

  //! Singleton
  final _i2.Mediator mediatorSingleton = _i2.MediatorImp();

  static Future<AppComponent> create() async {
    final injector = AppComponentInjector._();
    return injector;
  }

  MyApp _createApp() => MyApp(_createSplashModule(), _createDetectionModule());

  _i8.SplashModule _createSplashModule(){
   final SpalshAnimationBloC  spalshAnimationBloC   = SpalshAnimationBloC(false);
   return _i8.SplashModule(_i7.SplashScreen(spalshAnimationBloC: spalshAnimationBloC,));

  }

  _i4.DetectionModule _createDetectionModule() {

    final _i1.CameraCubit cameraBloc = _i1.CameraCubit(mediator: mediatorSingleton);
    final  _i3.ObjectDetectionCubit objectDetectionCubit = _i3.ObjectDetectionCubit( mediator: mediatorSingleton);
     return _i4.DetectionModule(_i6.ObjectSelectionScreen(

      ),
         _i5.DetectorScreen(
           detectionBloc:objectDetectionCubit,
           cameraBloc: cameraBloc,
         )
     );}

  MyApp get app {
    return _createApp();
  }
}
