import 'package:f_m/ui/home_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/screen_params.dart';
import '../state_managment/object_detect_state_managment.dart';
class ObjectSelectionScreen extends StatelessWidget {
  final Map<String, String> objects = {
    'Mobile': 'cell phone',
    'Laptop': 'laptop',
    'Mouse': 'mouse',
    'Bottle': 'bottle',
  };

  @override
  Widget build(BuildContext context) {
    ScreenParams.screenSize = MediaQuery.sizeOf(context);

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
                        // Pass the selected object to the next screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HomeView(
                              selectedObject: objects.values.toList()[index],
                            ),
                          ),
                        );
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
