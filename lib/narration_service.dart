import 'dart:io';
import 'yolo_service.dart';
import 'scene_analyzer.dart';
import 'phi3_service.dart';
import 'translator_service.dart';

class NarrationService {
  final YoloService _yoloService = YoloService();
  final SceneAnalyzer _sceneAnalyzer = SceneAnalyzer();
  final Phi3Service _phi3Service = Phi3Service();
  
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    print('Initializing offline narration pipeline...');
    
    try {
      // Initialize YOLO and Phi-3 in parallel
      await Future.wait([
        _yoloService.initialize(),
        _phi3Service.initialize(),
      ]);
      
      _isInitialized = true;
      print('Offline narration pipeline ready');
    } catch (e) {
      print('Error initializing narration service: $e');
      throw Exception('Failed to initialize narration service: $e');
    }
  }

  /// Generate narration for an image in the specified language
  /// Always generates in English first, then translates if needed
  Future<String> generateNarration(File imageFile, String languageCode) async {
    if (!_isInitialized) {
      print('>>> Narration service not initialized, initializing now...');
      await initialize();
    }

    try {
      print('>>> Starting offline narration pipeline...');
      
      // Step 1: YOLO object detection
      print('>>> Step 1: Running YOLO object detection...');
      List<DetectedObject> detections = await _yoloService.detectObjects(imageFile);
      print('>>> YOLO detected ${detections.length} objects');
      
      if (detections.isEmpty) {
        print('>>> No objects detected');
        String englishMessage = 'I cannot see any clear objects in this image. The view may be unclear or there may be nothing in frame.';
        return _translateIfNeeded(englishMessage, languageCode);
      }

      // Step 2: Spatial scene analysis
      print('>>> Step 2: Analyzing scene layout...');
      SceneAnalysis sceneAnalysis = _sceneAnalyzer.analyzeScene(detections);
      
      print('>>> Scene description: ${sceneAnalysis.sceneDescription}');

      // Step 3: Generate natural language with Phi-3
      print('>>> Step 3: Generating natural description with Phi-3...');
      String englishDescription = await _phi3Service.generateDescription(
        sceneAnalysis.sceneDescription
      );
      print('>>> Phi-3 generated: $englishDescription');

      // Step 4: Translate if not English
      print('>>> Step 4: Translating to target language...');
      String finalDescription = _translateIfNeeded(englishDescription, languageCode);

      print('>>> Final narration: $finalDescription');
      return finalDescription;
    } catch (e, stackTrace) {
      print('>>> ERROR generating narration: $e');
      print('>>> Stack trace: $stackTrace');
      
      // Fallback error message
      String errorMessage = 'Unable to analyze the image at this time.';
      return _translateIfNeeded(errorMessage, languageCode);
    }
  }

  String _translateIfNeeded(String englishText, String languageCode) {
    // Extract base language code
    String baseLanguage = languageCode.split('-')[0].toLowerCase();
    
    // If English, return as-is
    if (baseLanguage == 'en') {
      return englishText;
    }

    // Translate to target language
    return OfflineTranslator.translate(englishText, languageCode);
  }

  void dispose() {
    _yoloService.dispose();
    _phi3Service.dispose();
    _isInitialized = false;
  }
}
