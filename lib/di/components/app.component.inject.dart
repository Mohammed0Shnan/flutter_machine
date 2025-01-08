import 'package:f_m/di/components/app.component.dart';
import 'package:f_m/main.dart';
import 'package:f_m/module_detection/bloc/camera_cubit.dart';
import 'package:f_m/module_detection/bloc/mediation_bloc.dart';
import 'package:f_m/module_detection/bloc/object_detect_bloc.dart';
import 'package:f_m/module_detection/detection_module.dart';
import 'package:f_m/module_detection/screen/object_selection_screen.dart';
import 'package:f_m/module_splash/screen/splash_screen.dart';
import 'package:f_m/module_splash/splash_module.dart';

class AppComponentInjector implements AppComponent {
  AppComponentInjector._();

  static Future<AppComponent> create() async {
    final injector = AppComponentInjector._();
    return injector;
  }

  MyApp _createApp() => MyApp(_createSplashModule(), _createDetectionModule());

  SplashModule _createSplashModule() => SplashModule(SplashScreen());

  DetectionModule _createDetectionModule() {
     Mediator mediator = MediatorImp();
     CameraCubit cameraCubit = CameraCubit(mediator: mediator);
     ObjectDetectionCubit objectDetectionCubit = ObjectDetectionCubit( mediator: mediator);
     return DetectionModule(ObjectSelectionScreen(
        bloc:objectDetectionCubit,
      ));}

  MyApp get app {
    return _createApp();
  }
}
