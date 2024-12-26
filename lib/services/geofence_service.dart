import 'dart:io'; // Add this line
import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';

class GeofenceService {
  static const double geofenceRadius = 100.0; // in meters
  static const double collegeLatitude = 17.7292098; // your latitude here
  static const double collegeLongitude = 82.3786785; // your longitude here
  static final logger = Logger();

  static Future<bool> isWithinGeofence() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
      );
      double distance = Geolocator.distanceBetween(
        collegeLatitude,
        collegeLongitude,
        position.latitude,
        position.longitude,
      );
      logger.i('Current Position: ${position.latitude}, ${position.longitude}');
      logger.i('Distance from Geofence Center: $distance meters');
      logger.i('Geofence Radius: $geofenceRadius meters');
      return distance <= geofenceRadius;
    } catch (e) {
      logger.e('Geofence check failed: $e');
      return false;
    }
  }

  static void checkGeofence(Function onEnter, Function onExit) async {
    bool isWithin = await isWithinGeofence();
    if (isWithin) {
      onEnter();
    } else {
      onExit();
    }
  }

  static Future<void> startGeofencing(Function onEnter, Function onExit) async {
    Geolocator.getPositionStream(
      locationSettings:
          LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 50),
    ).listen((Position position) {
      checkGeofence(onEnter, onExit);
    });
  }

  static Future<void> logActivity(
      String userId, String activity, String description) async {
    final logger = Logger();
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    try {
      // Get location coordinates
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
      );

      // Get device details
      String deviceModel = '';
      String osVersion = '';

      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceModel = androidInfo.model ?? '';
        osVersion = androidInfo.version.release ?? '';
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceModel = iosInfo.name ?? '';
        osVersion = iosInfo.systemVersion ?? '';
      }

      await _firestore.collection('activity_logs').add({
        'userId': userId,
        'timestamp': Timestamp.now(),
        'activity': activity,
        'description': description,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'deviceModel': deviceModel,
        'osVersion': osVersion,
      });
      logger.i('Activity logged: $activity');
    } catch (e) {
      logger.e('Error logging activity: $e');
    }
  }
}
