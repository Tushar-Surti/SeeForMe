import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:seeforme/claude_service.dart';
import 'package:seeforme/camera_service.dart';
import 'package:seeforme/language_service.dart';
import 'package:seeforme/language_selector.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:volume_controller/volume_controller.dart';
import 'dart:async';
import 'package:flutter/rendering.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  File? image;
  String? description;
  bool isLoading = false;
  bool showDescription = false;
  final FlutterTts flutterTts = FlutterTts();
  final CameraService _cameraService = CameraService();
  String _currentLanguageCode = 'en-US';
  
  // Create a class-level instance of VolumeController
  final VolumeController _volumeController = VolumeController();
  
  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  
  // Animations
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    
    // Pulse animation for the loading indicator
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut)
    );
    
    // Fade animation for the description text
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn)
    );
    
    _animation = _fadeAnimation;
    
    // Slide animation for the image
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    // Set up camera callback
    _cameraService.setImageCapturedCallback(_handleImageCaptured);

    // Initialize the volume controller
    _initVolumeController();
    
    // Configure TTS with selected language
    _initTts();
    _configureTts();
    
    // Check if first launch to show language selection
    _checkFirstLaunch();
  }

  // Initialize volume controller and add listener
  void _initVolumeController() async {
    try {
      print("---------------------");
      print("Setting up volume button listener");

      // Get initial volume and log
      double? initialVolume = await _volumeController.getVolume();
      print("Initial volume set to: $initialVolume");
      
      double lastVolume = initialVolume ?? 0.5; // Default to 0.5 if null
      
      // Set up the listener with more sensitive detection
      _volumeController.listener((newVolume) {
        // Log the volume change for debugging
        print("Volume changed from $lastVolume to $newVolume");
        
        // Take a photo when volume changes
        if (newVolume != lastVolume) {
          print("Volume button press detected!");
          
          // Provide haptic feedback
          HapticFeedback.mediumImpact();
          
          // Show visual feedback
          ScaffoldMessenger.of(context).clearSnackBars(); // Clear any existing snackbars
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Volume button pressed - taking photo"),
              duration: Duration(milliseconds: 1000),
              backgroundColor: Color(0xFF6C63FF),
            ),
          );
          
          // Take a photo
          _startCamera();
          
          // Update the last volume for next detection
          lastVolume = newVolume;
        }
      });
      
      // Show a message about volume button usage
      Future.delayed(Duration(milliseconds: 1000), () {
        _showVolumeButtonInfo();
      });
      
      print("Volume button listener setup complete");
      print("---------------------");
    } catch (e) {
      print("Error initializing volume controller: $e");
    }
  }

  // Show info message about volume buttons
  void _showVolumeButtonInfo() {
    String message = "Press volume buttons to take a photo";
    
    // Get translation for common phrases based on language
    if (_currentLanguageCode.startsWith('hi')) {
      message = "फोटो लेने के लिए वॉल्यूम बटन दबाएं";
    } else if (_currentLanguageCode.startsWith('gu')) {
      message = "ફોટો લેવા માટે વોલ્યુમ બટન દબાવો";
    } else if (_currentLanguageCode.startsWith('bn')) {
      message = "ছবি তুলতে ভলিউম বাটন টিপুন";
    } else if (_currentLanguageCode.startsWith('ta')) {
      message = "படம் எடுக்க வால்யூம் பொத்தான்களை அழுத்தவும்";
    } else if (_currentLanguageCode.startsWith('te')) {
      message = "ఫోటో తీయడానికి వాల్యూమ్ బటన్‌లను నొక్కండి";
    } else if (_currentLanguageCode.startsWith('mr')) {
      message = "फोटो घेण्यासाठी व्हॉल्यूम बटणे दाबा";
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 3),
        backgroundColor: Color(0xFF3F3D9B),
      ),
    );
  }

  Future<void> _initTts() async {
    // Initialize TTS
    await flutterTts.setIosAudioCategory(
      IosTextToSpeechAudioCategory.playback, 
      [IosTextToSpeechAudioCategoryOptions.defaultToSpeaker]
    );
    
    // Get available languages from TTS engine
    var availableLanguages = await flutterTts.getLanguages;
    print("Available TTS Languages: $availableLanguages");
    
    // Get available voices
    var availableVoices = await flutterTts.getVoices;
    print("Available TTS Voices: $availableVoices");
  }

  Future<void> _checkFirstLaunch() async {
    if (await LanguageService.isFirstLaunch()) {
      // Small delay to ensure the UI is fully rendered
      Future.delayed(Duration(milliseconds: 500), () {
        LanguageService.showLanguageSelectionDialog(context);
      });
    }
  }

  Future<void> _configureTts() async {
    String languageCode = await LanguageService.getSelectedLanguageCode();
    
    // Save the current language code
    setState(() {
      _currentLanguageCode = languageCode;
    });
    
    // Configure TTS with explicit engine parameters
    await flutterTts.setLanguage(languageCode);
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(0.5); // Slower rate for better comprehension
    await flutterTts.setVolume(1.0);
    
    // Test if the language is supported
    var result = await flutterTts.isLanguageAvailable(languageCode);
    print("Language $languageCode available: $result");

    // Print the currently selected language
    print("Current language set to: $languageCode");
  }

  @override
  void dispose() {
    // Clean up volume controller
    _volumeController.removeListener();
    
    _pulseController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _cameraService.stopCamera();
    flutterTts.stop();
    super.dispose();
  }

  Future<void> _startCamera() async {
    try {
      String message = "Taking photo";
      
      // Get translation for common phrases based on language
      if (_currentLanguageCode.startsWith('hi')) {
        message = "फोटो ले रहा है";
      } else if (_currentLanguageCode.startsWith('gu')) {
        message = "ફોટો લઈ રહ્યા છે";
      } else if (_currentLanguageCode.startsWith('bn')) {
        message = "ছবি তুলছি";
      } else if (_currentLanguageCode.startsWith('ta')) {
        message = "புகைப்படம் எடுக்கிறது";
      } else if (_currentLanguageCode.startsWith('te')) {
        message = "ఫోటో తీస్తున్నారు";
      } else if (_currentLanguageCode.startsWith('mr')) {
        message = "फोटो घेत आहे";
      } else if (_currentLanguageCode.startsWith('kn')) {
        message = "ಫೋಟೋ ತೆಗೆದುಕೊಳ್ಳುತ್ತಿದೆ";
      } else if (_currentLanguageCode.startsWith('ml')) {
        message = "ഫോട്ടോ എടുക്കുന്നു";
      } else if (_currentLanguageCode.startsWith('pa')) {
        message = "ਫੋਟੋ ਲੈ ਰਿਹਾ ਹੈ";
      }
      
      await flutterTts.speak(message);
      await _cameraService.startCamera();
    } catch (e) {
      print("Error starting camera: $e");
      await flutterTts.speak("Error taking photo. Please try again.");
    }
  }

  void _handleImageCaptured(String imagePath) async {
    setState(() {
      image = File(imagePath);
      showDescription = false;
    });
    
    // Reset animations and play slide animation for new image
    _slideController.reset();
    _slideController.forward();
    
    // Add audio cue that photo was captured and analysis is starting
    String message = "Photo taken. Analyzing image.";
    
    // Get translation for common phrases based on language
    if (_currentLanguageCode.startsWith('hi')) {
      message = "फोटो ली गई। छवि का विश्लेषण किया जा रहा है।";
    } else if (_currentLanguageCode.startsWith('gu')) {
      message = "ફોટો લેવામાં આવ્યો. છબીનું વિશ્લેષણ કરી રહ્યા છીએ.";
    } else if (_currentLanguageCode.startsWith('bn')) {
      message = "ছবি তোলা হয়েছে। ছবি বিশ্লেষণ করা হচ্ছে।";
    } else if (_currentLanguageCode.startsWith('ta')) {
      message = "புகைப்படம் எடுக்கப்பட்டது. படத்தை பகுப்பாய்வு செய்கிறது.";
    } else if (_currentLanguageCode.startsWith('te')) {
      message = "ఫోటో తీసుకున్నారు. చిత్రాన్ని విశ్లేషిస్తోంది.";
    } else if (_currentLanguageCode.startsWith('mr')) {
      message = "फोटो घेतला. प्रतिमेचे विश्लेषण करत आहे.";
    } else if (_currentLanguageCode.startsWith('kn')) {
      message = "ಫೋಟೋ ತೆಗೆದುಕೊಂಡಿದೆ. ಚಿತ್ರವನ್ನು ವಿಶ್ಲೇಷಿಸಲಾಗುತ್ತಿದೆ.";
    } else if (_currentLanguageCode.startsWith('ml')) {
      message = "ഫോട്ടോ എടുത്തു. ചിത്രം വിശകലനം ചെയ്യുന്നു.";
    } else if (_currentLanguageCode.startsWith('pa')) {
      message = "ਫੋਟੋ ਲਈ ਗਈ। ਚਿੱਤਰ ਦਾ ਵਿਸ਼ਲੇਸ਼ਣ ਕੀਤਾ ਜਾ ਰਿਹਾ ਹੈ।";
    }
    
    await flutterTts.speak(message);
    await _analyzeImage();
  }
  
  Future<void> _analyzeImage() async {
    if (image == null) return;
    
    setState(() {
      isLoading = true;
      showDescription = false;
    });
    
    try {
      final result = await ClaudeService().analyzeImage(image!, languageCode: _currentLanguageCode);
      
      setState(() {
        description = result;
        isLoading = false;
        showDescription = true;
      });
      
      // Animate the description text appearing
      _fadeController.reset();
      _fadeController.forward();
      
      await _speak(result);
    } catch (e) {
      print("Error analyzing image: $e");
      setState(() {
        isLoading = false;
      });
      
      String errorMessage = "Sorry, I couldn't analyze that image. Please try again.";
      
      // Get translation for error message based on language
      if (_currentLanguageCode.startsWith('hi')) {
        errorMessage = "क्षमा करें, मैं उस छवि का विश्लेषण नहीं कर सका। कृपया पुनः प्रयास करें।";
      } else if (_currentLanguageCode.startsWith('gu')) {
        errorMessage = "માફ કરશો, હું તે છબીનું વિશ્લેષણ કરી શક્યો નથી. કૃપા કરીને ફરીથી પ્રયાસ કરો.";
      } else if (_currentLanguageCode.startsWith('bn')) {
        errorMessage = "দুঃখিত, আমি সেই ছবিটি বিশ্লেষণ করতে পারিনি। অনুগ্রহ করে আবার চেষ্টা করুন।";
      } else if (_currentLanguageCode.startsWith('ta')) {
        errorMessage = "மன்னிக்கவும், எனக்கு அந்த படத்தை பகுப்பாய்வு செய்ய முடியவில்லை. தயவுசெய்து மீண்டும் முயற்சிக்கவும்.";
      } else if (_currentLanguageCode.startsWith('te')) {
        errorMessage = "క్షమించండి, నేను ఆ చిత్రాన్ని విశ్లేషించలేకపోయాను. దయచేసి మళ్ళీ ప్రయత్నించండి.";
      } else if (_currentLanguageCode.startsWith('mr')) {
        errorMessage = "क्षमस्व, मला त्या प्रतिमेचे विश्लेषण करता आले नाही. कृपया पुन्हा प्रयत्न करा.";
      } else if (_currentLanguageCode.startsWith('kn')) {
        errorMessage = "ಕ್ಷಮಿಸಿ, ನಾನು ಆ ಚಿತ್ರವನ್ನು ವಿಶ್ಲೇಷಿಸಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.";
      } else if (_currentLanguageCode.startsWith('ml')) {
        errorMessage = "ക്ഷമിക്കണം, എനിക്ക് ആ ചിത്രം വിശകലനം ചെയ്യാൻ കഴിഞ്ഞില്ല. ദയവായി വീണ്ടും ശ്രമിക്കുക.";
      } else if (_currentLanguageCode.startsWith('pa')) {
        errorMessage = "ਮੁਆਫ ਕਰਨਾ, ਮੈਂ ਉਸ ਚਿੱਤਰ ਦਾ ਵਿਸ਼ਲੇਸ਼ਣ ਨਹੀਂ ਕਰ ਸਕਿਆ। ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।";
      }
      
      await flutterTts.speak(errorMessage);
    }
  }

  Future<void> _speak(String text) async {
    try {
      // Set language again to ensure it's using the right language
      await flutterTts.setLanguage(_currentLanguageCode);
      await flutterTts.setPitch(1.0);
      await flutterTts.setSpeechRate(0.5); // Slower rate for better comprehension
      
      print("Speaking in language: $_currentLanguageCode");
      
      // Break text into smaller chunks if it's too long
      if (text.length > 500) {
        List<String> textChunks = [];
        int chunkSize = 300;
        
        for (var i = 0; i < text.length; i += chunkSize) {
          int end = (i + chunkSize < text.length) ? i + chunkSize : text.length;
          // Try to end at a sentence or period
          if (end < text.length) {
            int periodIndex = text.lastIndexOf('.', end);
            if (periodIndex > i && periodIndex < end + 50) { // Look a bit further if needed
              end = periodIndex + 1;
            }
          }
          textChunks.add(text.substring(i, end));
        }
        
        for (var chunk in textChunks) {
          await flutterTts.speak(chunk);
          await Future.delayed(Duration(milliseconds: 500)); // Small pause between chunks
        }
      } else {
        await flutterTts.speak(text);
      }
    } catch (e) {
      print("Error in TTS: $e");
      // Fallback to English if there's an issue with the selected language
      await flutterTts.setLanguage("en-US");
      await flutterTts.speak("I'm having trouble with this language. Using English instead.");
      await flutterTts.speak(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _startCamera,
        backgroundColor: Color(0xFF6C63FF),
        child: Icon(Icons.camera_alt, color: Colors.white),
        tooltip: 'Take Photo',
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6C63FF), // Purple-blue
              Color(0xFF3F3D9B), // Deep blue
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          "SeeForMe",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(width: 10),
                        Icon(Icons.remove_red_eye, color: Colors.white, size: 28),
                      ],
                    ),
                    // Language selector
                    LanguageSelector(
                      onLanguageChanged: () async {
                        await _configureTts();
                        // Speak a confirmation in the new language
                        String message = "Language changed";
                        
                        // Get translation for language changed message
                        if (_currentLanguageCode.startsWith('hi')) {
                          message = "भाषा बदल गई है";
                        } else if (_currentLanguageCode.startsWith('gu')) {
                          message = "ભાષા બદલાઈ ગઈ છે";
                        } else if (_currentLanguageCode.startsWith('bn')) {
                          message = "ভাষা পরিবর্তন হয়েছে";
                        } else if (_currentLanguageCode.startsWith('ta')) {
                          message = "மொழி மாற்றப்பட்டது";
                        } else if (_currentLanguageCode.startsWith('te')) {
                          message = "భాష మారింది";
                        } else if (_currentLanguageCode.startsWith('mr')) {
                          message = "भाषा बदलली आहे";
                        } else if (_currentLanguageCode.startsWith('kn')) {
                          message = "ಭಾಷೆ ಬದಲಾಯಿಸಲಾಗಿದೆ";
                        } else if (_currentLanguageCode.startsWith('ml')) {
                          message = "ഭാഷ മാറ്റി";
                        } else if (_currentLanguageCode.startsWith('pa')) {
                          message = "ਭਾਸ਼ਾ ਬਦਲੀ ਗਈ ਹੈ";
                        }
                        
                        await flutterTts.speak(message);
                      },
                    ),
                  ],
                ),
              ),

              // Main Content
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: SingleChildScrollView(
                        physics: BouncingScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 30),

                              // Heading
                              Text(
                                "Let's see the world",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF3F3D9B),
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Take a photo to get a detailed description",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              SizedBox(height: 30),

                              // Image Container
                              Container(
                                height: 360,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0xFF6C63FF).withOpacity(0.2),
                                      spreadRadius: 2,
                                      blurRadius: 20,
                                      offset: Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      border: Border.all(
                                        color: Color(0xFF6C63FF).withOpacity(0.3),
                                        width: 2,
                                      ),
                                    ),
                                    child: image != null
                                        ? Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              Image.file(
                                                image!,
                                                fit: BoxFit.cover,
                                              ),
                                              if (isLoading)
                                                Container(
                                                  color: Colors.black.withOpacity(0.5),
                                                  child: Center(
                                                    child: Column(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        CircularProgressIndicator(
                                                          color: Colors.white,
                                                          strokeWidth: 3,
                                                        ),
                                                        SizedBox(height: 16),
                                                        Text(
                                                          "Analyzing...",
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 18,
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          )
                                        : Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.image_search_rounded,
                                                size: 80,
                                                color: Color(0xFF6C63FF).withOpacity(0.6),
                                              ),
                                              SizedBox(height: 16),
                                              Text(
                                                "Your image will appear here",
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                  color: Color(0xFF3F3D9B),
                                                ),
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                "Take a photo to get started",
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 30),

                              // Action Button
                              GestureDetector(
                                onTap: _startCamera,
                                child: Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFF6C63FF),
                                        Color(0xFF584BEA),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0xFF6C63FF).withOpacity(0.3),
                                        spreadRadius: 1,
                                        blurRadius: 8,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.camera_alt_rounded,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        "Take Photo",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: 30),

                              // Description
                              if (!isLoading && description != null)
                                FadeTransition(
                                  opacity: _animation,
                                  child: Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Colors.white,
                                          Color(0xFFF5F5FE),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.15),
                                          spreadRadius: 2,
                                          blurRadius: 15,
                                          offset: Offset(0, 5),
                                        ),
                                      ],
                                      border: Border.all(
                                        color: Color(0xFF6C63FF).withOpacity(0.2),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Color(0xFF6C63FF).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                Icons.auto_awesome,
                                                color: Color(0xFF6C63FF),
                                                size: 22,
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Text(
                                              "AI Description",
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF3F3D9B),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          description!,
                                          style: TextStyle(
                                            fontSize: 16,
                                            height: 1.6,
                                            color: Colors.grey.shade800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}