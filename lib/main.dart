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
import 'screens/dashboard_screen.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'services/api_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationService.initialize();

  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final Logger logger = Logger();

  var status = await Permission.location.request();
  if (status.isGranted) {
    GeofenceService.startGeofencing(onEnterGeofence, onExitGeofence);
  } else {
    // Handle the case when permissions are not granted
  }

  runApp(MyApp());

  // Ensure user data is set in Firestore when the app starts
  auth.authStateChanges().listen((User? user) async {
    if (user != null) {
      await _setUserData(user.uid);
    }
  });
}

Future<void> _setUserData(String userId) async {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final Logger logger = Logger();

  try {
    // Check if the document exists
    DocumentSnapshot userSnapshot =
        await firestore.collection('users').doc(userId).get();
    if (!userSnapshot.exists) {
      // Set initial user data
      await firestore.collection('users').doc(userId).set({
        'customUserId': 'user_custom_id_$userId', // Example custom user ID
        'managerEmail':
            'potti2255@gmail.com', // Your email address as manager email
        // Add other user fields if needed
      });
      logger.i('User data set for userId: $userId');
    } else {
      // Ensure managerEmail is set even if the document exists
      Map<String, dynamic> data = userSnapshot.data() as Map<String, dynamic>;
      if (!data.containsKey('managerEmail')) {
        await firestore.collection('users').doc(userId).update({
          'managerEmail':
              'potti2255@gmail.com', // Your email address as manager email
        });
        logger.i('managerEmail added for userId: $userId');
      }
    }
  } catch (e) {
    logger.e('Error setting user data: $e');
  }
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
