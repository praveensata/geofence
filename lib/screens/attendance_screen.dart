import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/geofence_service.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  AttendanceScreenState createState() => AttendanceScreenState();
}

class AttendanceScreenState extends State<AttendanceScreen> {
  final logger = Logger();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _user = FirebaseAuth.instance.currentUser;
  bool _isPresent = false;
  bool _isGeofencingStarted = false;

  @override
  void initState() {
    super.initState();
    _checkGeofenceState();
  }

  Future<void> _checkGeofenceState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool geofenceActive = prefs.getBool('isGeofenceActive') ?? false;
    setState(() {
      _isPresent = false; // Set to false for testing
      _isGeofencingStarted = geofenceActive;
    });
    logger.i('Geofence active: $_isPresent'); // Add this log
  }

  void _startGeofencing() {
    GeofenceService.startGeofencing(_onEnterGeofence, _onExitGeofence);
    setState(() {
      _isGeofencingStarted = true;
    });
  }

  void _onEnterGeofence() {
    logger.i('Entered geofence');
    if (_user != null) {
      GeofenceService.logActivity(
          _user.uid, 'enter_geofence', 'User entered the geofence');
    }
  }

  void _onExitGeofence() {
    logger.i('Exited geofence');
    if (_user != null) {
      GeofenceService.logActivity(
          _user.uid, 'exit_geofence', 'User exited the geofence');
      if (mounted) {
        setState(() {
          _isPresent = false;
          _isGeofencingStarted = false;
        });
      }
      GeofenceService.notifyUserOnExit();
    }
  }

  Future<void> _submitAttendance() async {
    if (_user == null || _isPresent) return;

    var status = await Permission.location.request();
    if (!mounted) return;

    if (status.isGranted) {
      bool isWithinGeofence = await GeofenceService.isWithinGeofence();
      if (!mounted) return;

      if (isWithinGeofence) {
        await ApiService().logAttendance(_user.uid, DateTime.now(), true);
        logger.i('Attendance logged');
        GeofenceService.logActivity(_user.uid, 'submit_attendance',
            'User submitted attendance and is present within geofence');
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isGeofenceActive', true);
        _startGeofencing();
        setState(() {
          _isPresent = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You are present.')),
        );
      } else {
        logger.i('User is outside geofence');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'You are outside the geofence. You are marked as absent.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Location permissions are required to log attendance.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    logger
        .i('Building widget: isPresent=$_isPresent'); // Log state during build
    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance'),
        actions: [
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (!_isPresent) // Only show the button if user is not present
              ElevatedButton(
                onPressed: _submitAttendance,
                child: Text('Submit Attendance'),
              ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/dashboard');
              },
              child: Text('Go to Dashboard'),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('attendance')
                    .where('userId', isEqualTo: _user?.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final attendanceRecords = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: attendanceRecords.length,
                    itemBuilder: (context, index) {
                      final record = attendanceRecords[index];
                      final timestamp = record['timestamp'];
                      final isEntering = record['isEntering'];

                      DateTime dateTime;
                      if (timestamp is Timestamp) {
                        dateTime = timestamp.toDate();
                      } else if (timestamp is String) {
                        dateTime = DateTime.parse(timestamp);
                      } else {
                        dateTime = DateTime.now();
                      }

                      return ListTile(
                        title: Text('Time: ${dateTime.toString()}'),
                        subtitle: Text(isEntering ? 'Entered' : 'Exited'),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
