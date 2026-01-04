class OfflineTranslator {
  // Translation dictionaries for common phrases
  // In production, this would use a proper offline translation model
  
  static final Map<String, Map<String, String>> _translations = {
    'hi': {
      // English to Hindi
      'I can see': 'मैं देख सकता हूं',
      'in this image': 'इस छवि में',
      'There is': 'यहाँ है',
      'on the left': 'बाईं ओर',
      'on the right': 'दाईं ओर',
      'in the center': 'केंद्र में',
      'close to the camera': 'कैमरे के पास',
      'in the distance': 'दूरी में',
      'at the top': 'शीर्ष पर',
      'at the bottom': 'नीचे',
      'next to': 'के बगल में',
      'in front of': 'के सामने',
      'blocking': 'अवरुद्ध कर रहा है',
      'person': 'व्यक्ति',
      'car': 'कार',
      'bicycle': 'साइकिल',
      'dog': 'कुत्ता',
      'cat': 'बिल्ली',
      'chair': 'कुर्सी',
      'table': 'मेज',
      'bottle': 'बोतल',
      'cup': 'कप',
      'book': 'किताब',
    },
    'gu': {
      // English to Gujarati
      'I can see': 'હું જોઈ શકું છું',
      'in this image': 'આ છબીમાં',
      'There is': 'ત્યાં છે',
      'on the left': 'ડાબી બાજુએ',
      'on the right': 'જમણી બાજુએ',
      'in the center': 'મધ્યમાં',
      'close to the camera': 'કેમેરાની નજીક',
      'in the distance': 'દૂર',
      'at the top': 'ટોચ પર',
      'at the bottom': 'નીચે',
      'next to': 'બાજુમાં',
      'in front of': 'સામે',
      'blocking': 'અવરોધ કરે છે',
      'person': 'વ્યક્તિ',
      'car': 'કાર',
      'bicycle': 'સાયકલ',
      'dog': 'કૂતરો',
      'cat': 'બિલાડી',
      'chair': 'ખુરશી',
      'table': 'ટેબલ',
      'bottle': 'બોટલ',
      'cup': 'કપ',
      'book': 'પુસ્તક',
    },
    'bn': {
      // English to Bengali
      'I can see': 'আমি দেখতে পাচ্ছি',
      'in this image': 'এই ছবিতে',
      'There is': 'আছে',
      'on the left': 'বাম দিকে',
      'on the right': 'ডান দিকে',
      'in the center': 'মাঝখানে',
      'close to the camera': 'ক্যামেরার কাছে',
      'in the distance': 'দূরে',
      'at the top': 'উপরে',
      'at the bottom': 'নিচে',
      'next to': 'পাশে',
      'in front of': 'সামনে',
      'blocking': 'আটকাচ্ছে',
      'person': 'ব্যক্তি',
      'car': 'গাড়ি',
      'bicycle': 'সাইকেল',
      'dog': 'কুকুর',
      'cat': 'বিড়াল',
      'chair': 'চেয়ার',
      'table': 'টেবিল',
      'bottle': 'বোতল',
      'cup': 'কাপ',
      'book': 'বই',
    },
    'te': {
      // English to Telugu
      'I can see': 'నేను చూడగలను',
      'in this image': 'ఈ చిత్రంలో',
      'There is': 'ఉంది',
      'on the left': 'ఎడమ వైపు',
      'on the right': 'కుడి వైపు',
      'in the center': 'మధ్యలో',
      'close to the camera': 'కెమెరాకు దగ్గరగా',
      'in the distance': 'దూరంలో',
      'at the top': 'పైన',
      'at the bottom': 'క్రింద',
      'next to': 'పక్కన',
      'in front of': 'ముందు',
      'blocking': 'అడ్డుకుంటోంది',
      'person': 'వ్యక్తి',
      'car': 'కారు',
      'bicycle': 'సైకిల్',
      'dog': 'కుక్క',
      'cat': 'పిల్లి',
      'chair': 'కుర్చీ',
      'table': 'టేబుల్',
      'bottle': 'సీసా',
      'cup': 'కప్పు',
      'book': 'పుస్తకం',
    },
    'ta': {
      // English to Tamil
      'I can see': 'நான் பார்க்க முடியும்',
      'in this image': 'இந்த படத்தில்',
      'There is': 'உள்ளது',
      'on the left': 'இடதுபுறம்',
      'on the right': 'வலதுபுறம்',
      'in the center': 'மையத்தில்',
      'close to the camera': 'கேமராவுக்கு அருகில்',
      'in the distance': 'தூரத்தில்',
      'at the top': 'மேலே',
      'at the bottom': 'கீழே',
      'next to': 'அடுத்து',
      'in front of': 'முன்',
      'blocking': 'தடுக்கிறது',
      'person': 'நபர்',
      'car': 'கார்',
      'bicycle': 'சைக்கிள்',
      'dog': 'நாய்',
      'cat': 'பூனை',
      'chair': 'நாற்காலி',
      'table': 'மேசை',
      'bottle': 'பாட்டில்',
      'cup': 'கப்',
      'book': 'புத்தகம்',
    },
    'mr': {
      // English to Marathi
      'I can see': 'मी पाहू शकतो',
      'in this image': 'या प्रतिमेत',
      'There is': 'आहे',
      'on the left': 'डावीकडे',
      'on the right': 'उजवीकडे',
      'in the center': 'मध्यभागी',
      'close to the camera': 'कॅमेर्याजवळ',
      'in the distance': 'दूर',
      'at the top': 'वर',
      'at the bottom': 'खाली',
      'next to': 'शेजारी',
      'in front of': 'समोर',
      'blocking': 'अवरोधित करत आहे',
      'person': 'व्यक्ती',
      'car': 'कार',
      'bicycle': 'सायकल',
      'dog': 'कुत्रा',
      'cat': 'मांजर',
      'chair': 'खुर्ची',
      'table': 'टेबल',
      'bottle': 'बाटली',
      'cup': 'कप',
      'book': 'पुस्तक',
    },
    'kn': {
      // English to Kannada
      'I can see': 'ನಾನು ನೋಡಬಲ್ಲೆ',
      'in this image': 'ಈ ಚಿತ್ರದಲ್ಲಿ',
      'There is': 'ಇದೆ',
      'on the left': 'ಎಡಭಾಗದಲ್ಲಿ',
      'on the right': 'ಬಲಭಾಗದಲ್ಲಿ',
      'in the center': 'ಮಧ್ಯದಲ್ಲಿ',
      'close to the camera': 'ಕ್ಯಾಮರಾಗೆ ಹತ್ತಿರ',
      'in the distance': 'ದೂರದಲ್ಲಿ',
      'at the top': 'ಮೇಲೆ',
      'at the bottom': 'ಕೆಳಗೆ',
      'next to': 'ಪಕ್ಕದಲ್ಲಿ',
      'in front of': 'ಮುಂದೆ',
      'blocking': 'ತಡೆಯುತ್ತಿದೆ',
      'person': 'ವ್ಯಕ್ತಿ',
      'car': 'ಕಾರು',
      'bicycle': 'ಸೈಕಲ್',
      'dog': 'ನಾಯಿ',
      'cat': 'ಬೆಕ್ಕು',
      'chair': 'ಕುರ್ಚಿ',
      'table': 'ಮೇಜು',
      'bottle': 'ಬಾಟಲಿ',
      'cup': 'ಕಪ್',
      'book': 'ಪುಸ್ತಕ',
    },
    'ml': {
      // English to Malayalam
      'I can see': 'എനിക്ക് കാണാൻ കഴിയും',
      'in this image': 'ഈ ചിത്രത്തിൽ',
      'There is': 'ഉണ്ട്',
      'on the left': 'ഇടതുവശത്ത്',
      'on the right': 'വലതുവശത്ത്',
      'in the center': 'നടുവിൽ',
      'close to the camera': 'ക്യാമറയോട് അടുത്ത്',
      'in the distance': 'ദൂരെ',
      'at the top': 'മുകളിൽ',
      'at the bottom': 'താഴെ',
      'next to': 'അടുത്ത്',
      'in front of': 'മുന്നിൽ',
      'blocking': 'തടയുന്നു',
      'person': 'വ്യക്തി',
      'car': 'കാർ',
      'bicycle': 'സൈക്കിൾ',
      'dog': 'നായ',
      'cat': 'പൂച്ച',
      'chair': 'കസേര',
      'table': 'മേശ',
      'bottle': 'കുപ്പി',
      'cup': 'കപ്പ്',
      'book': 'പുസ്തകം',
    },
    'pa': {
      // English to Punjabi
      'I can see': 'ਮੈਂ ਦੇਖ ਸਕਦਾ ਹਾਂ',
      'in this image': 'ਇਸ ਤਸਵੀਰ ਵਿੱਚ',
      'There is': 'ਹੈ',
      'on the left': 'ਖੱਬੇ ਪਾਸੇ',
      'on the right': 'ਸੱਜੇ ਪਾਸੇ',
      'in the center': 'ਕੇਂਦਰ ਵਿੱਚ',
      'close to the camera': 'ਕੈਮਰੇ ਦੇ ਨੇੜੇ',
      'in the distance': 'ਦੂਰੀ ਵਿੱਚ',
      'at the top': 'ਸਿਖਰ \'ਤੇ',
      'at the bottom': 'ਹੇਠਾਂ',
      'next to': 'ਅੱਗੇ',
      'in front of': 'ਸਾਮ੍ਹਣੇ',
      'blocking': 'ਰੋਕ ਰਿਹਾ ਹੈ',
      'person': 'ਵਿਅਕਤੀ',
      'car': 'ਕਾਰ',
      'bicycle': 'ਸਾਈਕਲ',
      'dog': 'ਕੁੱਤਾ',
      'cat': 'ਬਿੱਲੀ',
      'chair': 'ਕੁਰਸੀ',
      'table': 'ਮੇਜ਼',
      'bottle': 'ਬੋਤਲ',
      'cup': 'ਕੱਪ',
      'book': 'ਕਿਤਾਬ',
    },
  };

  static String translate(String text, String targetLanguageCode) {
    // Extract base language code (e.g., 'hi-IN' -> 'hi')
    String baseLanguage = targetLanguageCode.split('-')[0].toLowerCase();
    
    // If English or language not supported, return original
    if (baseLanguage == 'en' || !_translations.containsKey(baseLanguage)) {
      return text;
    }

    String translatedText = text;
    Map<String, String> languageDict = _translations[baseLanguage]!;
    
    // Replace phrases and words with translations
    // Sort by length descending to replace longer phrases first
    List<String> sortedKeys = languageDict.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    
    for (String englishPhrase in sortedKeys) {
      String translation = languageDict[englishPhrase]!;
      translatedText = translatedText.replaceAll(
        RegExp(englishPhrase, caseSensitive: false),
        translation,
      );
    }
    
    return translatedText;
  }

  static Future<String> translateAsync(String text, String targetLanguageCode) async {
    // Async version for future expansion with more complex translation models
    return translate(text, targetLanguageCode);
  }
}
