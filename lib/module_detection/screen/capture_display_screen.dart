import 'dart:io';
import 'package:camera/camera.dart';
import 'package:f_m/module_detection/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class CapturedImageScreen extends StatefulWidget {
  final XFile image;
  final Rect boundingBox;
  final String objectName;

  const CapturedImageScreen({
    required this.boundingBox,
    required this.objectName,
    required this.image,
    Key? key,
  }) : super(key: key);

  @override
  State<CapturedImageScreen> createState() => _CapturedImageScreenState();
}

class _CapturedImageScreenState extends State<CapturedImageScreen> {
  File? _croppedImage;
  bool _isProcessing = true;

  @override
  void initState() {
    super.initState();
    _processImage();
  }

  Future<void> _processImage() async {
    try {
      // Load the image file
      final imageFile = File(widget.image.path);
      final imageBytes = await imageFile.readAsBytes();
      final decodedImage = img.decodeImage(imageBytes);

      if (decodedImage != null) {
        // Use the decoded image dimensions
        final imageWidth = decodedImage.width;
        final imageHeight = decodedImage.height;

        // Scale factors to map bounding box to original image size
        final scaleX = imageWidth / imageWidth; // This will always be 1.0
        final scaleY = imageHeight / imageHeight; // This will always be 1.0

        // Calculate crop dimensions based on scaled bounding box
        const padding = 10; // Adjust padding as needed
        final cropX = (widget.boundingBox.left * scaleX - padding).clamp(0, imageWidth);
        final cropY = (widget.boundingBox.top * scaleY - padding).clamp(0, imageHeight);
        final cropWidth = (widget.boundingBox.width * scaleX + 2 * padding)
            .clamp(0, imageWidth - cropX);
        final cropHeight = (widget.boundingBox.height * scaleY + 2 * padding)
            .clamp(0, imageHeight - cropY);

        // Crop the image
        final croppedImage = img.copyCrop(
          decodedImage,
          x: cropX.toInt(),
          y: cropY.toInt(),
          width: cropWidth.toInt(),
          height: cropHeight.toInt(),
        );

        // Save the cropped image to a new file
        final croppedImagePath =
            '${imageFile.parent.path}/cropped_${imageFile.uri.pathSegments.last}';
        final croppedFile = File(croppedImagePath)
          ..writeAsBytesSync(img.encodeJpg(croppedImage));

        // Update state with the cropped image
        setState(() {
          _croppedImage = croppedFile;
        });
      } else {
        print("Error: Failed to decode image.");
      }
    } catch (e) {
      print("Error processing image: $e");
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: true,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            CustomAppBar(
              title: 'Captured Object Screen',
              style: TextStyle(
                fontSize: size.height * 0.03,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            SizedBox(height: size.height * 0.2),
            Center(
              child: _isProcessing
                  ? const CircularProgressIndicator()
                  : _croppedImage != null
                  ? Hero(
                tag: 'hero_camera_icon',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    _croppedImage!,
                    height: size.height * 0.3, // Dynamically sized
                    width: size.width * 0.5,
                    fit: BoxFit.cover,
                  ),
                ),
              )
                  : const Text(
                'Error processing image.',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: size.height * 0.1),
            Text(
              'Detecting ${widget.objectName}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}
