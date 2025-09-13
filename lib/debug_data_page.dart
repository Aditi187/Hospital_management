import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DebugDataPage extends StatelessWidget {
  const DebugDataPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Data'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('User ID: ${currentUser?.uid ?? "Not logged in"}'),
            Text('User Email: ${currentUser?.email ?? "No email"}'),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () => _testFirestoreConnection(context),
              child: const Text('Test Firestore Connection'),
            ),
            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () => _addSimpleAppointment(context, currentUser?.uid),
              child: const Text('Add Simple Appointment'),
            ),
            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () => _listAllAppointments(context, currentUser?.uid),
              child: const Text('List All Appointments'),
            ),
            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () =>
                  _addSimpleMedicalReport(context, currentUser?.uid),
              child: const Text('Add Simple Medical Report'),
            ),
            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () =>
                  _listAllMedicalReports(context, currentUser?.uid),
              child: const Text('List All Medical Reports'),
            ),
            const SizedBox(height: 20),

            const Text('Debug Output will appear in console'),
          ],
        ),
      ),
    );
  }

  void _testFirestoreConnection(BuildContext context) async {
    try {
      print('Testing Firestore connection...');

      // Test write
      await FirebaseFirestore.instance.collection('test').add({
        'timestamp': FieldValue.serverTimestamp(),
        'message': 'Test connection',
      });

      print('✅ Firestore write test successful');

      // Test read
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('test')
          .limit(1)
          .get();
      print(
        '✅ Firestore read test successful. Found ${snapshot.docs.length} documents',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Firestore connection successful!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('❌ Firestore connection failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Firestore connection failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _addSimpleAppointment(BuildContext context, String? userId) async {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not logged in'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      print('Adding simple appointment for user: $userId');

      final appointmentData = {
        'patientId': userId,
        'specialty': 'General Medicine',
        'date': Timestamp.fromDate(DateTime.now().add(const Duration(days: 1))),
        'timeSlot': '10:00 AM',
        'symptoms': 'Test appointment',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      };

      DocumentReference docRef = await FirebaseFirestore.instance
          .collection('appointments')
          .add(appointmentData);

      print('✅ Simple appointment added with ID: ${docRef.id}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Simple appointment added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('❌ Error adding simple appointment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding appointment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _listAllAppointments(BuildContext context, String? userId) async {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not logged in'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      print('Listing appointments for user: $userId');

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .where('patientId', isEqualTo: userId)
          .get();

      print('✅ Found ${snapshot.docs.length} appointments for user $userId');

      for (var doc in snapshot.docs) {
        print('Appointment ID: ${doc.id}, Data: ${doc.data()}');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Found ${snapshot.docs.length} appointments (check console)',
          ),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      print('❌ Error listing appointments: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error listing appointments: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _addSimpleMedicalReport(BuildContext context, String? userId) async {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not logged in'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      print('Adding simple medical report for user: $userId');

      final reportData = {
        'patientId': userId,
        'reportType': 'Blood Test',
        'date': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 1)),
        ),
        'doctorName': 'Dr. Test',
        'diagnosis': 'Normal results',
        'createdAt': FieldValue.serverTimestamp(),
      };

      DocumentReference docRef = await FirebaseFirestore.instance
          .collection('medical_reports')
          .add(reportData);

      print('✅ Simple medical report added with ID: ${docRef.id}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Simple medical report added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('❌ Error adding simple medical report: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding medical report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _listAllMedicalReports(BuildContext context, String? userId) async {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not logged in'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      print('Listing medical reports for user: $userId');

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('medical_reports')
          .where('patientId', isEqualTo: userId)
          .get();

      print('✅ Found ${snapshot.docs.length} medical reports for user $userId');

      for (var doc in snapshot.docs) {
        print('Medical Report ID: ${doc.id}, Data: ${doc.data()}');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Found ${snapshot.docs.length} medical reports (check console)',
          ),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      print('❌ Error listing medical reports: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error listing medical reports: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
