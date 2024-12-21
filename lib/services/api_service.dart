import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

class ApiService {
  final logger = Logger();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> logAttendance(
      String userId, DateTime timestamp, bool isEntering) async {
    try {
      await _firestore.collection('attendance').add({
        'userId': userId,
        'timestamp': Timestamp.fromDate(timestamp),
        'isEntering': isEntering,
      });
      logger.i('Attendance logged successfully');
    } catch (e) {
      logger.e('Error logging attendance: $e');
    }
  }
}
