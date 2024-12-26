import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:logger/logger.dart';
import 'services/geofence_service.dart';
import 'services/notification_service.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/attendance_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/admin_dashboard.dart';
import 'screens/dashboard_screen.dart'; // Import the new dashboard screen
import 'firebase_options.dart'; // Import Firebase options
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationService.initialize();

  var status = await Permission.location.request();
  if (status.isGranted) {
    GeofenceService.startGeofencing(onEnterGeofence, onExitGeofence);
  } else {
    // Handle the case when permissions are not granted
  }

  runApp(MyApp());
}

final logger = Logger();

void onEnterGeofence() {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    logger.i('Entered geofence');
    NotificationService.showNotification(
        'Geofence Alert', 'You have entered the geofence area.');
    ApiService().logAttendance(user.uid, DateTime.now(), true);
  }
}

Future<void> onExitGeofence() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    logger.i('Exited geofence');
    NotificationService.showNotification(
        'Geofence Alert', 'You have exited the geofence area.');
    await ApiService().logAttendance(user.uid, DateTime.now(), false);

    await FirebaseAuth.instance.signOut().then((_) {
      logger.i('User logged out automatically');
    });
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/attendance': (context) => AttendanceScreen(),
        '/profile': (context) => ProfileScreen(),
        '/admin': (context) => AdminDashboard(),
        '/dashboard': (context) => DashboardScreen(),
      },
    );
  }
}
