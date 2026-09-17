// File generated for Firebase project: myvault-9d7f3 (abhimanyu.com)
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDmMl4y1OmXSSDhmhxM-cYnB-xAXg-sJ3s',
    appId: '1:438209489105:android:24f8630cce3933f509fdf0',
    messagingSenderId: '438209489105',
    projectId: 'myvault-9d7f3',
    storageBucket: 'myvault-9d7f3.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDmMl4y1OmXSSDhmhxM-cYnB-xAXg-sJ3s',
    appId: '1:438209489105:ios:24f8630cce3933f509fdf0',
    messagingSenderId: '438209489105',
    projectId: 'myvault-9d7f3',
    storageBucket: 'myvault-9d7f3.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDmMl4y1OmXSSDhmhxM-cYnB-xAXg-sJ3s',
    appId: '1:438209489105:web:24f8630cce3933f509fdf0',
    messagingSenderId: '438209489105',
    projectId: 'myvault-9d7f3',
    authDomain: 'myvault-9d7f3.firebaseapp.com',
    storageBucket: 'myvault-9d7f3.firebasestorage.app',
  );
}
