import 'dart:io';
import 'package:flutter/material.dart';

class CapturedImageScreen extends StatelessWidget {
  final File image;
  final String objectType;
  final String timestamp;

  const CapturedImageScreen({
    required this.image,
    required this.objectType,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Captured Image")),
      body: Column(
        children: [
          Image.file(image),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Object: $objectType", style: TextStyle(fontSize: 16)),
                Text("Timestamp: $timestamp", style: TextStyle(fontSize: 16)),
                // Additional metadata can be added here
              ],
            ),
          ),
        ],
      ),
    );
  }
}
