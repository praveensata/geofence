import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboard extends StatelessWidget {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Attendance Logs',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: firestore.collection('attendance').snapshots(),
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
                      final userId = record['userId'];
                      final isEntering = record['isEntering'];

                      return ListTile(
                        title: Text('User ID: $userId'),
                        subtitle: Text(
                            'Time: ${timestamp.toString()} - ${isEntering ? 'Entered' : 'Exited'}'),
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
