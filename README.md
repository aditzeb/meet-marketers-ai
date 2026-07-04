# Meet Marketers AI 🚀

An autonomous, end-to-end AI Marketing Agency Platform built with **Flutter Web**, **Firebase (Auth & Firestore)**, and **Google Cloud Vertex AI / Gemini 3.5 & 2.5 Flash**.

🌐 **Live Web Application**: [https://meet-marketers-ai.web.app](https://meet-marketers-ai.web.app)  
📦 **GitHub Repository**: [https://github.com/aditzeb/meet-marketers-ai.git](https://github.com/aditzeb/meet-marketers-ai.git)

---

## 🌟 Key Features

### 1. 💼 Client Portfolio & Workspace Management
- Direct **Firestore** database connection with dual-root collection indexing (`/account_managers/{uid}/clients` & `/clients`).
- Interactive client roster management with **Delete Client Workspace** confirmation dialogs.
- Active workspace isolation across all campaign stages.

### 2. 🎯 Strategy Hub (Phase 2)
- **AI-Powered 2×2 SWOT Matrix**: Dynamic strategic analysis with custom factor additions.
- **Interactive Social Media Content Calendar**: Weekly planner grid with platform chips (*LinkedIn, Instagram, Twitter / X, YouTube, Facebook*) and custom event scheduling dialog.
- **SEO Keyword Research & Target Personas**: Search volume metrics, difficulty scoring, and buyer persona profiling.

### 3. 🎬 Content Studio & Media Generation (Phase 3A)
- **Multi-Format Deliverable Generation**: Video Scripts, High-Converting Ad Copy, Design Briefs, Social Posts, Email Sequences, and Press Releases.
- **Real-Time Dynamic AI Image Generation**: Dynamic 8K commercial photography synthesis powered by Gemini / Vertex AI & Flux engines.
- **Browser-Compliant HTML5 Video Engine**: Interactive video player with CORS-enabled MP4 streaming and interactive play/unmute overlays.
- **1-Click Web File Downloader**: Native HTML anchor triggers for instant browser downloads of generated 8K photos (`.jpg`) and video renders (`.mp4`).

### 4. ✅ Vetting & Campaign Review (Phase 4)
- AM editor split-screen buffer for fine-tuning AI-generated outputs before approval.
- One-click campaign locking and JSON deliverable exporting.

---

## 🛠️ Tech Stack & Architecture

- **Frontend Framework**: Flutter Web (Dart) with ClinicSage Design System
- **State Management**: Flutter Riverpod
- **Backend & Cloud**: Firebase Auth & Cloud Firestore
- **AI Models**: Gemini 3.5 Flash, Gemini 2.5 Flash, Gemini 2.0 Flash, Vertex AI Media Engine
- **Hosting**: Firebase Hosting (`meet-marketers-ai.web.app`)

---

## 🚀 Local Setup & Installation

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.19.0 or higher)
- [Git](https://git-scm.com/)

### 1. Clone Repository
```bash
git clone https://github.com/aditzeb/meet-marketers-ai.git
cd meet_marketers_ai
```

### 2. Configure Local Secret Keys (`app_config.dart`)
Copy the provided template configuration file and add your Gemini API Key:

```bash
cp lib/core/config/app_config.example.dart lib/core/config/app_config.dart
```

Edit `lib/core/config/app_config.dart`:
```dart
class AppConfig {
  static const String geminiApiKey = 'YOUR_GEMINI_API_KEY_HERE';
}
```
> 🔒 Note: `lib/core/config/app_config.dart` is excluded from git tracking via `.gitignore` to keep API keys safe for public view.

### 3. Install Dependencies & Run
```bash
flutter pub get
flutter run -d chrome
```

---

## 📦 Building & Deploying to Firebase Hosting

### Build Production Bundle
```bash
flutter build web --no-pub
```

### Deploy to Firebase
```bash
npx firebase-tools deploy --only hosting --project meet-marketers-ai
```

---

## 📄 License
This project is licensed under the MIT License.
