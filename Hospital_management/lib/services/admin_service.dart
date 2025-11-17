import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Check if current user is admin
  static Future<bool> isAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return false;

      final data = doc.data();
      return data?['role'] == 'admin';
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  /// Get all doctors with their status
  static Future<List<Map<String, dynamic>>> getAllDoctors() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'doctor')
          .get();

      List<Map<String, dynamic>> doctors = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        doctors.add(data);
      }

      return doctors;
    } catch (e) {
      print('Error getting all doctors: $e');
      return [];
    }
  }

  /// Get all patients
  static Future<List<Map<String, dynamic>>> getAllPatients() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'patient')
          .get();

      List<Map<String, dynamic>> patients = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        patients.add(data);
      }

      return patients;
    } catch (e) {
      print('Error getting all patients: $e');
      return [];
    }
  }

  /// Get pending doctor approvals
  static Future<List<Map<String, dynamic>>> getPendingDoctors() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'doctor')
          .where('approvalStatus', isEqualTo: 'pending')
          .get();

      List<Map<String, dynamic>> pendingDoctors = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        pendingDoctors.add(data);
      }

      return pendingDoctors;
    } catch (e) {
      print('Error getting pending doctors: $e');
      return [];
    }
  }

  /// Approve doctor account
  static Future<bool> approveDoctorAccount(
    String doctorId,
    String reason,
  ) async {
    try {
      await _firestore.collection('users').doc(doctorId).update({
        'approvalStatus': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
        'approvalReason': reason,
        'isBlocked': false,
      });

      // Create notification for doctor in their subcollection
      await _firestore
          .collection('users')
          .doc(doctorId)
          .collection('notifications')
          .add({
            'type': 'account_approved',
            'title': 'Account Approved',
            'message':
                'Your doctor account has been approved. You can now login and use the app.',
            'body':
                'Your doctor account has been approved. You can now login and use the app.',
            'reason': reason,
            'createdAt': FieldValue.serverTimestamp(),
            'isRead': false,
            'read': false,
          });

      return true;
    } catch (e) {
      print('Error approving doctor account: $e');
      return false;
    }
  }

  /// Reject doctor account
  static Future<bool> rejectDoctorAccount(
    String doctorId,
    String reason,
  ) async {
    try {
      await _firestore.collection('users').doc(doctorId).update({
        'approvalStatus': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectionReason': reason,
        'isBlocked': true,
      });

      // Create notification for doctor in their subcollection
      await _firestore
          .collection('users')
          .doc(doctorId)
          .collection('notifications')
          .add({
            'type': 'account_rejected',
            'title': 'Account Rejected',
            'message': 'Your doctor account application has been rejected.',
            'body': 'Your doctor account application has been rejected.',
            'reason': reason,
            'createdAt': FieldValue.serverTimestamp(),
            'isRead': false,
            'read': false,
          });

      return true;
    } catch (e) {
      print('Error rejecting doctor account: $e');
      return false;
    }
  }

  /// Block/Unblock user
  static Future<bool> toggleUserBlock(
    String userId,
    bool block,
    String reason,
  ) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isBlocked': block,
        'blockReason': block ? reason : null,
        'blockedAt': block ? FieldValue.serverTimestamp() : null,
      });

      // Create notification in user's subcollection
      final message = block
          ? 'Your account has been blocked. Reason: $reason'
          : 'Your account has been unblocked. You can now use the app.';

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
            'type': block ? 'account_blocked' : 'account_unblocked',
            'title': block ? 'Account Blocked' : 'Account Unblocked',
            'message': message,
            'body': message,
            'createdAt': FieldValue.serverTimestamp(),
            'isRead': false,
            'read': false,
          });

      return true;
    } catch (e) {
      print('Error toggling user block: $e');
      return false;
    }
  }

  /// Delete user account
  static Future<bool> deleteUser(String userId) async {
    try {
      // Delete user document
      await _firestore.collection('users').doc(userId).delete();

      // Delete related appointments
      final appointments = await _firestore
          .collection('appointments')
          .where('patientId', isEqualTo: userId)
          .get();
      for (var doc in appointments.docs) {
        await doc.reference.delete();
      }

      // Delete related prescriptions
      final prescriptions = await _firestore
          .collection('prescriptions')
          .where('patientId', isEqualTo: userId)
          .get();
      for (var doc in prescriptions.docs) {
        await doc.reference.delete();
      }

      return true;
    } catch (e) {
      print('Error deleting user: $e');
      return false;
    }
  }

  /// Send announcement to all patients
  static Future<bool> sendAnnouncementToPatients(
    String title,
    String message,
  ) async {
    try {
      final patients = await getAllPatients();

      // Create announcement in announcements collection
      final announcementRef = await _firestore.collection('announcements').add({
        'title': title,
        'message': message,
        'targetRole': 'patient',
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': _auth.currentUser?.uid,
      });

      // Create individual notifications for each patient in their subcollection
      for (var patient in patients) {
        await _firestore
            .collection('users')
            .doc(patient['id'])
            .collection('notifications')
            .add({
              'type': 'announcement',
              'title': title,
              'message': message,
              'body': message, // For display in snackbar
              'announcementId': announcementRef.id,
              'createdAt': FieldValue.serverTimestamp(),
              'isRead': false,
              'read': false, // Both fields for compatibility
            });
      }

      return true;
    } catch (e) {
      print('Error sending announcement to patients: $e');
      return false;
    }
  }

  /// Send alert to all doctors
  static Future<bool> sendAlertToDoctors(String title, String message) async {
    try {
      final doctors = await getAllDoctors();

      // Create alert in announcements collection
      final alertRef = await _firestore.collection('announcements').add({
        'title': title,
        'message': message,
        'targetRole': 'doctor',
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': _auth.currentUser?.uid,
      });

      // Create individual notifications for each doctor in their subcollection
      for (var doctor in doctors) {
        await _firestore
            .collection('users')
            .doc(doctor['id'])
            .collection('notifications')
            .add({
              'type': 'alert',
              'title': title,
              'message': message,
              'body': message, // For display in snackbar
              'alertId': alertRef.id,
              'createdAt': FieldValue.serverTimestamp(),
              'isRead': false,
              'read': false, // Both fields for compatibility
            });
      }

      return true;
    } catch (e) {
      print('Error sending alert to doctors: $e');
      return false;
    }
  }

  /// Get all announcements
  static Future<List<Map<String, dynamic>>> getAllAnnouncements() async {
    try {
      final snapshot = await _firestore
          .collection('announcements')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting announcements: $e');
      return [];
    }
  }

  /// Get admin statistics
  static Future<Map<String, dynamic>> getAdminStats() async {
    try {
      final totalDoctors = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'doctor')
          .count()
          .get();

      final approvedDoctors = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'doctor')
          .where('approvalStatus', isEqualTo: 'approved')
          .count()
          .get();

      final pendingDoctors = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'doctor')
          .where('approvalStatus', isEqualTo: 'pending')
          .count()
          .get();

      final totalPatients = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'patient')
          .count()
          .get();

      final totalAppointments = await _firestore
          .collection('appointments')
          .count()
          .get();

      final blockedUsers = await _firestore
          .collection('users')
          .where('isBlocked', isEqualTo: true)
          .count()
          .get();

      return {
        'totalDoctors': totalDoctors.count,
        'approvedDoctors': approvedDoctors.count,
        'pendingDoctors': pendingDoctors.count,
        'totalPatients': totalPatients.count,
        'totalAppointments': totalAppointments.count,
        'blockedUsers': blockedUsers.count,
      };
    } catch (e) {
      print('Error getting admin stats: $e');
      return {
        'totalDoctors': 0,
        'approvedDoctors': 0,
        'pendingDoctors': 0,
        'totalPatients': 0,
        'totalAppointments': 0,
        'blockedUsers': 0,
      };
    }
  }

  /// Get user notifications
  static Stream<QuerySnapshot> getUserNotificationsStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();
  }

  /// Mark notification as read
  static Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }
}
