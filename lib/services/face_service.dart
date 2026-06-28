import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceService {
  // FaceDetector hanya dibuat di platform mobile (Android/iOS).
  // Di Web, google_mlkit_face_detection tidak tersedia sehingga
  // inisialisasi langsung akan crash. Gunakan nullable + lazy init.
  FaceDetector? _faceDetector;

  FaceService() {
    if (!kIsWeb) {
      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableClassification: true,
          enableLandmarks: false,
          enableContours: false,
          enableTracking: false,
          performanceMode: FaceDetectorMode.fast,
        ),
      );
    }
  }

  static final Map<DeviceOrientation, int> _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  /// Konversi CameraImage menjadi InputImage untuk ML Kit.
  /// Hanya relevan di mobile — kembalikan null di Web.
  InputImage? inputImageFromCameraImage(
    CameraImage image,
    CameraDescription camera,
    CameraController controller,
  ) {
    if (kIsWeb) return null;

    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;

    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation =
          _orientations[controller.value.deviceOrientation];

      if (rotationCompensation == null) return null;

      if (camera.lensDirection == CameraLensDirection.front) {
        rotationCompensation =
            (sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }

      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }

    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  Future<List<Face>> detectFaces(InputImage inputImage) async {
    if (kIsWeb || _faceDetector == null) return [];
    return await _faceDetector!.processImage(inputImage);
  }

  void dispose() {
    _faceDetector?.close();
  }
}
