import 'package:f_m/main.dart';
import 'app.component.inject.dart' as lib;

abstract class AppComponent {
  MyApp get app;
  static Future<AppComponent> create() async {
    return await lib.AppComponentInjector.create();
  }
}
