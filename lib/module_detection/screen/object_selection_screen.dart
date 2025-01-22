import 'package:f_m/module_detection/detection_routes.dart';
import 'package:f_m/utils/bouncing_press_effect.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:lottie/lottie.dart';
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
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              childAspectRatio: 0.8,
            ),
            itemCount: objects.length,
            itemBuilder: (context, index) {
              return AnimationConfiguration.staggeredGrid(
                position: index,
                columnCount: 2,
                delay: const Duration(milliseconds:600),
                child: ScaleAnimation(
                  scale: 0.5,
                  child: FadeInAnimation(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          DetectionRoutes.DETECTOR_SCREEN,
                          arguments: objects.values.toList()[index],
                        );
                      },
                      child: BouncingPressEffect(
                        minScale: .95,
                        child: AspectRatio(
                          aspectRatio: 3 / 4,
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0),
                            ),
                            elevation: 4.0,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Lottie animation
                                Expanded(
                                  flex: 3,
                                  child: Lottie.asset(
                                    'assets/lottie/${objects.values.toList()[index]}.json',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                const SizedBox(height: 8.0),
                                // Object name or value
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    objects.values.toList()[index],
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
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
