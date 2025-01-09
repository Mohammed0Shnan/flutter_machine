import 'package:f_m/module_detection/bloc/camera_cubit.dart';
import 'package:f_m/module_detection/bloc/object_detect_bloc.dart';
import 'package:f_m/module_detection/screen/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


class ObjectSelectionScreen extends StatelessWidget {

  final ObjectDetectionCubit bloc;
  final CameraCubit cameraBloc;
  ObjectSelectionScreen({super.key,required this.bloc , required this.cameraBloc});

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
                        // Pass the selected object to the next screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BlocProvider.value(
                              value: bloc,
                              child: HomeView(
                                selectedObject: objects.values.toList()[index],
                              ),
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
