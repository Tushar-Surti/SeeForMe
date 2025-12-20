import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:seeforme/language_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ClaudeService {
  final String _baseUrl = 'https://api.anthropic.com/v1/messages';
  late final String _apiKey;

  ClaudeService() {
    _apiKey = dotenv.env['CLAUDE_API_KEY'] ?? '';
    if (_apiKey.isEmpty) {
      throw Exception('CLAUDE_API_KEY not found in .env file');
    }
  }

  // Language-specific prompts for image analysis
  final Map<String, String> _languagePrompts = {
    'en':
        "Please provide a detailed description of what you see in this image. Include any text, objects, people, or notable features that are visible. Be specific and thorough in your description. Use simple and clear language.",
    'hi':
        "कृपया इस छवि में आप जो देखते हैं उसका विस्तृत विवरण दें। किसी भी पाठ, वस्तुओं, लोगों या दिखाई देने वाली उल्लेखनीय विशेषताओं को शामिल करें। अपने विवरण में विशिष्ट और विस्तृत हों। सरल और स्पष्ट भाषा का उपयोग करें।",
    'gu':
        "કૃપા કરીને આ છબીમાં તમે જે જુઓ છો તેનું વિગતવાર વર્ણન આપો. કોઈપણ ટેક્સ્ટ, વસ્તુઓ, લોકો અથવા નોંધપાત્ર લક્ષણો કે જે દેખાય છે તે શામિલ કરો. તમારા વર્ણનમાં ચોક્કસ અને સંપૂર્ણ રહો. સરળ અને સ્પષ્ટ ભાષાનો ઉપયોગ કરો.",
    'bn':
        "অনুগ্রহ করে এই ছবিতে আপনি যা দেখেন তার বিস্তারিত বর্ণনা দিন। যে কোনো টেক্সট, বস্তু, ব্যক্তি বা উল্লেখযোগ্য বৈশিষ্ট্য অন্তর্ভুক্ত করুন যা দৃশ্যমান। আপনার বর্ণনায় নির্দিষ্ট এবং পূর্ণাঙ্গ হন। সহজ ও পরিষ্কার ভাষা ব্যবহার করুন।",
    'te':
        "దయచేసి ఈ చిత్రంలో మీరు చూసేదాని గురించి వివరణాత్మక వివరణను అందించండి. కనిపించే ఏదైనా వచనం, వస్తువులు, వ్యక్తులు లేదా గమనార్హమైన లక్షణాలను చేర్చండి. మీ వివరణలో నిర్దిష్టంగా మరియు సమగ్రంగా ఉండండి. సరళమైన మరియు స్పష్టమైన భాషను ఉపయోగించండి.",
    'ta':
        "இந்தப் படத்தில் நீங்கள் காண்பதை விரிவான விளக்கத்தை வழங்கவும். தெரியும் எந்த உரை, பொருட்கள், மக்கள் அல்லது குறிப்பிடத்தக்க அம்சங்களையும் சேர்க்கவும். உங்கள் விளக்கத்தில் குறிப்பிட்டதாகவும் முழுமையாகவும் இருங்கள். எளிய மற்றும் தெளிவான மொழியைப் பயன்படுத்துங்கள்.",
    'mr':
        "मराठीत उत्तर द्या. आपले उत्तर साधे, स्पष्ट आणि प्रतिमेत दिसणाऱ्या गोष्टींवर केंद्रित ठेवा. केवळ 3-5 वाक्ये वापरा. तांत्रिक शब्द टाळा आणि रोजच्या भाषेचा वापर करा.",
    'kn':
        "ಕನ್ನಡದಲ್ಲಿ ಉತ್ತರಿಸಿ. ನಿಮ್ಮ ಪ್ರತಿಕ್ರಿಯೆಯನ್ನು ಸರಳವಾಗಿ, ಸ್ಪಷ್ಟವಾಗಿ ಮತ್ತು ಚಿತ್ರದಲ್ಲಿ ಕಾಣುವ ವಿಷಯಗಳ ಮೇಲೆ ಕೇಂದ್ರೀಕರಿಸಿ. 3-5 ವಾಕ್ಯಗಳನ್ನು ಮಾತ್ರ ಬಳಸಿ. ತಾಂತ್ರಿಕ ಪದಗಳನ್ನು ತಪ್ಪಿಸಿ ಮತ್ತು ದೈನಂದಿನ ಭಾಷೆಯನ್ನು ಬಳಸಿ.",
    'ml':
        "മലയാളത്തിൽ മറുപടി നൽകുക. നിങ്ങളുടെ മറുപടി ലളിതവും വ്യക്തവും ചിത്രത്തിൽ കാണുന്ന കാര്യങ്ങളിൽ ശ്രദ്ധ കേന്ദ്രീകരിക്കുന്നതുമായിരിക്കണം. 3-5 വാക്യങ്ങൾ മാത്രം ഉപയോഗിക്കുക. സാങ്കേതിക പദങ്ങൾ ഒഴിവാക്കി നിത്യജീവിത ഭാഷ ഉപയോഗിക്കുക.",
    'pa':
        "ਪੰਜਾਬੀ ਵਿਚ ਜਵਾਬ ਦਿਓ। ਆਪਣੇ ਜਵਾਬ ਨੂੰ ਸਧਾਰਨ, ਸਪਸ਼ਟ ਅਤੇ ਤਸਵੀਰ ਵਿੱਚ ਦਿਖਾਈ ਦੇਣ ਵਾਲੀਆਂ ਚੀਜ਼ਾਂ 'ਤੇ ਕੇਂਦਰਿਤ ਰੱਖੋ। ਸਿਰਫ 3-5 ਵਾਕਾਂ ਦੀ ਵਰਤੋਂ ਕਰੋ। ਤਕਨੀਕੀ ਸ਼ਬਦਾਂ ਤੋਂ ਪਰਹੇਜ਼ ਕਰੋ ਅਤੇ ਰੋਜ਼ਾਨਾ ਭਾਸ਼ਾ ਦੀ ਵਰਤੋਂ ਕਰੋ।",
  };

  // Language to instruct Claude to respond in with specific instructions for quality
  final Map<String, String> _responseLanguages = {
    'en':
        "Respond in English. Keep your response simple, clear, and focused on what's visible in the image. Use 3-5 sentences only. Avoid technical terms and use everyday language.",
    'hi':
        "हिंदी में जवाब दें। अपने जवाब को सरल, स्पष्ट और छवि में दिखाई देने वाली चीजों पर केंद्रित रखें। केवल 3-5 वाक्यों का उपयोग करें। तकनीकी शब्दों से बचें और रोजमर्रा की भाषा का उपयोग करें।",
    'gu':
        "ગુજરાતીમાં જવાબ આપો. તમારો જવાબ સરળ, સ્પષ્ટ અને છબીમાં દૃશ્યમાન વસ્તુઓ પર કેન્દ્રિત રાખો. માત્ર 3-5 વાક્યોનો ઉપયોગ કરો. ટેકનિકલ શબ્દોથી દૂર રહો અને રોજિંદા ભાષાનો ઉપયોગ કરો.",
    'bn':
        "বাংলায় উত্তর দিন। আপনার উত্তর সহজ, পরিষ্কার এবং ছবিতে দৃশ্যমান বিষয়গুলিতে ফোকাস করুন। কেবল 3-5টি বাক্য ব্যবহার করুন। প্রযুক্তিগত শব্দ এড়িয়ে চলুন এবং প্রতিদিনের ভাষা ব্যবহার করুন।",
    'te':
        "తెలుగులో సమాధానం ఇవ్వండి. మీ సమాధానాన్ని సరళంగా, స్పష్టంగా మరియు చిత్రంలో కనిపించే వాటిపై దృష్టి పెట్టండి. 3-5 వాక్యాలను మాత్రమే ఉపయోగించండి. సాంకేతిక పదాలను నివారించండి మరియు రోజువారీ భాషను ఉపయోగించండి.",
    'ta':
        "இந்த படத்தில் ஏதோ தெரிகிறது. மேலும் தகவலுக்கு தயவுசெய்து மற்றொரு படத்தை எடுக்கவும்.",
    'mr':
        "या चित्रात काहीतरी दिसत आहे. अधिक माहितीसाठी कृपया आणखी एक फोटो घ्या.",
    'kn': "ಈ ಚಿತ್ರದಲ್ಲಿ ಏನೋ ಕಾಣುತ್ತಿದ್ದಾರೆ.",
    'ml':
        "ഈ ചിത്രത്തിൽ എന്തോ കാണുന്നു. കൂടുതൽ വിവരങ്ങൾക്ക് ദയവായി മറ്റൊരു ചിത്രം എടുക്കുക.",
    'pa':
        "ਇਸ ਤਸਵੀਰ ਵਿੱਚ ਕੁਝ ਦਿਖਾਈ ਦੇ ਰਿਹਾ ਹੈ। ਵਧੇਰੇ ਜਾਣਕਾਰੀ ਲਈ ਕਿਰਪਾ ਕਰਕੇ ਇੱਕ ਹੋਰ ਤਸਵੀਰ ਲਓ।",
  };

  // Quality assurance system prompt that works in all languages
  final String _systemPrompt =
      "You are a helpful assistant that describes images accurately and clearly for visually impaired users. Your description should be simple, direct, and focused only on what's clearly visible in the image. Keep your response to 3-5 sentences maximum. DO NOT include any sentences in English when asked to respond in another language. Never mix languages in your response. Use only standard characters of the requested language. DO NOT use special characters, markdown formatting, or unusual sequences like '^', '~', or repeated letters. Use only plain, simple text with standard punctuation.";

  Future<String> analyzeImage(File image,
      {String languageCode = 'en-US'}) async {
    try {
      // Extract base language code without region (e.g., 'en-US' -> 'en')
      String baseLanguage = languageCode.split('-')[0].toLowerCase();

      // Default to English if the language is not supported
      if (!_languagePrompts.containsKey(baseLanguage)) {
        baseLanguage = 'en';
      }

      // Log image details
      print('Image path: ${image.path}');
      print('Image exists: ${await image.exists()}');
      print('Original image size: ${await image.length()} bytes');
      print('Using language for Claude: $baseLanguage');

      // Read and decode the image
      final bytes = await image.readAsBytes();
      final decodedImage = img.decodeImage(bytes);

      if (decodedImage == null) {
        throw Exception('Failed to decode image');
      }

      // Calculate new dimensions while maintaining aspect ratio
      int maxDimension = 800; // Reduced max dimension for better performance
      int newWidth = decodedImage.width;
      int newHeight = decodedImage.height;

      if (decodedImage.width > maxDimension ||
          decodedImage.height > maxDimension) {
        if (decodedImage.width > decodedImage.height) {
          newWidth = maxDimension;
          newHeight =
              (decodedImage.height * maxDimension / decodedImage.width).round();
        } else {
          newHeight = maxDimension;
          newWidth =
              (decodedImage.width * maxDimension / decodedImage.height).round();
        }
      }

      // Resize the image
      final resizedImage = img.copyResize(
        decodedImage,
        width: newWidth,
        height: newHeight,
      );

      // Encode the resized image with compression
      final compressedBytes =
          img.encodeJpg(resizedImage, quality: 75); // Reduced quality
      print('Compressed image size: ${compressedBytes.length} bytes');

      final base64Image = base64Encode(compressedBytes);
      print('Base64 length: ${base64Image.length}');

      // Get prompt in the selected language
      String prompt = _languagePrompts[baseLanguage]!;
      String responseInstruction = _responseLanguages[baseLanguage]!;

      // Modified system prompt with language-specific instructions
      String languageSystemPrompt =
          "$_systemPrompt ${baseLanguage != 'en' ? 'IMPORTANT: Your ENTIRE response must be in the requested language only. DO NOT use any English words or phrases.' : ''}";

      // Add special instructions for Gujarati
      if (baseLanguage == 'gu') {
        languageSystemPrompt +=
            " For Gujarati language: Use only standard Gujarati Unicode characters (\\u0A80-\\u0AFF). DO NOT use Latin letters, special characters, or unusual encoding. Format all text in proper, valid Gujarati script only.";
      }

      // Combined prompt with stronger language instruction
      String combinedPrompt = "$prompt $responseInstruction";
      if (baseLanguage != 'en') {
        combinedPrompt +=
            " IMPORTANT: Your response must be COMPLETELY in the selected language ONLY, with NO English words. Use ONLY plain text without special formatting, symbols, or markdown.";

        // Add specific Gujarati instructions
        if (baseLanguage == 'gu') {
          combinedPrompt +=
              " કૃપા કરીને ફક્ત શુદ્ધ ગુજરાતી અક્ષરોનો ઉપયોગ કરો. અંગ્રેજી અક્ષરો અથવા વિશેષ ચિહ્નોનો ઉપયોગ ન કરો. ફક્ત સરળ ગુજરાતી વાક્યો લખો.";
        }
      } else {
        combinedPrompt +=
            " Use ONLY plain text without special formatting or unusual characters.";
      }

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          "model": "claude-3-opus-20240229",
          "max_tokens": 300, // Limit token count to ensure concise response
          "temperature":
              0.1, // Even lower temperature for more consistent responses
          "system": languageSystemPrompt, // Language-specific system prompt
          "messages": [
            {
              "role": "user",
              "content": [
                {
                  "type": "image",
                  "source": {
                    "type": "base64",
                    "media_type": "image/jpeg",
                    "data": base64Image,
                  },
                },
                {
                  "type": "text",
                  "text": combinedPrompt,
                },
              ],
            },
          ],
        }),
      );

      print('API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Explicitly decode the response bytes as UTF-8 before parsing JSON
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final responseText = data['content'][0]['text'];

        // Apply minimal cleaning to the response
        String cleanedResponse = _cleanResponse(responseText, baseLanguage);

        // Simply return the cleaned response without checking for "problematic" patterns
        return cleanedResponse;
      } else {
        print('API Response Body: ${response.body}');
        throw Exception(
          "Failed to analyze image: ${response.statusCode}",
        );
      }
    } catch (e, stackTrace) {
      print('Error in analyzeImage: $e');
      print('Stack trace: $stackTrace');

      // Return a simple error message instead of a fallback response
      return "No description available. Please try again.";
    }
  }

  // --- Minimal cleaning for all languages ---
  String _minimalClean(String response, String scriptPattern) {
    // Remove invisible characters, trim whitespace
    return response
        .replaceAll(RegExp(r'[\u200B-\u200F\u202A-\u202E\uFEFF]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _cleanResponse(String response, String languageCode) {
    // Use minimal cleaning for all languages
    String scriptPattern = '.'; // Default pattern that matches any character

    // Perform only minimal cleaning without filtering content
    String cleaned = _minimalClean(response, scriptPattern);

    // If the cleaned response is empty, return a minimal error message
    if (cleaned.isEmpty) {
      return "No description available.";
    }
    return cleaned;
  }
}
