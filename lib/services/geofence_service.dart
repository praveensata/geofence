import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'notification_service.dart';

class GeofenceService {
  static const double geofenceRadius = 100.0; // in meters
  static const double collegeLatitude = 17.7292098; // your latitude here
  static const double collegeLongitude = 82.3786785; // your longitude here
  static final logger = Logger();
  static double totalDistance = 0.0; // Add a variable to track total distance

  static Future<void> startGeofencing(Function onEnter, Function onExit) async {
    Geolocator.getPositionStream(
      locationSettings:
          LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 50),
    ).listen((Position position) {
      _checkGeofence(position, onEnter, onExit);
      _trackDistance(position); // Track distance
    });
  }

  static Future<void> _checkGeofence(
      Position position, Function onEnter, Function onExit) async {
    double distance = Geolocator.distanceBetween(
      collegeLatitude,
      collegeLongitude,
      position.latitude,
      position.longitude,
    );
    if (distance <= geofenceRadius) {
      onEnter();
    } else {
      onExit();
    }
  }

  static Future<void> _trackDistance(Position position) async {
    Position? lastPosition;

    if (lastPosition != null) {
      double distance = Geolocator.distanceBetween(
        lastPosition.latitude,
        lastPosition.longitude,
        position.latitude,
        position.longitude,
      );
      totalDistance += distance;
      logger.i('Total Distance: $totalDistance meters');
    }

    lastPosition = position;
  }

  static Future<bool> isWithinGeofence() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      double distance = Geolocator.distanceBetween(
        collegeLatitude,
        collegeLongitude,
        position.latitude,
        position.longitude,
      );
      logger.i('Current Position: ${position.latitude}, ${position.longitude}');
      logger.i('Distance from Geofence Center: $distance meters');
      return distance <= geofenceRadius;
    } catch (e) {
      logger.e('Geofence check failed: $e');
      return false;
    }
  }

  static Future<void> logActivity(
      String authUserId, String activity, String description) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

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

      DocumentSnapshot userSnapshot =
          await firestore.collection('users').doc(authUserId).get();
      String customUserId = userSnapshot['customUserId'];
      String managerEmail = userSnapshot['managerEmail']; // Add manager email

      await firestore.collection('activity_logs').add({
        'userId': customUserId,
        'managerEmail': managerEmail, // Include manager email
        'timestamp': Timestamp.now(),
        'activity': activity,
        'description': description,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'deviceModel': deviceModel,
        'osVersion': osVersion,
      });

      // Send notification to manager
      if (managerEmail != null) {
        NotificationService.showNotification(
          'Geofence Alert',
          'Employee ${customUserId} has ${activity} the geofence area.',
        );
      }

      logger.i('Activity logged: $activity');
    } catch (e) {
      logger.e('Error logging activity: $e');
    }
  }

  static void onEnterGeofence() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      logger.i('Entered geofence');
      NotificationService.showNotification(
          'Geofence Alert', 'You have entered the geofence area.');
      logActivity(user.uid, 'ENTER', 'Entered geofence');
    }
  }

  static void onExitGeofence() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      logger.i('Exited geofence');
      NotificationService.showNotification(
          'Geofence Alert', 'You have exited the geofence area.');
      logActivity(user.uid, 'EXIT', 'Exited geofence');
    }
  }
}
