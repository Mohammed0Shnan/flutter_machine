import 'dart:io';
import 'package:camera/camera.dart';
import 'package:f_m/module_detection/models/screen_params.dart';
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
      final box = widget.boundingBox;
      final imageWidth = ScreenParams.screenPreviewSize.width;
      final imageHeight = ScreenParams.screenPreviewSize.height;
      final screenWidth = ScreenParams.previewSize.width;
      final screenHeight = ScreenParams.previewSize.height;
      final devicePixelRatio = ScreenParams.previewRatio;

      final screenWidthInPixels = screenWidth * devicePixelRatio;
      final screenHeightInPixels = screenHeight * devicePixelRatio;

      // Apply scaling
      final scaleX = imageWidth / screenWidthInPixels;
      final scaleY = imageHeight / screenHeightInPixels;

      double cropX = box.left * scaleX;
      double cropY = (box.top - (box.height / 2)) * scaleY;
      double cropWidth = box.width * scaleX;
      double cropHeight = box.height * scaleY;

      final paddingPercentage = 0.1;
      cropX -= cropWidth * paddingPercentage;
      cropY -= cropHeight * paddingPercentage;
      cropWidth += cropWidth * paddingPercentage * 2;
      cropHeight += cropHeight * paddingPercentage * 2;

      cropX = cropX.clamp(0, imageWidth.toDouble());
      cropY = cropY.clamp(0, imageHeight.toDouble());
      cropWidth = cropWidth.clamp(0, imageWidth - cropX);
      cropHeight = cropHeight.clamp(0, imageHeight - cropY);

      if (cropY + cropHeight > imageHeight) {
        cropY = imageHeight - cropHeight;
      }

      final imageFile = File(widget.image.path);
      final imageBytes = await imageFile.readAsBytes();
      final decodedImage = img.decodeImage(imageBytes);

      if (decodedImage != null) {
        if (cropWidth > 0 && cropHeight > 0) {
          final croppedImage = img.copyCrop(
            decodedImage,
            x: cropX.toInt(),
            y: cropY.toInt(),
            width: cropWidth.toInt(),
            height: cropHeight.toInt(),
          );

          final croppedImagePath = '${imageFile.parent.path}/cropped_${imageFile.uri.pathSegments.last}';
          final croppedFile = File(croppedImagePath)
            ..writeAsBytesSync(img.encodeJpg(croppedImage));
          setState(() {
            _croppedImage = croppedFile;
          });
        } else {
          print("Error: Invalid cropping dimensions.");
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
