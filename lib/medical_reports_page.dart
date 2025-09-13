import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'patient_information_page.dart';

class MedicalReportsPage extends StatefulWidget {
  const MedicalReportsPage({Key? key}) : super(key: key);

  @override
  State<MedicalReportsPage> createState() => _MedicalReportsPageState();
}

class _MedicalReportsPageState extends State<MedicalReportsPage> {
  // Helper for displaying medical history sections
  Widget _buildHistorySection(
    String title,
    List<dynamic> items,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const SizedBox(height: 4),
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
                padding: const EdgeInsets.only(bottom: 2),
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

  void _showAddMedicalRecordDialog() {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController doctorController = TextEditingController();
    final TextEditingController diagnosisController = TextEditingController();
    final TextEditingController treatmentController = TextEditingController();
    final TextEditingController medicationsController = TextEditingController();
    final TextEditingController allergiesController = TextEditingController();
    final TextEditingController vitalsController = TextEditingController();
    final TextEditingController nextFollowUpController =
        TextEditingController();
    final TextEditingController prescriptionController =
        TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Medical Record'),
        content: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: doctorController,
                    decoration: const InputDecoration(labelText: 'Doctor Name'),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Enter doctor name'
                        : null,
                  ),
                  TextFormField(
                    controller: diagnosisController,
                    decoration: const InputDecoration(labelText: 'Diagnosis'),
                  ),
                  TextFormField(
                    controller: treatmentController,
                    decoration: const InputDecoration(
                      labelText: 'Treatment Plan',
                    ),
                  ),
                  TextFormField(
                    controller: medicationsController,
                    decoration: const InputDecoration(labelText: 'Medications'),
                  ),
                  TextFormField(
                    controller: allergiesController,
                    decoration: const InputDecoration(labelText: 'Allergies'),
                  ),
                  TextFormField(
                    controller: vitalsController,
                    decoration: const InputDecoration(labelText: 'Vitals'),
                  ),
                  TextFormField(
                    controller: nextFollowUpController,
                    decoration: const InputDecoration(
                      labelText: 'Next Follow-up',
                    ),
                  ),
                  TextFormField(
                    controller: prescriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Prescription',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Date:'),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null)
                            setState(() => selectedDate = picked);
                        },
                        child: Text(
                          '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!_formKey.currentState!.validate()) return;
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) return;
              await FirebaseFirestore.instance
                  .collection('medical_reports')
                  .add({
                    'doctorName': doctorController.text.trim(),
                    'diagnosis': diagnosisController.text.trim(),
                    'treatmentPlan': treatmentController.text.trim(),
                    'medications': medicationsController.text.trim(),
                    'allergies': allergiesController.text.trim(),
                    'vitals': vitalsController.text.trim(),
                    'nextFollowUp': nextFollowUpController.text.trim(),
                    'prescription': prescriptionController.text.trim(),
                    'date': Timestamp.fromDate(selectedDate),
                    'patientId': user.uid,
                    'createdAt': FieldValue.serverTimestamp(),
                  });
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Medical record added!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Add Record'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearMyMedicalRecords(BuildContext context, String uid) async {
    // Delete all medical reports for the current user from Firestore
    final batch = FirebaseFirestore.instance.batch();
    final query = await FirebaseFirestore.instance
        .collection('medical_reports')
        .where('patientId', isEqualTo: uid)
        .get();
    for (final doc in query.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All your medical records have been cleared.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('User not logged in.'));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Reports'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Clear My Medical Records',
            onPressed: () => _clearMyMedicalRecords(context, user.uid),
          ),
        ],
      ),
      body: Column(
        children: [
          // Medical History Summary Section
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('patient_information')
                .doc(user.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No medical history found.'),
                );
              }
              final data = snapshot.data!.data() as Map<String, dynamic>;
              final medicalHistory = data['medicalHistory'] ?? {};
              return Card(
                margin: const EdgeInsets.all(16),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.history, color: Colors.purple, size: 28),
                          const SizedBox(width: 12),
                          const Text(
                            'Medical History',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildHistorySection(
                        'Chronic Conditions',
                        medicalHistory['chronicConditions'] ?? [],
                        Icons.medical_services,
                        Colors.orange,
                      ),
                      const SizedBox(height: 8),
                      _buildHistorySection(
                        'Previous Surgeries',
                        medicalHistory['surgeries'] ?? [],
                        Icons.healing,
                        Colors.blue,
                      ),
                      const SizedBox(height: 8),
                      _buildHistorySection(
                        'Family History',
                        medicalHistory['familyHistory'] ?? [],
                        Icons.family_restroom,
                        Colors.green,
                      ),
                      const SizedBox(height: 8),
                      _buildHistorySection(
                        'Current Medications',
                        medicalHistory['currentMedications'] ?? [],
                        Icons.medication,
                        Colors.red,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // Expanded: rest of the page (table, summary, cards)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('medical_reports')
                  .where('patientId', isEqualTo: user.uid)
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, size: 64, color: Colors.red),
                        SizedBox(height: 16),
                        Text('Error:  ���[38;5;9m${snapshot.error}���[0m'),
                        SizedBox(height: 16),
                      ],
                    ),
                  );
                }
                final reports = snapshot.data?.docs ?? [];
                final totalReports = reports.length;
                int activeTreatments = 0;
                int followUps = 0;
                for (final doc in reports) {
                  final data = doc.data() as Map<String, dynamic>;
                  if (data['treatmentPlan'] != null &&
                      (data['treatmentPlan'] as String).trim().isNotEmpty) {
                    activeTreatments++;
                  }
                  if (data['nextFollowUp'] != null &&
                      (data['nextFollowUp'] as String).trim().isNotEmpty) {
                    followUps++;
                  }
                }
                // Structured Medical Records Overview Table
                Widget structureSection = Card(
                  margin: const EdgeInsets.all(16),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: reports.isEmpty
                        ? const Text('No medical records found.')
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Date')),
                                DataColumn(label: Text('Doctor')),
                                DataColumn(label: Text('Diagnosis')),
                                DataColumn(label: Text('Treatment')),
                                DataColumn(label: Text('Allergies')),
                                DataColumn(label: Text('Medications')),
                                DataColumn(label: Text('Vitals')),
                                DataColumn(label: Text('Next Follow-up')),
                                DataColumn(label: Text('Prescription')),
                              ],
                              rows: reports.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final date = data['date'] != null
                                    ? (data['date'] as Timestamp).toDate()
                                    : null;
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Text(
                                        date != null
                                            ? '${date.day}/${date.month}/${date.year}'
                                            : '-',
                                      ),
                                    ),
                                    DataCell(Text(data['doctorName'] ?? '-')),
                                    DataCell(Text(data['diagnosis'] ?? '-')),
                                    DataCell(
                                      Text(data['treatmentPlan'] ?? '-'),
                                    ),
                                    DataCell(Text(data['allergies'] ?? '-')),
                                    DataCell(Text(data['medications'] ?? '-')),
                                    DataCell(Text(data['vitals'] ?? '-')),
                                    DataCell(Text(data['nextFollowUp'] ?? '-')),
                                    DataCell(Text(data['prescription'] ?? '-')),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                  ),
                );
                return Column(
                  children: [
                    structureSection,
                    // Patient Summary Card
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.teal.shade50, Colors.blue.shade50],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 2,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 25,
                                backgroundColor: Colors.teal.shade100,
                                child: Icon(
                                  Icons.person,
                                  color: Colors.teal.shade700,
                                  size: 30,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Patient Health Summary',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.teal.shade800,
                                      ),
                                    ),
                                    Text(
                                      'Complete medical history overview',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const PatientInformationPage(),
                                    ),
                                  );
                                },
                                icon: Icon(
                                  Icons.info_outline,
                                  color: Colors.teal.shade600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildQuickStat(
                                  'Total Reports',
                                  totalReports.toString(),
                                  Icons.assignment,
                                  Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildQuickStat(
                                  'Active Treatments',
                                  activeTreatments.toString(),
                                  Icons.healing,
                                  Colors.green,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildQuickStat(
                                  'Follow-ups',
                                  followUps.toString(),
                                  Icons.schedule,
                                  Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Reports List
                    Expanded(
                      child: reports.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.assignment,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No medical reports found',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Your medical reports will appear here',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: reports.length,
                              itemBuilder: (context, index) {
                                final report = reports[index];
                                final data =
                                    report.data() as Map<String, dynamic>;
                                return _buildReportCard(
                                  context,
                                  data,
                                  report.id,
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMedicalRecordDialog,
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add),
        tooltip: 'Add Medical Record',
      ),
    );
  }

  Widget _buildReportCard(
    BuildContext context,
    Map<String, dynamic> data,
    String reportId,
  ) {
    final DateTime date = (data['date'] as Timestamp).toDate();
    final String reportType = data['reportType'] ?? 'General Report';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    reportType,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, color: Colors.green, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'VERIFIED',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Date and Doctor
            Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.grey[600], size: 20),
                const SizedBox(width: 8),
                Text('${date.day}/${date.month}/${date.year}'),
                const SizedBox(width: 24),
                Icon(Icons.person_outlined, color: Colors.grey[600], size: 20),
                const SizedBox(width: 8),
                Text(data['doctorName'] ?? 'Dr. Smith'),
              ],
            ),
            const SizedBox(height: 12),

            // Diagnosis
            if (data['diagnosis'] != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.medical_services,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Diagnosis:',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(data['diagnosis']),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Medications
            if (data['medications'] != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.medication, color: Colors.grey[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Medications:',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(data['medications']),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Patient Symptoms (New Addition)
            if (data['patientSymptoms'] != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.sick, color: Colors.orange.shade600, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Patient Symptoms:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade700,
                          ),
                        ),
                        Text(data['patientSymptoms']),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Patient Vitals (New Addition)
            if (data['vitals'] != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.favorite, color: Colors.red.shade600, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vital Signs:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.red.shade700,
                          ),
                        ),
                        Text(data['vitals']),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Patient Treatment Plan (New Addition)
            if (data['treatmentPlan'] != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.healing, color: Colors.purple.shade600, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Treatment Plan:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.purple.shade700,
                          ),
                        ),
                        Text(data['treatmentPlan']),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Patient Notes (New Addition)
            if (data['patientNotes'] != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.note, color: Colors.teal.shade600, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Patient Notes:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.teal.shade700,
                          ),
                        ),
                        Text(data['patientNotes']),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Next Follow-up (New Addition)
            if (data['nextFollowUp'] != null) ...[
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule, color: Colors.blue.shade600, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Next Follow-up:',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          Text(
                            data['nextFollowUp'],
                            style: TextStyle(color: Colors.blue.shade800),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Patient Allergies (New Addition)
            if (data['allergies'] != null && data['allergies'].isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red.shade600, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Known Allergies:',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.red.shade700,
                            ),
                          ),
                          Text(
                            data['allergies'],
                            style: TextStyle(color: Colors.red.shade800),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Lab Results
            if (data['labResults'] != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.science, color: Colors.grey[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Lab Results:',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(data['labResults']),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Notes
            if (data['notes'] != null &&
                data['notes'].toString().isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.note, color: Colors.grey[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Notes:',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(data['notes']),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Report ID
            Text(
              'Report ID: ${reportId.substring(0, 8)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontFamily: 'monospace',
              ),
            ),

            // Action buttons
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _downloadReport(context, reportId),
                  icon: const Icon(Icons.download),
                  label: const Text('Download'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _shareReport(context, reportId),
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _downloadReport(BuildContext context, String reportId) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Download functionality would be implemented here'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _shareReport(BuildContext context, String reportId) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality would be implemented here'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildQuickStat(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
