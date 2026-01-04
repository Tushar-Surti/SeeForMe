import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';

class LanguageService {
  static const String _languagePreferenceKey = 'selected_language';
  
  // Available languages with their TTS language codes
  static final Map<String, String> availableLanguages = {
    'English': 'en-US',
    'Hindi': 'hi-IN',
    'Bengali': 'bn-IN',
    'Telugu': 'te-IN',
    'Tamil': 'ta-IN',
    'Marathi': 'mr-IN',
    'Gujarati': 'gu-IN',
    'Kannada': 'kn-IN',
    'Malayalam': 'ml-IN',
    'Punjabi': 'pa-IN',
  };

  // Get the currently selected language
  static Future<String> getSelectedLanguage() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languagePreferenceKey) ?? 'English';
  }

  // Get the language code for TTS
  static Future<String> getSelectedLanguageCode() async {
    final language = await getSelectedLanguage();
    return availableLanguages[language] ?? 'en-US';
  }

  // Save the selected language
  static Future<void> setSelectedLanguage(String language) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languagePreferenceKey, language);
  }

  // Check if this is the first launch
  static Future<bool> isFirstLaunch() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return !prefs.containsKey(_languagePreferenceKey);
  }

  // Check if TTS language is supported on the device
  static Future<bool> isLanguageSupported(FlutterTts flutterTts, String languageCode) async {
    try {
      var available = await flutterTts.isLanguageAvailable(languageCode);
      return available;
    } catch (e) {
      print("Error checking language support: $e");
      return false;
    }
  }

  // Configure TTS with the selected language
  static Future<void> configureTts(FlutterTts flutterTts) async {
    final languageCode = await getSelectedLanguageCode();
    
    try {
      // Print available voices for debugging
      var voices = await flutterTts.getVoices;
      print("Available voices: $voices");
      
      // Print available languages for debugging
      var languages = await flutterTts.getLanguages;
      print("Available languages: $languages");
      
      // Check if the language is supported
      bool isSupported = await isLanguageSupported(flutterTts, languageCode);
      print("Language $languageCode supported: $isSupported");
      
      if (isSupported) {
        await flutterTts.setLanguage(languageCode);
      } else {
        // Try with just the language code (without region)
        String languageCodeOnly = languageCode.split('-')[0];
        bool isBasicSupported = await isLanguageSupported(flutterTts, languageCodeOnly);
        
        if (isBasicSupported) {
          await flutterTts.setLanguage(languageCodeOnly);
          print("Using basic language code: $languageCodeOnly");
        } else {
          // Fallback to English
          await flutterTts.setLanguage("en-US");
          print("Language not supported, falling back to English");
        }
      }
      
      // Set other TTS parameters
      await flutterTts.setPitch(1.0);
      await flutterTts.setSpeechRate(0.5); // Slower for better comprehension
      await flutterTts.setVolume(1.0);
    } catch (e) {
      print("Error configuring TTS: $e");
      // Fallback to English in case of error
      await flutterTts.setLanguage("en-US");
    }
  }

  // Show language selection dialog
  static Future<void> showLanguageSelectionDialog(BuildContext context) async {
    final currentLanguage = await getSelectedLanguage();
    String selectedLanguage = currentLanguage;
    final FlutterTts tempTts = FlutterTts(); // For testing language support
    
    // Get supported languages for highlighting
    Map<String, bool> supportedLanguages = {};
    for (var entry in availableLanguages.entries) {
      supportedLanguages[entry.key] = await isLanguageSupported(tempTts, entry.value);
    }
    
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Select Language',
            style: TextStyle(
              color: Color(0xFF3F3D9B),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: availableLanguages.length,
              itemBuilder: (context, index) {
                final language = availableLanguages.keys.elementAt(index);
                final isSupported = supportedLanguages[language] ?? false;
                
                return ListTile(
                  leading: Radio<String>(
                    value: language,
                    groupValue: selectedLanguage,
                    activeColor: const Color(0xFF6C63FF),
                    onChanged: (String? value) async {
                      if (value != null) {
                        selectedLanguage = value;
                        await setSelectedLanguage(value);
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                  title: Text(
                    language,
                    style: TextStyle(
                      color: isSupported ? Colors.black : Colors.grey,
                    ),
                  ),
                  subtitle: isSupported ? null : Text(
                    "May not be fully supported",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade800,
                    ),
                  ),
                  onTap: () async {
                    selectedLanguage = language;
                    await setSelectedLanguage(language);
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF6C63FF),
              ),
              child: const Text('Confirm'),
              onPressed: () async {
                await setSelectedLanguage(selectedLanguage);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
} 