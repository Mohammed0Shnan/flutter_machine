
import 'package:f_m/di/components/app.component.dart';
import 'package:f_m/module_detection/detection_module.dart';
import 'package:f_m/module_splash/splash_module.dart';
import 'package:f_m/module_splash/splash_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final container = await AppComponent.create();
  return runApp(container.app);

}

class MyApp extends StatefulWidget {

  final SplashModule _splashModule;
  final DetectionModule _detectionModule;
   const MyApp(this._splashModule,this._detectionModule, {super.key}
  );

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    Map<String, WidgetBuilder> routes = {};
    routes.addAll(widget._splashModule.getRoutes());
    routes.addAll(widget._detectionModule.getRoutes());

    return FutureBuilder<Widget>(
      initialData: Container(color: Colors.green),
      future: configuratedApp(routes),
      builder: (BuildContext context, AsyncSnapshot<Widget> snapshot) {
        return snapshot.data!;
      },
    );
  }

  Future<Widget> configuratedApp(Map<String, WidgetBuilder> routes) async {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Object Detection',
        routes: routes,
        initialRoute: SplashRoutes.SPLASH_SCREEN
    );
  }
  @override
  void dispose() {
    super.dispose();
  }
}


