import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

/// Default [FirebaseOptions] for project: meet-marketers-ai (Number: 134038765566)
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
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC1cSq-lO0FHQCS2WC4ee50p6sK77E02n8',
    appId: '1:134038765566:web:b8126ba37b5e3520a7caaf',
    messagingSenderId: '134038765566',
    projectId: 'meet-marketers-ai',
    authDomain: 'meet-marketers-ai.firebaseapp.com',
    storageBucket: 'meet-marketers-ai.firebasestorage.app',
    measurementId: 'G-2RZYQSF057',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC1cSq-lO0FHQCS2WC4ee50p6sK77E02n8',
    appId: '1:134038765566:android:meet-marketers-ai',
    messagingSenderId: '134038765566',
    projectId: 'meet-marketers-ai',
    storageBucket: 'meet-marketers-ai.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC1cSq-lO0FHQCS2WC4ee50p6sK77E02n8',
    appId: '1:134038765566:ios:meet-marketers-ai',
    messagingSenderId: '134038765566',
    projectId: 'meet-marketers-ai',
    storageBucket: 'meet-marketers-ai.firebasestorage.app',
    iosBundleId: 'com.meetmarketers.ai',
  );
}
