import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/firestore_service.dart';

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
      length: 3,
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
              Tab(icon: Icon(Icons.shopping_cart), text: 'Medicine Orders'),
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
            _buildMedicineOrdersTab(user.uid),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalRecordsTab(String userId) {
    return Column(
      children: [
        // Medical History Summary Section
        StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
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
                          'Medical History Summary',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      'Blood Type',
                      medicalHistory['bloodType'] ?? 'N/A',
                    ),
                    _buildInfoRow(
                      'Allergies',
                      medicalHistory['allergies'] ?? 'None reported',
                    ),
                    _buildInfoRow(
                      'Conditions',
                      medicalHistory['conditions'] ?? 'None reported',
                    ),
                    _buildInfoRow(
                      'Current Medications',
                      medicalHistory['medications'] ?? 'None reported',
                    ),
                    _buildInfoRow(
                      'Last Visit',
                      medicalHistory['lastVisit'] ?? 'N/A',
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        // Medical Records List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('medical_reports')
                .where('patientId', isEqualTo: userId)
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
                        onPressed: () => _orderMedicine(prescription.id, data),
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

  Widget _buildMedicineOrdersTab(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('medicine_orders')
          .where('patientId', isEqualTo: userId)
          .orderBy('orderDate', descending: true)
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
                Icon(Icons.shopping_cart, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text('No medicine orders found'),
                SizedBox(height: 8),
                Text(
                  'Orders will appear here when you order medicines from prescriptions',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final orders = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            final data = order.data() as Map<String, dynamic>;

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
                        Icon(Icons.shopping_cart, color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            data['medicineName'] ?? 'Medicine Order',
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
                            color: _getOrderStatusColor(data['status']),
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
                    _buildInfoRow('Medicine', data['medicineName'] ?? 'N/A'),
                    _buildInfoRow(
                      'Quantity',
                      data['quantity']?.toString() ?? 'N/A',
                    ),
                    _buildInfoRow(
                      'Delivery Address',
                      data['deliveryAddress'] ?? 'N/A',
                    ),
                    _buildInfoRow('Contact', data['contactNumber'] ?? 'N/A'),
                    _buildInfoRow('Order Date', _formatDate(data['orderDate'])),
                    if (data['estimatedDelivery'] != null)
                      _buildInfoRow(
                        'Estimated Delivery',
                        _formatDate(data['estimatedDelivery']),
                      ),
                    if (data['trackingNumber'] != null)
                      _buildInfoRow('Tracking Number', data['trackingNumber']),
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

  void _orderMedicine(
    String prescriptionId,
    Map<String, dynamic> prescriptionData,
  ) {
    final quantityController = TextEditingController(text: '1');
    final addressController = TextEditingController();
    final contactController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Order ${prescriptionData['medicineName']}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  hintText: 'Enter quantity needed',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Delivery Address',
                  hintText: 'Enter delivery address',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contactController,
                decoration: const InputDecoration(
                  labelText: 'Contact Number',
                  hintText: 'Enter contact number',
                ),
                keyboardType: TextInputType.phone,
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
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                final orderData = {
                  'patientId': user.uid,
                  'prescriptionId': prescriptionId,
                  'medicineName': prescriptionData['medicineName'],
                  'dosage': prescriptionData['dosage'],
                  'quantity': int.tryParse(quantityController.text) ?? 1,
                  'deliveryAddress': addressController.text.trim(),
                  'contactNumber': contactController.text.trim(),
                  'status': 'Ordered',
                  'orderDate': FieldValue.serverTimestamp(),
                  'estimatedDelivery': DateTime.now().add(
                    const Duration(days: 3),
                  ),
                };

                try {
                  await FirebaseFirestore.instance
                      .collection('medicine_orders')
                      .add(orderData);

                  // Update prescription status
                  await FirebaseFirestore.instance
                      .collection('prescriptions')
                      .doc(prescriptionId)
                      .update({'status': 'Ordered'});

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Medicine ordered successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error ordering medicine: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Order'),
          ),
        ],
      ),
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

  Color _getOrderStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'ordered':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'shipped':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.orange;
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
