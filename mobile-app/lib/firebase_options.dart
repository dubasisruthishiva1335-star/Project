// File generated for Firebase project: myvault-9d7f3
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
    apiKey: 'AIzaSyA_myvault_9d7f3_android_client_key',
    appId: '1:104298172938:android:82390a8df9e82103',
    messagingSenderId: '104298172938',
    projectId: 'myvault-9d7f3',
    storageBucket: 'myvault-9d7f3.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA_myvault_9d7f3_ios_client_key',
    appId: '1:104298172938:ios:82390a8df9e82104',
    messagingSenderId: '104298172938',
    projectId: 'myvault-9d7f3',
    storageBucket: 'myvault-9d7f3.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA_myvault_9d7f3_web_client_key',
    appId: '1:104298172938:web:82390a8df9e82105',
    messagingSenderId: '104298172938',
    projectId: 'myvault-9d7f3',
    authDomain: 'myvault-9d7f3.firebaseapp.com',
    storageBucket: 'myvault-9d7f3.firebasestorage.app',
  );
}
