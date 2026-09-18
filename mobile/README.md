# ON MY WAY (OMW) — Native Flutter Mobile App 📱

Hyper-local peer-to-peer micro-mobility and campus favor escrow app engineered for **VIT Vellore Main Campus**.

---

## 📂 Mobile Architecture

```
mobile/
├── android/                         # Complete Native Android Host Scaffolding
│   ├── app/
│   │   ├── src/main/
│   │   │   ├── AndroidManifest.xml  # Internet permissions + singleTop intent
│   │   │   ├── kotlin/.../MainActivity.kt
│   │   │   └── res/values/styles.xml # Pure white launch splash
│   │   └── build.gradle             # minSdk 21, compileSdk 34
│   ├── build.gradle
│   └── settings.gradle
├── assets/
│   ├── images/
│   │   ├── logo_transparent.png     # Mascot icon (checkerboard removed)
│   │   └── mascot.svg               # Vector mascot
│   └── videos/
│       └── handwritten_onmyway.mp4  # Handwritten "On My Way" video
├── lib/
│   ├── main.dart                    # Root MaterialApp entrypoint
│   ├── screens/
│   │   └── auth_screen.dart         # Synchronized video+SVG intro & exact login screen
│   └── widgets/
│       └── google_button.dart       # 4-color Google G icon CustomPainter
└── pubspec.yaml                     # Dependencies (video_player, flutter_svg, google_sign_in, http)
```

---

## 🚀 Setup & Run Instructions

### 1. Flutter SDK Setup (Windows)
1. Extract the downloaded `flutter_windows_x.x.x-stable.zip` to `C:\src\flutter` (or any path without spaces/special chars).
2. Add `C:\src\flutter\bin` to your Windows User `Path` environment variable.
3. Open a new terminal and verify:
   ```powershell
   flutter doctor
   ```

### 2. Run the App
From the project root:
```powershell
cd mobile
flutter pub get
flutter run
```

### 3. Build APK for Android
To build a standalone APK to install directly on your phone:
```powershell
flutter build apk --release
```
The output `.apk` will be in:
`mobile/build/app/outputs/flutter-apk/app-release.apk`

---

## ⚡ Features Implemented in the App

1. **Synchronized Intro Animation:**
   - Starts on a clean `#ffffff` canvas.
   - Plays the self-drawing mascot line trace simultaneously with `handwritten_onmyway.mp4`.
   - Smooth 900ms cubic morph into the login screen.

2. **Wireframe Login Screen (Matching Figma / Mockup):**
   - Circular mascot logo at the top
   - "Create an account" headline
   - "Enter your email to sign up for this app" subtitle
   - Clean email input
   - Solid black "Continue" button
   - "or" divider
   - Official 4-color "Continue with Google" button
   - "Continue with Email" button
   - Terms & Privacy Policy footer

3. **Backend API Integration:**
   - Configured to point to the live cloud backend:
     `https://omw-jout.onrender.com/api`
   - Validates `@vitstudent.ac.in` email format (`name.surname2025@vitstudent.ac.in`).
   - Automatically parses student name, admission year, and academic standing (Freshman, Sophomore, Junior, Senior).
   - Credits the **20 non-cashable welcome airdrop tokens** upon new sign-up.
