import 'package:f_m/module_detection/detection_routes.dart';
import 'package:f_m/utils/bouncing_press_effect.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
class ObjectSelectionScreen extends StatelessWidget {
  ObjectSelectionScreen(
      {super.key});

  final Map<String, String> objects = {
    'Mobile': 'cell phone',
    'Laptop': 'laptop',
    'Mouse': 'mouse',
    'Bottle': 'bottle',
  };

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title:  FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            "Select Object For Detection",
            style: TextStyle(
                fontSize: .03 * size.height,
                fontWeight: FontWeight.w700,
                color: Colors.black),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: AnimationLimiter(
          child: ListView.builder(
              itemCount: objects.length,
              itemBuilder: (context, index) {
                return AnimationConfiguration.staggeredList(
                  position: index,
                  delay: Duration(milliseconds: 200),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: BouncingPressEffect(
                        minScale: .95,
                        child: Card(
                          margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                          child: ListTile(
                            title: Text(objects.values.toList()[index]),
                            trailing: Icon(Icons.arrow_forward),
                            onTap: () {
                              Navigator.pushNamed(
                                  context, DetectionRoutes.DETECTOR_SCREEN,
                                  arguments: objects.values.toList()[index]);
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                );

              },
            ),
        ),
      ),
    );
  }
}
