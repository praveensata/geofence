import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import 'add_user_dialog.dart'; // Import the Add User Dialog

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger logger = Logger();
  bool _isLoading = true;
  final List<Map<String, dynamic>> _users = [];
  final List<Map<String, dynamic>> _attendanceStats = [];
  final List<Map<String, dynamic>> _geofenceActivity = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadUsers();
    await _loadAttendanceStats();
    await _loadGeofenceActivity();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadUsers() async {
    QuerySnapshot userSnapshot = await _firestore.collection('users').get();
    List<Map<String, dynamic>> users = userSnapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id; // Add user ID to the data map
      return data;
    }).toList();
    setState(() {
      _users.clear();
      _users.addAll(users);
    });
  }

  Future<void> _loadAttendanceStats() async {
    QuerySnapshot attendanceSnapshot =
        await _firestore.collection('attendance').get();
    List<Map<String, dynamic>> attendanceStats =
        attendanceSnapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id; // Add attendance ID to the data map
      return data;
    }).toList();
    setState(() {
      _attendanceStats.clear();
      _attendanceStats.addAll(attendanceStats);
    });
  }

  Future<void> _loadGeofenceActivity() async {
    QuerySnapshot geofenceSnapshot =
        await _firestore.collection('geofenceActivity').get();
    List<Map<String, dynamic>> geofenceActivity =
        geofenceSnapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id; // Add geofence activity ID to the data map
      return data;
    }).toList();
    setState(() {
      _geofenceActivity.clear();
      _geofenceActivity.addAll(geofenceActivity);
    });
  }

  Future<void> _addUser(Map<String, dynamic> userData) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: userData['email'],
        password: userData['password'],
      );

      String customUserId =
          userData['customUserId']; // Custom user ID from the dialog

      await _firestore.collection('users').doc(customUserId).set({
        'customUserId': customUserId, // Store the custom user ID
        'email': userData['email'],
        'role': userData['role'],
      });
      _loadUsers();
    } catch (e) {
      logger.e("Error adding user: $e");
    }
  }

  Future<void> _editUser(
      String userId, Map<String, dynamic> updatedData) async {
    try {
      await _firestore.collection('users').doc(userId).update(updatedData);
      _loadUsers();
    } catch (e) {
      logger.e("Error editing user: $e");
    }
  }

  Future<void> _removeUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
      _loadUsers();
    } catch (e) {
      logger.e("Error removing user: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'User Management',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AddUserDialog(
                                  onAddUser: _addUser,
                                );
                              },
                            );
                          },
                          child: Text('Add User'),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        return ListTile(
                          title: Text(user['email']),
                          subtitle: Text('Role: ${user['role']}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit),
                                onPressed: () {
                                  // Implement edit functionality
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () {
                                  _removeUser(user['id']);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Attendance Statistics',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: _attendanceStats.length,
                      itemBuilder: (context, index) {
                        final stats = _attendanceStats[index];
                        return ListTile(
                          title: Text('User ID: ${stats['userId']}'),
                          subtitle: Text(
                              'Status: ${stats['status']} at ${(stats['timestamp'] as Timestamp).toDate()}'),
                        );
                      },
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Geofence Activity',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: _geofenceActivity.length,
                      itemBuilder: (context, index) {
                        final activity = _geofenceActivity[index];
                        return ListTile(
                          title: Text('User ID: ${activity['userId']}'),
                          subtitle: Text(
                              '${activity['activity']} at ${(activity['timestamp'] as Timestamp).toDate()}'),
                          trailing: Text(
                              'Lat: ${activity['latitude']}, Lng: ${activity['longitude']}'),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
