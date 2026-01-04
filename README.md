# 👁️ SeeForMe

> **Empowering independence for visually impaired individuals through real-time, multilingual scene understanding with audio feedback - now 100% offline!**

---

## 🌟 Overview

Visually impaired individuals often struggle to identify objects and navigate their surroundings independently.
While existing solutions exist, they are often:

* 🌐 Limited to **English only**
* ⚠️ Difficult to operate without visual interaction
* 🚫 Lacking **support for Indian languages**
* ❌ Not optimized for **simple, accessible controls**
* 🔌 **Require internet connectivity**
* 🔒 **Privacy concerns** with cloud-based processing

**SeeForMe** bridges this gap by providing:

✅ Real-time **object & scene recognition** using on-device AI
✅ **Audio feedback** in multiple Indian languages
✅ **Accessible navigation** via simple controls (like volume buttons)
✅ A **user-friendly mobile app** designed with inclusivity at its core
✅ **100% offline operation** - no internet required
✅ **Complete privacy** - all processing happens on your device

---

## 🎯 Key Features

* 🔍 **Object Detection & Scene Understanding** – AI-powered recognition using YOLO (80+ object classes)
* 🧠 **Spatial Awareness** – Understands object positions (left/right/center, near/far) and relationships
* 🗣️ **Multilingual Audio Output** – Support for 10 Indian languages + English
* 🎧 **Natural Language Descriptions** – Phi-3 LLM generates clear, spoken descriptions
* 🎛️ **Simple Controls** – Operate via volume buttons for hands-free accessibility
* 📱 **Mobile-first Design** – Optimized for Android devices
* 🔒 **Privacy-First** – All AI processing happens on-device, no data leaves your phone
* ✈️ **Works Offline** – No internet connection required

---

## 🏗️ Architecture

### Offline Processing Pipeline

```
Camera Frame
    ↓
YOLO Object Detection (TensorFlow Lite)
    ↓
Spatial Scene Analysis
    ↓
Phi-3 Mini LLM (Local Inference)
    ↓
Offline Translation (if needed)
    ↓
Text-to-Speech (Multi-language)
```

**All processing happens on your device!**

---

## 🛠️ Tech Stack

* **Computer Vision**: YOLOv5s FP16 (TensorFlow Lite)
* **Natural Language**: Phi-3 Mini (Quantized for mobile)
* **Languages**: Dart/Flutter for mobile app
* **Text-to-Speech (TTS)**: Native platform TTS engines
* **ML Framework**: TensorFlow Lite
* **Platform**: Android (iOS support available via Flutter)
* **Translation**: Offline dictionary-based translation

---

## 🌐 Supported Languages

* 🇬🇧 English (en)
* 🇮🇳 Hindi (hi)
* 🇮🇳 Gujarati (gu)
* 🇮🇳 Bengali (bn)
* 🇮🇳 Telugu (te)
* 🇮🇳 Tamil (ta)
* 🇮🇳 Marathi (mr)
* 🇮🇳 Kannada (kn)
* 🇮🇳 Malayalam (ml)
* 🇮🇳 Punjabi (pa)

---

## 📦 Installation & Setup

### Prerequisites
- Flutter SDK (latest stable version)
- Android Studio / Xcode (for mobile development)
- TensorFlow Lite models (see setup instructions below)

### Steps

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/SeeForMe.git
   cd SeeForMe
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Download AI models:**
   - See `assets/models/README.md` for detailed model download instructions
   - Required models:
     - `yolov5s-fp16.tflite` (~15-20 MB)
    - `phi3-mini.gguf` (~50-200 MB)
   - Place models in `assets/models/` directory

4. **Run the app:**
   ```bash
   flutter run
   ```

5. **Build release APK:**
   ```bash
   flutter build apk --release
   ```

For detailed setup and troubleshooting, see [OFFLINE_MIGRATION.md](OFFLINE_MIGRATION.md)

---

## 📸 App Screenshots

<!-- | Home Screen                      | Object Detection                      | Scene Description                 | Settings                             |
| -------------------------------- | ------------------------------------- | --------------------------------- | ------------------------------------ |
| ![Home](screenshots/screen1.png) | ![Detection](screenshots/screen2.png) | ![Scene](screenshots/screen3.png) | ![Settings](screenshots/screen4.png) | -->
<p align="center">
  <img src="screen1.png" width="100%" alt="Home Screen"/>
</p>

<p align="center">
  <img src="screen2.png" width="100%" alt="Object Detection"/>
</p>

<p align="center">
  <img src="screen3.png" width="100%" alt="Scene Description"/>
</p>
---

## 🛠️ Tech Stack

<!-- * **Computer Vision**: YOLOv8 / MobileNet (optimized for edge devices)
* **Languages**: Python, Java/Kotlin (for mobile integration)
* **Text-to-Speech (TTS)**: Google TTS / Open-source Indian language TTS engines
* **Frameworks**: TensorFlow Lite / ONNX Runtime
* **Platform**: Android (planned iOS support later) -->

---

## 🧑‍🤝‍🧑 Team & Credits

Developed with ❤️ to make technology more **inclusive** and **accessible**.

---

<!-- ## 📜 License

This project is licensed under the **MIT License** – feel free to use and improve it.

--- -->

✨ *“See the world, your way.”*

---

