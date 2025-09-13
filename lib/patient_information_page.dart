import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Abstract base class for patient information components
abstract class PatientInformationComponent {
  String get title;
  IconData get icon;
  Color get color;
  Widget buildContent(BuildContext context, Map<String, dynamic> data);
}

// Patient demographics component
class PatientDemographics extends PatientInformationComponent {
  @override
  String get title => 'Personal Information';

  @override
  IconData get icon => Icons.person;

  @override
  Color get color => Colors.blue;

  @override
  Widget buildContent(BuildContext context, Map<String, dynamic> data) {
    return Column(
      children: [
        _buildInfoRow('Full Name', data['fullName'] ?? 'Not provided'),
        _buildInfoRow('Date of Birth', data['dateOfBirth'] ?? 'Not provided'),
        _buildInfoRow('Gender', data['gender'] ?? 'Not provided'),
        _buildInfoRow('Blood Type', data['bloodType'] ?? 'Not provided'),
        _buildInfoRow('Phone Number', data['phoneNumber'] ?? 'Not provided'),
        _buildInfoRow('Email', data['email'] ?? 'Not provided'),
        _buildInfoRow('Address', data['address'] ?? 'Not provided'),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

// Emergency contacts component
class EmergencyContacts extends PatientInformationComponent {
  @override
  String get title => 'Emergency Contacts';

  @override
  IconData get icon => Icons.emergency;

  @override
  Color get color => Colors.red;

  @override
  Widget buildContent(BuildContext context, Map<String, dynamic> data) {
    List<dynamic> contacts = data['emergencyContacts'] ?? [];

    if (contacts.isEmpty) {
      return const Center(
        child: Text(
          'No emergency contacts added',
          style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
        ),
      );
    }

    return Column(
      children: contacts.map<Widget>((contact) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                contact['name'] ?? 'Unknown',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Relationship: ${contact['relationship'] ?? 'Not specified'}',
                style: TextStyle(color: Colors.red.shade700),
              ),
              Text(
                'Phone: ${contact['phone'] ?? 'Not provided'}',
                style: TextStyle(color: Colors.red.shade700),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// Insurance information component
class InsuranceInformation extends PatientInformationComponent {
  @override
  String get title => 'Insurance Information';

  @override
  IconData get icon => Icons.shield;

  @override
  Color get color => Colors.green;

  @override
  Widget buildContent(BuildContext context, Map<String, dynamic> data) {
    Map<String, dynamic> insurance = data['insurance'] ?? {};

    if (insurance.isEmpty) {
      return const Center(
        child: Text(
          'No insurance information available',
          style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        children: [
          _buildInsuranceRow('Provider', insurance['provider']),
          _buildInsuranceRow('Policy Number', insurance['policyNumber']),
          _buildInsuranceRow('Group Number', insurance['groupNumber']),
          _buildInsuranceRow('Effective Date', insurance['effectiveDate']),
          _buildInsuranceRow('Expiry Date', insurance['expiryDate']),
          _buildInsuranceRow('Coverage Type', insurance['coverageType']),
        ],
      ),
    );
  }

  Widget _buildInsuranceRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.green.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'Not provided',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.green.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Medical history summary component
class MedicalHistorySummary extends PatientInformationComponent {
  @override
  String get title => 'Medical History Summary';

  @override
  IconData get icon => Icons.history;

  @override
  Color get color => Colors.purple;

  @override
  Widget buildContent(BuildContext context, Map<String, dynamic> data) {
    Map<String, dynamic> medicalHistory = data['medicalHistory'] ?? {};

    return Column(
      children: [
        _buildHistorySection(
          'Chronic Conditions',
          medicalHistory['chronicConditions'] ?? [],
          Icons.medical_services,
          Colors.orange,
        ),
        const SizedBox(height: 16),
        _buildHistorySection(
          'Previous Surgeries',
          medicalHistory['surgeries'] ?? [],
          Icons.healing,
          Colors.blue,
        ),
        const SizedBox(height: 16),
        _buildHistorySection(
          'Family History',
          medicalHistory['familyHistory'] ?? [],
          Icons.family_restroom,
          Colors.green,
        ),
        const SizedBox(height: 16),
        _buildHistorySection(
          'Current Medications',
          medicalHistory['currentMedications'] ?? [],
          Icons.medication,
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildHistorySection(
    String title,
    List<dynamic> items,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Text(
              'No records available',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            ...items.map<Widget>((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: TextStyle(color: color)),
                    Expanded(
                      child: Text(
                        item.toString(),
                        style: TextStyle(color: color.withOpacity(0.8)),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }
}

// Main patient information page using composition pattern
class PatientInformationPage extends StatefulWidget {
  const PatientInformationPage({super.key});

  @override
  State<PatientInformationPage> createState() => _PatientInformationPageState();
}

class _PatientInformationPageState extends State<PatientInformationPage>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // List of patient information components
  final List<PatientInformationComponent> _components = [
    PatientDemographics(),
    EmergencyContacts(),
    InsuranceInformation(),
    MedicalHistorySummary(),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _components.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view patient information')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Patient Information',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.teal.shade600,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () => _editPatientInfo(context),
            tooltip: 'Edit Information',
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.white),
            onPressed: () => _clearMyData(context),
            tooltip: 'Clear My Data',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: _components.map((component) {
            return Tab(icon: Icon(component.icon), text: component.title);
          }).toList(),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('patient_information')
            .doc(currentUser.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          Map<String, dynamic> patientData = {};
          if (snapshot.hasData && snapshot.data!.exists) {
            patientData = snapshot.data!.data() as Map<String, dynamic>;
          }

          return TabBarView(
            controller: _tabController,
            children: _components.map((component) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              component.icon,
                              color: component.color,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              component.title,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: component.color,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        component.buildContent(context, patientData),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  void _editPatientInfo(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit functionality would be implemented here'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<void> _clearMyData(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = user.uid;
    try {
      // Delete patient information
      await FirebaseFirestore.instance
          .collection('patient_information')
          .doc(uid)
          .delete();
      // Delete all appointments for this user
      final appointments = await FirebaseFirestore.instance
          .collection('appointments')
          .where('patientId', isEqualTo: uid)
          .get();
      for (final doc in appointments.docs) {
        await doc.reference.delete();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your patient info and appointments have been cleared.',
          ),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error clearing data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
