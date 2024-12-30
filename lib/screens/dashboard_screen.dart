import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:logger/logger.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  final User? _user = FirebaseAuth.instance.currentUser;
  Map<DateTime, List<String>> _attendanceEvents = {};
  List<Map<String, dynamic>> _recentActivityLogs = [];
  bool _isLoading = true;
  final logger = Logger();

  final CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (_user == null) {
      logger.e("User is null");
      return;
    }

    try {
      await _loadAttendanceData();
      await _loadActivityLogs();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      logger.e("Error loading data: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadAttendanceData() async {
    try {
      QuerySnapshot attendanceSnapshot = await FirebaseFirestore.instance
          .collection('attendance')
          .where('userId', isEqualTo: _user!.uid)
          .get();

      Map<DateTime, List<String>> attendanceEvents = {};

      for (var doc in attendanceSnapshot.docs) {
        DateTime date = (doc['timestamp'] as Timestamp).toDate();
        String status = doc['isEntering'] ? 'Present' : 'Absent';
        DateTime eventDate = DateTime(date.year, date.month, date.day);

        if (attendanceEvents[eventDate] == null) {
          attendanceEvents[eventDate] = [status];
        } else {
          attendanceEvents[eventDate]!.add(status);
        }
      }

      if (mounted) {
        setState(() {
          _attendanceEvents = attendanceEvents;
        });
      }
    } catch (e) {
      logger.e("Error loading attendance data: $e");
    }
  }

  Future<void> _loadActivityLogs() async {
    try {
      QuerySnapshot activitySnapshot = await FirebaseFirestore.instance
          .collection('activity_logs')
          .where('userId', isEqualTo: _user!.uid)
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      List<Map<String, dynamic>> activityLogs = [];

      for (var doc in activitySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        activityLogs.add(data);
      }

      if (mounted) {
        setState(() {
          _recentActivityLogs = activityLogs;
        });
      }
    } catch (e) {
      logger.e("Error loading activity logs: $e");
    }
  }

  List<String> getEventsForDay(DateTime day) {
    return _attendanceEvents[day] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Dashboard'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attendance Calendar',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16),
                    TableCalendar<String>(
                      focusedDay: _focusedDay,
                      firstDay: DateTime.utc(2000, 1, 1),
                      lastDay: DateTime.utc(2100, 12, 31),
                      calendarFormat: _calendarFormat,
                      selectedDayPredicate: (day) {
                        return isSameDay(_selectedDay, day);
                      },
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay =
                              focusedDay; // update `_focusedDay` here as well
                        });
                      },
                      eventLoader: getEventsForDay,
                      calendarStyle: CalendarStyle(
                        markersMaxCount: 1,
                        canMarkersOverflow: true,
                      ),
                      headerStyle: HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                      ),
                      startingDayOfWeek: StartingDayOfWeek.monday,
                      calendarBuilders: CalendarBuilders(
                        markerBuilder: (context, date, events) {
                          if (events.isNotEmpty) {
                            return Positioned(
                              right: 1,
                              bottom: 1,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.blue,
                                ),
                                width: 16.0,
                                height: 16.0,
                                child: Center(
                                  child: Text(
                                    '${events.length}',
                                    style: TextStyle().copyWith(
                                      color: Colors.white,
                                      fontSize: 12.0,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }
                          return SizedBox.shrink();
                        },
                      ),
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Geofence Entries/Exits Summary',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: _recentActivityLogs.length,
                      itemBuilder: (context, index) {
                        final log = _recentActivityLogs[index];
                        return ListTile(
                          title: Text(
                              '${log['activity']} - ${log['description']}'),
                          subtitle: Text(
                              'Timestamp: ${(log['timestamp'] as Timestamp).toDate()}'),
                          trailing: Text(
                              'Lat: ${log['latitude']}, Lng: ${log['longitude']}'),
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
