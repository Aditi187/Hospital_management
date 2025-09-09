import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? user;
  List<Map<String, dynamic>> appointments = [];

  @override
  void initState() {
    super.initState();
    user = _auth.currentUser;
    fetchAppointments();
  }

  Future<void> fetchAppointments() async {
    if (user == null) return;
    final snapshot = await _firestore
        .collection('patients')
        .doc(user!.uid)
        .collection('appointments')
        .get();

    setState(() {
      appointments = snapshot.docs
          .map((doc) => {"id": doc.id, ...doc.data()})
          .toList();
    });
  }

  void logout() async {
    await _auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Patient Dashboard"),
        actions: [
          IconButton(onPressed: logout, icon: const Icon(Icons.logout))
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Welcome, ${user?.displayName ?? user?.email}"),
            Text("Your UID: ${user?.uid}"),
            const SizedBox(height: 20),
            const Text(
              "Appointments:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            appointments.isEmpty
                ? const Text("No appointments yet.")
                : Expanded(
                    child: ListView.builder(
                      itemCount: appointments.length,
                      itemBuilder: (context, index) {
                        final appt = appointments[index];
                        return ListTile(
                          title: Text("${appt['doctor']}"),
                          subtitle: Text(
                              "${appt['date']} at ${appt['time']} (${appt['status']})"),
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
