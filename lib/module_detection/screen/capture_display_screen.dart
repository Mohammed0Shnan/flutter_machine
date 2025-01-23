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
    super.key,
    required this.boundingBox,
    required this.objectName,
    required this.image,
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
    _processImage();
  }

  Future<void> _processImage() async {
    try {
      // Load the image from the file
      final imageFile = File(widget.image.path);
      final imageBytes = await imageFile.readAsBytes();
      final decodedImage = img.decodeImage(imageBytes);

      if (decodedImage != null) {
        final imageWidth = decodedImage.width;
        final imageHeight = decodedImage.height;

        const padding = 10;
        double cropX = widget.boundingBox.left - (4*padding);
        double cropY = widget.boundingBox.top - padding;
        double cropWidth = widget.boundingBox.width + 2 * padding;
        double cropHeight = widget.boundingBox.height + 3 * padding;

        // Ensure crop dimensions do not exceed image boundaries
        if (cropX < 0) {
          cropX = 0;
        }
        if (cropY < 0) {
          cropY = 0;
        }
        if (cropX + cropWidth > imageWidth) {
          cropWidth = imageWidth - cropX;
        }
        if (cropY + cropHeight > imageHeight) {
          cropHeight = imageHeight - cropY;
        }

        // Ensure the crop width and height are valid
        if (cropWidth > 0 && cropHeight > 0) {
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
          print("Error: Cropping dimensions are invalid.");
        }
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
            SizedBox(height: size.height * 0.16),
            Center(
              child: _isProcessing
                  ? const CircularProgressIndicator()
                  : _croppedImage != null
                  ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      _croppedImage!,
                      height: size.height * 0.5,
                      width: size.width * 0.9,
                      fit: BoxFit.cover,
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
