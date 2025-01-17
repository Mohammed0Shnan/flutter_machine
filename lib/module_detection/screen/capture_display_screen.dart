import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class CapturedImageScreen extends StatefulWidget {
  final CameraController controller;
  final Rect boundingBox;
  final String objectName;

  const CapturedImageScreen({
    required this.controller,
    required this.boundingBox,
    required this.objectName,
    super.key,
  });

  @override
  State<CapturedImageScreen> createState() => _CapturedImageScreenState();
}

class _CapturedImageScreenState extends State<CapturedImageScreen> {
  File? _croppedImage;
  bool _isProcessing = true;

  @override
  void initState() {
    super.initState();
    _captureAndProcessImage();


  }

  Future<void> _captureAndProcessImage() async {


    try {
      final capturedImage = await widget.controller.takePicture();
      final imageFile = File(capturedImage.path);
      final imageBytes = await imageFile.readAsBytes();

      final decodedImage = img.decodeImage(imageBytes);
      const padding = 10;
      if (decodedImage != null) {
        final croppedImage = img.copyCrop(
          decodedImage,
          x: (widget.boundingBox.left - padding).clamp(0, decodedImage.width).toInt(),
          y: (widget.boundingBox.top - padding).clamp(0, decodedImage.height).toInt(),
          width: (widget.boundingBox.width + padding).clamp(0, decodedImage.width - (widget.boundingBox.left - padding).toInt()).toInt(),
          height: (widget.boundingBox.height + padding).clamp(0, decodedImage.height - (widget.boundingBox.top - padding).toInt()).toInt(),
        );

        final croppedImagePath =
            '${imageFile.parent.path}/cropped_${imageFile.uri.pathSegments.last}';
        final croppedFile = File(croppedImagePath)
          ..writeAsBytesSync(img.encodeJpg(croppedImage));

        setState(() {
          _croppedImage = croppedFile;
        });
      }
    } catch (e) {
      print("Error capturing image: $e");
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Captured Object: ${widget.objectName}'),
      ),
      body: Center(
        child: _isProcessing
            ? const CircularProgressIndicator()
            : _croppedImage != null
            ? Hero(
          tag: 'hero_camera_icon',
          child: Image.file(
            _croppedImage!,
            height: 200,
            width: 200,
            fit: BoxFit.cover,
          ),
        )
            : const Text('Error processing image.'),
      ),
    );
  }

}
