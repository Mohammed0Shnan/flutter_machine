import 'package:f_m/di/components/app.component.dart';
import 'package:f_m/main.dart';
import 'package:f_m/module_detection/detection_module.dart';
import 'package:f_m/module_detection/screen/detector_screen.dart';
import 'package:f_m/module_splash/screen/splash_screen.dart';
import 'package:f_m/module_splash/splash_module.dart';

class AppComponentInjector implements AppComponent {
  AppComponentInjector._();


  static Future<AppComponent> create() async {
    final injector = AppComponentInjector._();
    return injector;
  }

  MyApp _createApp() => MyApp(
      _createSplashModule(),_createDetectionModule()
      );
  SplashModule _createSplashModule() =>
      SplashModule(SplashScreen());

  DetectionModule _createDetectionModule()=> DetectionModule(DetectorScreen(selectedObject: '',));

  MyApp get app {
    return _createApp();
  }
}
