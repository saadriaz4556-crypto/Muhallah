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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

//These are just your Firebase keys for each platform.
//This info comes from Firebase console or FlutterFire CLI.
//Your app sends these keys to Firebase so Firebase knows:
//which project you are using
//how to store your data
//how to authenticate users
//how to send messages
//how to upload files

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBftGlQSTEurzcX-OeKgQuVyne91D_tN14',
    appId: '1:496013462528:web:84f32c8b30e820cd48dce5',
    messagingSenderId: '496013462528',
    projectId: 'digitalmohallah-f91c6',
    authDomain: 'digitalmohallah-f91c6.firebaseapp.com',
    storageBucket: 'digitalmohallah-f91c6.firebasestorage.app',
    measurementId: 'G-YP3D5HX0MC',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC1rNxUVASiWgvT5KamJx8AxTJK4g7ZxzU',
    appId: '1:496013462528:android:0930460018fb705448dce5',
    messagingSenderId: '496013462528',
    projectId: 'digitalmohallah-f91c6',
    storageBucket: 'digitalmohallah-f91c6.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA10VApJ-V_L9CRtJwZJ07Lmdha3fflmmk',
    appId: '1:496013462528:ios:213c042e22160b8948dce5',
    messagingSenderId: '496013462528',
    projectId: 'digitalmohallah-f91c6',
    storageBucket: 'digitalmohallah-f91c6.firebasestorage.app',
    iosBundleId: 'com.example.muhallah',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyA10VApJ-V_L9CRtJwZJ07Lmdha3fflmmk',
    appId: '1:496013462528:ios:213c042e22160b8948dce5',
    messagingSenderId: '496013462528',
    projectId: 'digitalmohallah-f91c6',
    storageBucket: 'digitalmohallah-f91c6.firebasestorage.app',
    iosBundleId: 'com.example.muhallah',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBftGlQSTEurzcX-OeKgQuVyne91D_tN14',
    appId: '1:496013462528:web:84f32c8b30e820cd48dce5',
    messagingSenderId: '496013462528',
    projectId: 'digitalmohallah-f91c6',
    authDomain: 'digitalmohallah-f91c6.firebaseapp.com',
    storageBucket: 'digitalmohallah-f91c6.firebasestorage.app',
    measurementId: 'G-YP3D5HX0MC',
  );
}
