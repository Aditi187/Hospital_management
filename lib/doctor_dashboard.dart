import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/firestore_service.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String selectedPatientId = '';
  Map<String, dynamic> selectedPatientData = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Doctor Dashboard"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: Row(
        children: [
          // Left Panel - Patient List
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.teal.shade50,
                    child: const Row(
                      children: [
                        Icon(Icons.people, color: Colors.teal),
                        SizedBox(width: 8),
                        Text(
                          'Patients',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(child: _buildPatientList()),
                ],
              ),
            ),
          ),
          // Right Panel - Patient Details and Medical Records
          Expanded(
            flex: 2,
            child: selectedPatientId.isEmpty
                ? _buildWelcomeScreen()
                : _buildPatientDetailsScreen(),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.medical_services, size: 100, color: Colors.grey.shade400),
          const SizedBox(height: 20),
          Text(
            'Welcome Doctor!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Select a patient to view their medical records',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No patients found'));
        }

        final patients = snapshot.data!.docs;

        return ListView.builder(
          itemCount: patients.length,
          itemBuilder: (context, index) {
            final patient = patients[index];
            final data = patient.data() as Map<String, dynamic>;
            final name = data['name'] ?? 'Unknown Patient';
            final email = data['email'] ?? '';
            final patientId = patient.id;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.teal.shade100,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'P',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                ),
                title: Text(name),
                subtitle: Text(email),
                selected: selectedPatientId == patientId,
                selectedTileColor: Colors.teal.shade50,
                onTap: () {
                  setState(() {
                    selectedPatientId = patientId;
                    selectedPatientData = data;
                  });
                },
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: selectedPatientId == patientId
                      ? Colors.teal
                      : Colors.grey,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPatientDetailsScreen() {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          // Patient Info Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.teal.shade50,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.teal.shade200,
                  child: Text(
                    selectedPatientData['name']?.isNotEmpty == true
                        ? selectedPatientData['name'][0].toUpperCase()
                        : 'P',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedPatientData['name'] ?? 'Unknown Patient',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                      Text(
                        selectedPatientData['email'] ?? '',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      Text(
                        'Patient ID: $selectedPatientId',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Tab Bar
          TabBar(
            labelColor: Colors.teal,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.teal,
            tabs: const [
              Tab(icon: Icon(Icons.person), text: 'Profile'),
              Tab(icon: Icon(Icons.medical_services), text: 'Medical Records'),
              Tab(icon: Icon(Icons.medication), text: 'Prescriptions'),
              Tab(icon: Icon(Icons.add_circle), text: 'Add Record'),
            ],
          ),
          // Tab Views
          Expanded(
            child: TabBarView(
              children: [
                _buildPatientProfileTab(),
                _buildMedicalRecordsTab(),
                _buildPrescriptionsTab(),
                _buildAddRecordTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard('Personal Information', Icons.person, Colors.blue, [
            _buildInfoRow('Name', selectedPatientData['name'] ?? 'N/A'),
            _buildInfoRow('Email', selectedPatientData['email'] ?? 'N/A'),
            _buildInfoRow('Phone', selectedPatientData['phone'] ?? 'N/A'),
            _buildInfoRow('Address', selectedPatientData['address'] ?? 'N/A'),
          ]),
          const SizedBox(height: 16),
          _buildInfoCard(
            'Insurance Information',
            Icons.shield,
            Colors.green,
            _buildInsuranceInfo(),
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            'Medical History',
            Icons.history,
            Colors.orange,
            _buildMedicalHistoryInfo(),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalRecordsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('medical_reports')
          .where('patientId', isEqualTo: selectedPatientId)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.medical_services, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text('No medical records found'),
              ],
            ),
          );
        }

        final records = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: records.length,
          itemBuilder: (context, index) {
            final record = records[index];
            final data = record.data() as Map<String, dynamic>;

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.medical_services, color: Colors.teal),
                        const SizedBox(width: 8),
                        Text(
                          data['title'] ?? 'Medical Record',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatDate(data['timestamp']),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (data['doctorName'] != null)
                      Text('Doctor: ${data['doctorName']}'),
                    if (data['diagnosis'] != null)
                      Text('Diagnosis: ${data['diagnosis']}'),
                    if (data['treatment'] != null)
                      Text('Treatment: ${data['treatment']}'),
                    if (data['notes'] != null) Text('Notes: ${data['notes']}'),
                    if (data['prescriptions'] != null)
                      _buildPrescriptionList(data['prescriptions']),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPrescriptionsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('prescriptions')
          .where('patientId', isEqualTo: selectedPatientId)
          .orderBy('prescribedDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.medication, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text('No prescriptions found'),
              ],
            ),
          );
        }

        final prescriptions = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: prescriptions.length,
          itemBuilder: (context, index) {
            final prescription = prescriptions[index];
            final data = prescription.data() as Map<String, dynamic>;

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.medication, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          data['medicineName'] ?? 'Medicine',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(data['status']),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            data['status'] ?? 'Pending',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Dosage: ${data['dosage'] ?? 'N/A'}'),
                    Text('Frequency: ${data['frequency'] ?? 'N/A'}'),
                    Text('Duration: ${data['duration'] ?? 'N/A'}'),
                    Text('Instructions: ${data['instructions'] ?? 'N/A'}'),
                    Text('Prescribed: ${_formatDate(data['prescribedDate'])}'),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAddRecordTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add New Medical Record',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showAddMedicalRecordDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Medical Record'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Prescribe Medicine',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showPrescribeMedicineDialog(),
                    icon: const Icon(Icons.medication),
                    label: const Text('Prescribe Medicine'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
    IconData icon,
    Color color,
    List<Widget> children,
  ) {
    return Card(
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  List<Widget> _buildInsuranceInfo() {
    final insurance = selectedPatientData['insurance'] ?? {};
    return [
      _buildInfoRow('Provider', insurance['provider'] ?? 'N/A'),
      _buildInfoRow('Policy #', insurance['policyNumber'] ?? 'N/A'),
      _buildInfoRow('Group #', insurance['groupNumber'] ?? 'N/A'),
      _buildInfoRow('Valid Through', insurance['validThrough'] ?? 'N/A'),
    ];
  }

  List<Widget> _buildMedicalHistoryInfo() {
    final medicalHistory = selectedPatientData['medicalHistory'] ?? {};
    return [
      _buildInfoRow('Blood Type', medicalHistory['bloodType'] ?? 'N/A'),
      _buildInfoRow('Allergies', medicalHistory['allergies'] ?? 'N/A'),
      _buildInfoRow('Conditions', medicalHistory['conditions'] ?? 'N/A'),
      _buildInfoRow('Medications', medicalHistory['medications'] ?? 'N/A'),
    ];
  }

  Widget _buildPrescriptionList(List<dynamic> prescriptions) {
    if (prescriptions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Text(
          'Prescriptions:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        ...prescriptions.map<Widget>((prescription) {
          return Padding(
            padding: const EdgeInsets.only(left: 16, top: 4),
            child: Text(
              '• ${prescription['medicine']} - ${prescription['dosage']}',
            ),
          );
        }).toList(),
      ],
    );
  }

  void _showAddMedicalRecordDialog() {
    final titleController = TextEditingController();
    final diagnosisController = TextEditingController();
    final treatmentController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Medical Record'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Record Title',
                  hintText: 'e.g., Regular Checkup, Follow-up Visit',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: diagnosisController,
                decoration: const InputDecoration(labelText: 'Diagnosis'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: treatmentController,
                decoration: const InputDecoration(labelText: 'Treatment'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _saveMedicalRecord(
              titleController.text,
              diagnosisController.text,
              treatmentController.text,
              notesController.text,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showPrescribeMedicineDialog() {
    final medicineController = TextEditingController();
    final dosageController = TextEditingController();
    final frequencyController = TextEditingController();
    final durationController = TextEditingController();
    final instructionsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Prescribe Medicine'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: medicineController,
                decoration: const InputDecoration(labelText: 'Medicine Name'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: dosageController,
                decoration: const InputDecoration(
                  labelText: 'Dosage',
                  hintText: 'e.g., 500mg',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: frequencyController,
                decoration: const InputDecoration(
                  labelText: 'Frequency',
                  hintText: 'e.g., Twice daily',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: durationController,
                decoration: const InputDecoration(
                  labelText: 'Duration',
                  hintText: 'e.g., 7 days',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: instructionsController,
                decoration: const InputDecoration(
                  labelText: 'Instructions',
                  hintText: 'e.g., Take after meals',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _savePrescription(
              medicineController.text,
              dosageController.text,
              frequencyController.text,
              durationController.text,
              instructionsController.text,
            ),
            child: const Text('Prescribe'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveMedicalRecord(
    String title,
    String diagnosis,
    String treatment,
    String notes,
  ) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      await _firestore.collection('medical_reports').add({
        'patientId': selectedPatientId,
        'doctorId': currentUser?.uid,
        'doctorName':
            currentUser?.displayName ?? currentUser?.email ?? 'Doctor',
        'title': title,
        'diagnosis': diagnosis,
        'treatment': treatment,
        'notes': notes,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': DateTime.now().toIso8601String(),
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Medical record added successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding medical record: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _savePrescription(
    String medicine,
    String dosage,
    String frequency,
    String duration,
    String instructions,
  ) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      await _firestore.collection('prescriptions').add({
        'patientId': selectedPatientId,
        'doctorId': currentUser?.uid,
        'doctorName':
            currentUser?.displayName ?? currentUser?.email ?? 'Doctor',
        'medicineName': medicine,
        'dosage': dosage,
        'frequency': frequency,
        'duration': duration,
        'instructions': instructions,
        'status': 'Prescribed',
        'prescribedDate': FieldValue.serverTimestamp(),
        'createdAt': DateTime.now().toIso8601String(),
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Medicine prescribed successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error prescribing medicine: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';

    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year}';
    }

    if (timestamp is String) {
      try {
        final date = DateTime.parse(timestamp);
        return '${date.day}/${date.month}/${date.year}';
      } catch (e) {
        return timestamp;
      }
    }

    return timestamp.toString();
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'prescribed':
        return Colors.blue;
      case 'dispensed':
        return Colors.green;
      case 'completed':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
=======

class DoctorDashboard extends StatelessWidget {
  const DoctorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Doctor Dashboard")),
      body: const Center(child: Text("Welcome Doctor!")),
>>>>>>> 4685f151cb62db19ed2c4d165ee7db2582cd4f02
    );
  }
}
