import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatelessWidget {
  final User? user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${user?.displayName ?? "N/A"}',
                style: TextStyle(fontSize: 18)),
            Text('Email: ${user?.email ?? "N/A"}',
                style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            Text('Attendance Logs',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: firestore
                    .collection('attendance')
                    .where('userId', isEqualTo: user?.uid)
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
                      final timestamp =
                          (record['timestamp'] as Timestamp).toDate();
                      final isEntering = record['isEntering'];

                      return ListTile(
                        title: Text('Time: ${timestamp.toString()}'),
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
