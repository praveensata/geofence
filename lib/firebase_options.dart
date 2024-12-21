// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCsHzr6HEaf0ox84bP2rRP6d4QGv7_J8nQ',
    appId: '1:747470021532:web:aaea1527fcb6eb8cad9e59',
    messagingSenderId: '747470021532',
    projectId: 'geofence-18f49',
    authDomain: 'geofence-18f49.firebaseapp.com',
    storageBucket: 'geofence-18f49.firebasestorage.app',
    measurementId: 'G-RQ2R020815',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDiBE1lTWJrp2uGC9jaNnEWcSceyB78CC4',
    appId: '1:747470021532:android:c3e4fc264758115aad9e59',
    messagingSenderId: '747470021532',
    projectId: 'geofence-18f49',
    storageBucket: 'geofence-18f49.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCnP73t7B_-ZIjDTZiQKErdmYaM5ugO1OA',
    appId: '1:747470021532:ios:9210b9a9873d71afad9e59',
    messagingSenderId: '747470021532',
    projectId: 'geofence-18f49',
    storageBucket: 'geofence-18f49.firebasestorage.app',
    iosBundleId: 'com.example.geofence',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCnP73t7B_-ZIjDTZiQKErdmYaM5ugO1OA',
    appId: '1:747470021532:ios:9210b9a9873d71afad9e59',
    messagingSenderId: '747470021532',
    projectId: 'geofence-18f49',
    storageBucket: 'geofence-18f49.firebasestorage.app',
    iosBundleId: 'com.example.geofence',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCsHzr6HEaf0ox84bP2rRP6d4QGv7_J8nQ',
    appId: '1:747470021532:web:f5b375ed3a4b9f0cad9e59',
    messagingSenderId: '747470021532',
    projectId: 'geofence-18f49',
    authDomain: 'geofence-18f49.firebaseapp.com',
    storageBucket: 'geofence-18f49.firebasestorage.app',
    measurementId: 'G-990ST4SKHQ',
  );
}
