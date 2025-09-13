import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Abstract base class for profile sections
abstract class ProfileSection {
  String get title;
  IconData get icon;
  Color get color;
  Widget buildContent(BuildContext context, Map<String, dynamic> userData);
}

// Insurance Information Section
class InsuranceInformationSection extends ProfileSection {
  @override
  String get title => 'Insurance Information';
  @override
  IconData get icon => Icons.shield;
  @override
  Color get color => Colors.green;

  @override
  Widget buildContent(BuildContext context, Map<String, dynamic> userData) {
    final insurance = userData['insurance'] ?? {};
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shield, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'Insurance Information',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Provider: ${insurance['provider'] ?? 'N/A'}'),
            Text('Policy #: ${insurance['policyNumber'] ?? 'N/A'}'),
            Text('Group #: ${insurance['groupNumber'] ?? 'N/A'}'),
            Text('Phone: ${insurance['phone'] ?? 'N/A'}'),
            Text('Valid Through: ${insurance['validThrough'] ?? 'N/A'}'),
          ],
        ),
      ),
    );
  }
}

// Medical History Summary Section
class MedicalHistorySummarySection extends ProfileSection {
  @override
  String get title => 'Medical History';
  @override
  IconData get icon => Icons.history;
  @override
  Color get color => Colors.blue;

  @override
  Widget buildContent(BuildContext context, Map<String, dynamic> userData) {
    final medicalHistory = userData['medicalHistory'] ?? {};
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Medical History Summary',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Conditions: ${medicalHistory['conditions'] ?? 'None reported'}',
            ),
            Text(
              'Allergies: ${medicalHistory['allergies'] ?? 'None reported'}',
            ),
            Text(
              'Medications: ${medicalHistory['medications'] ?? 'None reported'}',
            ),
            Text('Last Visit: ${medicalHistory['lastVisit'] ?? 'N/A'}'),
          ],
        ),
      ),
    );
  }
}

// Profile Page Widget
class ProfilePage extends StatelessWidget {
  final List<ProfileSection> sections = [
    InsuranceInformationSection(),
    MedicalHistorySummarySection(),
  ];

  ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final userData = snapshot.data?.data() as Map<String, dynamic>? ?? {};

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Profile Header
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 30,
                          child: Icon(Icons.person, size: 40),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userData['name'] ?? 'User',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                user.email ?? 'No email',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Profile Sections
                ...sections.map(
                  (section) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: section.buildContent(context, userData),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
