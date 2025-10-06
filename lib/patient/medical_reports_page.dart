import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'medicine_ordering_page.dart';

class MedicalReportsPage extends StatefulWidget {
  const MedicalReportsPage({Key? key}) : super(key: key);

  @override
  State<MedicalReportsPage> createState() => _MedicalReportsPageState();
}

class _MedicalReportsPageState extends State<MedicalReportsPage> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('User not logged in.'));
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Medical Reports'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.medical_services), text: 'Medical Records'),
              Tab(icon: Icon(Icons.medication), text: 'Prescriptions'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_forever),
              tooltip: 'Clear My Medical Records',
              onPressed: () => _clearMyMedicalRecords(context, user.uid),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildMedicalRecordsTab(user.uid),
            _buildPrescriptionsTab(user.uid),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalRecordsTab(String userId) {
    return Column(
      children: [
        // Medical Records List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('medical_reports')
                .where('patientId', isEqualTo: userId)
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
                      Icon(
                        Icons.medical_services,
                        size: 80,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text('No medical records found'),
                    ],
                  ),
                );
              }

              final reports = snapshot.data!.docs;
              reports.sort((a, b) {
                final aData = a.data() as Map<String, dynamic>;
                final bData = b.data() as Map<String, dynamic>;
                final aTs = aData['timestamp'] as Timestamp?;
                final bTs = bData['timestamp'] as Timestamp?;
                if (aTs == null) return 1;
                if (bTs == null) return -1;
                return bTs.compareTo(aTs);
              });

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: reports.length,
                itemBuilder: (context, index) {
                  final report = reports[index];
                  final data = report.data() as Map<String, dynamic>;

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
                              Icon(
                                Icons.medical_services,
                                color: Colors.deepPurple,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  data['title'] ?? 'Medical Record',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
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
                            _buildInfoRow('Doctor', data['doctorName']),
                          if (data['diagnosis'] != null)
                            _buildInfoRow('Diagnosis', data['diagnosis']),
                          if (data['treatment'] != null)
                            _buildInfoRow('Treatment', data['treatment']),
                          if (data['notes'] != null)
                            _buildInfoRow('Notes', data['notes']),
                          if (data['prescriptions'] != null)
                            _buildPrescriptionList(data['prescriptions']),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPrescriptionsTab(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('prescriptions')
          .where('patientId', isEqualTo: userId)
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
                        Expanded(
                          child: Text(
                            data['medicineName'] ?? 'Medicine',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
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
                    _buildInfoRow('Doctor', data['doctorName'] ?? 'N/A'),
                    _buildInfoRow('Dosage', data['dosage'] ?? 'N/A'),
                    _buildInfoRow('Frequency', data['frequency'] ?? 'N/A'),
                    _buildInfoRow('Duration', data['duration'] ?? 'N/A'),
                    _buildInfoRow(
                      'Instructions',
                      data['instructions'] ?? 'N/A',
                    ),
                    _buildInfoRow(
                      'Prescribed',
                      _formatDate(data['prescribedDate']),
                    ),
                    const SizedBox(height: 12),
                    if (data['status'] == 'Prescribed')
                      ElevatedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MedicineOrderingPage(),
                          ),
                        ),
                        icon: const Icon(Icons.shopping_cart),
                        label: const Text('Order Medicine'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: Colors.grey.shade700)),
          ),
        ],
      ),
    );
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
      case 'ordered':
        return Colors.orange;
      case 'dispensed':
        return Colors.green;
      case 'completed':
        return Colors.grey;
      default:
        return Colors.blue;
    }
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
}
