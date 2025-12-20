import 'dart:io';
import 'package:flutter/services.dart';

class CameraService {
  static const MethodChannel _channel = MethodChannel('com.example.seeforme/camera');
  static final CameraService _instance = CameraService._internal();

  factory CameraService() {
    return _instance;
  }

  CameraService._internal();

  Future<void> startCamera() async {
    try {
      await _channel.invokeMethod('startCamera');
    } on PlatformException catch (e) {
      print('Error starting camera: ${e.message}');
      rethrow;
    }
  }

  Future<void> stopCamera() async {
    try {
      await _channel.invokeMethod('stopCamera');
    } on PlatformException catch (e) {
      print('Error stopping camera: ${e.message}');
      rethrow;
    }
  }

  void setImageCapturedCallback(Function(String) callback) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onImageCaptured') {
        final String imagePath = call.arguments as String;
        callback(imagePath);
      }
    });
  }
} 