import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as imglib;
import 'package:face_recognition_app/core/base/exception.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

abstract class AuthMlDataSource {
  Future<Face> getFace(InputImage inputImage);
  Future<List> getPreProcess(File file, Face faceDetected);
  Future<void> compareFace(List preProcess1, List preProcess2);
}

class AuthMlDataSourceImpl implements AuthMlDataSource {
  final FaceDetector _faceDetector;
  final Interpreter _interpreter;
  final double _threshold = 0.80;

  AuthMlDataSourceImpl(this._faceDetector, this._interpreter);

  @override
  Future<Face> getFace(InputImage inputImage) async {
    try {
      final List<Face> faces = await _faceDetector.processImage(inputImage);
      return faces.first;
    } catch (e) {
      throw const DatabaseException('Gagal mendapatkan wajah');
    }
  }

  @override
  Future<void> compareFace(List preProcess1, List preProcess2) async {
    final currDist = _euclideanDistance(preProcess1, preProcess2);
    if (currDist > _threshold) {
      throw const DatabaseException('Wajah tidak cocok');
    }
  }

  double calculateEuclideanDistance(Point<int> point1, Point<int> point2) {
    return sqrt(((point1.x - point2.x) * (point1.y - point2.y) +
        (point1.y - point2.y) * (point1.y - point2.y)));
  }

  @override
  Future<List> getPreProcess(File file, Face faceDetected) async {
    imglib.Image croppedImage = await _cropFace(file, faceDetected);
    imglib.Image img = imglib.copyResizeCropSquare(croppedImage, size: 112);

    Float32List imageAsList = _imageToByteListFloat32(img);

    List input = imageAsList;
    input = input.reshape([1, 112, 112, 3]);
    List output = List.generate(1, (index) => List.filled(192, 0));

    _interpreter.run(input, output);
    output = output.reshape([192]);

    return List.from(output);
  }

  Future<imglib.Image> _cropFace(File file, Face faceDetected) async {
    final convertedImage0 = await imglib.decodeImageFile(file.path);
    if (convertedImage0 == null) {
      throw const DatabaseException('Gagal crop face');
    }
    final convertedImage = imglib.copyRotate(convertedImage0, angle: -90);
    double x = faceDetected.boundingBox.left - 10.0;
    double y = faceDetected.boundingBox.top - 10.0;
    double w = faceDetected.boundingBox.width + 10.0;
    double h = faceDetected.boundingBox.height + 10.0;
    return imglib.copyCrop(convertedImage,
        x: x.round(), y: y.round(), width: w.round(), height: h.round());
  }

  Float32List _imageToByteListFloat32(imglib.Image image) {
    var convertedBytes = Float32List(1 * 112 * 112 * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;

    for (var i = 0; i < 112; i++) {
      for (var j = 0; j < 112; j++) {
        var pixel = image.getPixel(j, i);
        // Extract RGBA components from pixel value
        buffer[pixelIndex++] = (pixel.r - 128) / 128;
        buffer[pixelIndex++] = (pixel.g - 128) / 128;
        buffer[pixelIndex++] = (pixel.b - 128) / 128;
      }
    }
    return convertedBytes.buffer.asFloat32List();
  }

  double _euclideanDistance(List? e1, List? e2) {
    if (e1 == null || e2 == null) throw Exception("Null argument");

    double sum = 0.0;
    for (int i = 0; i < e1.length; i++) {
      sum += pow((e1[i] - e2[i]), 2);
    }
    return sqrt(sum);
  }
}
