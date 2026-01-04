import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Phi-3 Mini inference powered by GGUF via native llama.cpp binding
/// 
/// IMPORTANT: Due to the large model size (2.3GB), the GGUF file is NOT bundled.
/// Users must manually copy 'Phi-3-mini-4k-instruct-q4.gguf' to the app's
/// documents directory before using this feature.
class Phi3Service {
  static const String _modelFileName = 'Phi-3-mini-4k-instruct-q4.gguf';
  static const platform = MethodChannel('com.example.seeforme/phi3');

  bool _isInitialized = false;
  String? _modelPath;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _modelPath = await _prepareModelFile();
      print('Loading Phi-3 Mini GGUF from $_modelPath');
      
      // Call native method to load the model
      final result = await platform.invokeMethod<bool>('loadModel', {
        'modelPath': _modelPath,
        'nCtx': 2048,
        'nThreads': 4,
      });
      
      if (result != true) {
        throw Exception('Failed to load model via native bridge');
      }
      
      _isInitialized = true;
      print('Phi-3 Mini GGUF loaded successfully');
    } catch (e) {
      print('Error loading Phi-3 GGUF: $e');
      rethrow;
    }
  }

  /// Generates an English description from structured scene text.
  /// This method does not include any fallback; it will throw if inference fails.
  Future<String> generateDescription(String scenePrompt) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_modelPath == null) {
      throw StateError('Phi-3 model is not initialized');
    }

    final String prompt = _buildPrompt(scenePrompt);

    try {
      final result = await platform.invokeMethod<String>('generateText', {
        'prompt': prompt,
        'maxTokens': 160,
        'temperature': 0.6,
        'topP': 0.9,
      });

      if (result == null) {
        throw Exception('No response from native Phi-3 inference');
      }

      final trimmed = result.trim();
      print('Phi-3 output: $trimmed');
      return trimmed.isEmpty ? 'No description generated.' : trimmed;
    } catch (e) {
      print('Error during Phi-3 generation: $e');
      rethrow;
    }
  }

  String _buildPrompt(String sceneInfo) {
    return '''You are a helpful assistant that describes scenes for blind users.
Scene data:
$sceneInfo

Provide a clear, concise description (2-3 sentences):''';
  }

  /// Locates the GGUF model in the app's documents directory.
  /// The user must manually place the model file there.
  Future<String> _prepareModelFile() async {
    final Directory supportDir = await getApplicationSupportDirectory();
    final String modelPath = p.join(supportDir.path, _modelFileName);

    final File modelFile = File(modelPath);
    if (!await modelFile.exists()) {
      throw Exception(
        'Model file not found at $modelPath.\n'
        'Please copy Phi-3-mini-4k-instruct-q4.gguf to this location.'
      );
    }

    print('Found GGUF model at $modelPath');
    return modelPath;
  }

  Future<void> dispose() async {
    if (_isInitialized) {
      try {
        await platform.invokeMethod('unloadModel');
      } catch (e) {
        print('Error unloading model: $e');
      }
    }
    _modelPath = null;
    _isInitialized = false;
  }
}
