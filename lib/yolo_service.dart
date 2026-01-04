import 'dart:io';
import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class DetectedObject {
  final String label;
  final double confidence;
  final double x;
  final double y;
  final double width;
  final double height;

  DetectedObject({
    required this.label,
    required this.confidence,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  @override
  String toString() {
    return 'DetectedObject(label: $label, confidence: ${(confidence * 100).toStringAsFixed(1)}%, '
        'bbox: ($x, $y, $width, $height))';
  }
}

class YoloService {
  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isInitialized = false;

  late int _inputSize; // Set from model input tensor
  late List<int> _inputShape; // [1, H, W, 3]
  late List<int> _outputShape; // e.g., [1, 25200, 85]

  static const double CONFIDENCE_THRESHOLD = 0.5;
  static const double IOU_THRESHOLD = 0.5;

  // Common COCO dataset labels for object detection
  static const List<String> COCO_LABELS = [
    'person', 'bicycle', 'car', 'motorcycle', 'airplane', 'bus', 'train', 'truck', 'boat',
    'traffic light', 'fire hydrant', 'stop sign', 'parking meter', 'bench', 'bird', 'cat',
    'dog', 'horse', 'sheep', 'cow', 'elephant', 'bear', 'zebra', 'giraffe', 'backpack',
    'umbrella', 'handbag', 'tie', 'suitcase', 'frisbee', 'skis', 'snowboard', 'sports ball',
    'kite', 'baseball bat', 'baseball glove', 'skateboard', 'surfboard', 'tennis racket',
    'bottle', 'wine glass', 'cup', 'fork', 'knife', 'spoon', 'bowl', 'banana', 'apple',
    'sandwich', 'orange', 'broccoli', 'carrot', 'hot dog', 'pizza', 'donut', 'cake', 'chair',
    'couch', 'potted plant', 'bed', 'dining table', 'toilet', 'tv', 'laptop', 'mouse',
    'remote', 'keyboard', 'cell phone', 'microwave', 'oven', 'toaster', 'sink', 'refrigerator',
    'book', 'clock', 'vase', 'scissors', 'teddy bear', 'hair drier', 'toothbrush'
  ];

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('Loading YOLO model...');
      
      // Load the TFLite model
      _interpreter = await Interpreter.fromAsset('assets/models/yolov5.tflite');

      // Capture input/output shapes from the model to avoid shape mismatches
      _inputShape = _interpreter!.getInputTensor(0).shape;
      _outputShape = _interpreter!.getOutputTensor(0).shape;
      _inputSize = _inputShape.length > 1 ? _inputShape[1] : 320;
      
      // Use COCO labels
      _labels = COCO_LABELS;
      
      _isInitialized = true;
      print('YOLO model loaded successfully with ${_labels.length} classes');
    } catch (e) {
      print('Error loading YOLO model: $e');
      throw Exception('Failed to initialize YOLO model: $e');
    }
  }

  Future<List<DetectedObject>> detectObjects(File imageFile) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Read and decode image
      final bytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Resize image to model input size
      img.Image resizedImage = img.copyResize(
        image,
        width: _inputSize,
        height: _inputSize,
      );

      // Prepare input tensor
      var input = _imageToByteListFloat32(resizedImage);
      // Interpreter expects a 4D tensor; wrap/reshape accordingly
      var modelInput = input.reshape(_inputShape);
      
      // Prepare output tensor based on actual model output shape
      var outputElementCount = _outputShape.fold(1, (a, b) => a * b);
      var output = List.filled(outputElementCount, 0.0).reshape(_outputShape);

      // Run inference
      _interpreter!.run(modelInput, output);

      // Parse detections
      List<DetectedObject> detections = _parseOutput(output);
      
      // Apply NMS (Non-Maximum Suppression)
      List<DetectedObject> filteredDetections = _applyNMS(detections);

      print('Detected ${filteredDetections.length} objects');
      for (var obj in filteredDetections) {
        print(obj);
      }

      return filteredDetections;
    } catch (e) {
      print('Error during object detection: $e');
      return [];
    }
  }

  Float32List _imageToByteListFloat32(img.Image image) {
    var convertedBytes = Float32List(1 * _inputSize * _inputSize * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;

    for (var y = 0; y < _inputSize; y++) {
      for (var x = 0; x < _inputSize; x++) {
        var pixel = image.getPixel(x, y);
        
        // Normalize to [0, 1]
        buffer[pixelIndex++] = pixel.r / 255.0;
        buffer[pixelIndex++] = pixel.g / 255.0;
        buffer[pixelIndex++] = pixel.b / 255.0;
      }
    }

    return Float32List.view(
      convertedBytes.buffer,
      0,
      1 * _inputSize * _inputSize * 3
    );
  }

  List<DetectedObject> _parseOutput(List output) {
    List<DetectedObject> detections = [];

    // Output format typically [1, anchors, 85]
    final int anchors = _outputShape.length > 1 ? _outputShape[1] : output[0].length;
    final int totalCols = _outputShape.length > 2 ? _outputShape[2] : (output[0][0] as List).length;
    final int classCount = (totalCols - 5).clamp(0, 1000);

    for (int i = 0; i < anchors; i++) {
      // Extract objectness score
      double objectness = output[0][i][4];
      
      if (objectness < CONFIDENCE_THRESHOLD) continue;

      // Extract bbox coordinates (center_x, center_y, width, height)
      double cx = output[0][i][0];
      double cy = output[0][i][1];
      double w = output[0][i][2];
      double h = output[0][i][3];

      // Find class with highest confidence
      int classId = 0;
      double maxClassScore = 0.0;
      
      for (int c = 0; c < classCount; c++) {
        double classScore = output[0][i][5 + c];
        if (classScore > maxClassScore) {
          maxClassScore = classScore;
          classId = c;
        }
      }

      double confidence = objectness * maxClassScore;
      
      if (confidence < CONFIDENCE_THRESHOLD) continue;

      // Convert to corner coordinates
      double x = (cx - w / 2);
      double y = (cy - h / 2);

      if (classId < _labels.length) {
        detections.add(DetectedObject(
          label: _labels[classId],
          confidence: confidence,
          x: x,
          y: y,
          width: w,
          height: h,
        ));
      }
    }

    return detections;
  }

  List<DetectedObject> _applyNMS(List<DetectedObject> detections) {
    if (detections.isEmpty) return [];

    // Sort by confidence
    detections.sort((a, b) => b.confidence.compareTo(a.confidence));

    List<DetectedObject> filtered = [];
    List<bool> suppressed = List.filled(detections.length, false);

    for (int i = 0; i < detections.length; i++) {
      if (suppressed[i]) continue;

      filtered.add(detections[i]);

      for (int j = i + 1; j < detections.length; j++) {
        if (suppressed[j]) continue;

        if (detections[i].label == detections[j].label) {
          double iou = _calculateIOU(detections[i], detections[j]);
          if (iou > IOU_THRESHOLD) {
            suppressed[j] = true;
          }
        }
      }
    }

    return filtered;
  }

  double _calculateIOU(DetectedObject a, DetectedObject b) {
    double x1 = a.x > b.x ? a.x : b.x;
    double y1 = a.y > b.y ? a.y : b.y;
    double x2 = (a.x + a.width < b.x + b.width) ? a.x + a.width : b.x + b.width;
    double y2 = (a.y + a.height < b.y + b.height) ? a.y + a.height : b.y + b.height;

    double intersectionArea = (x2 - x1).clamp(0, double.infinity) * 
                              (y2 - y1).clamp(0, double.infinity);

    double areaA = a.width * a.height;
    double areaB = b.width * b.height;
    double unionArea = areaA + areaB - intersectionArea;

    return intersectionArea / unionArea;
  }

  void dispose() {
    _interpreter?.close();
    _isInitialized = false;
  }
}
