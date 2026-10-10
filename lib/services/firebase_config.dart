import 'package:firebase_core/firebase_core.dart';

class FirebaseConfig {
  // Replace these placeholders with your actual Firebase Web Config values from the Firebase Console
  static const FirebaseOptions currentPlatform = FirebaseOptions(
    apiKey: "YOUR_API_KEY",
    appId: "YOUR_APP_ID",
    messagingSenderId: "YOUR_SENDER_ID",
    projectId: "YOUR_PROJECT_ID",
    storageBucket: "YOUR_STORAGE_BUCKET",
  );

  // Checks if the configuration has been modified from the default placeholders
  static bool get isValid {
    return currentPlatform.apiKey != "YOUR_API_KEY";
  }
}
