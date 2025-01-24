import 'package:flutter/cupertino.dart';

Route<dynamic> onGenerateRoute(RouteSettings settings, Map<String, WidgetBuilder> routes) {
  final WidgetBuilder? builder = routes[settings.name];
  if (builder == null) {
    throw Exception('Route ${settings.name} is not defined');
  }

  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) =>
        builder(context),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.ease;

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      var offsetAnimation = animation.drive(tween);

      return SlideTransition(
        position: offsetAnimation,
        child: child,
      );
    },
    settings: settings,
  );
}
