import 'package:f_m/module_detection/detection_routes.dart';
import 'package:flutter/material.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Object for Detection'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: objects.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(objects.values.toList()[index]),
                      trailing: Icon(Icons.arrow_forward),
                      onTap: () {
                        Navigator.pushNamed(
                            context, DetectionRoutes.DETECTOR_SCREEN,
                            arguments: objects.values.toList()[index]);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
