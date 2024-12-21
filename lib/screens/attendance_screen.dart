import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/api_service.dart';
import '../services/geofence_service.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final logger = Logger();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _user = FirebaseAuth.instance.currentUser;

  Future<void> _submitAttendance() async {
    if (_user == null) return;

    var status = await Permission.location.request();
    if (status.isGranted) {
      bool isWithinGeofence = await GeofenceService.isWithinGeofence();
      if (isWithinGeofence) {
        await ApiService().logAttendance(_user.uid, DateTime.now(), true);
        logger.i('Attendance logged');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You are present.')),
        );
      } else {
        await ApiService().logAttendance(_user.uid, DateTime.now(), false);
        logger.i('Attendance logged');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'You are outside the coordinates. Attendance marked as absent.')),
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
            ElevatedButton(
              onPressed: _submitAttendance,
              child: Text('Submit Attendance'),
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
