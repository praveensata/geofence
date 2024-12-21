import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';

class GeofenceService {
  static const double geofenceRadius = 100; // in meters
  static const double collegeLatitude = 17.736803; // your latitude here
  static const double collegeLongitude = 83.333491; // your longitude here
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

  static Future<void> checkGeofence(Function onEnter, Function onExit) async {
    bool isWithin = await isWithinGeofence();
    if (isWithin) {
      onEnter();
    } else {
      await onExit(); // Await to handle asynchronous sign out
    }
  }

  static Future<void> startGeofencing(Function onEnter, Function onExit) async {
    Geolocator.getPositionStream(
      locationSettings:
          LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
    ).listen((Position position) {
      checkGeofence(onEnter, onExit);
    });
  }
}
