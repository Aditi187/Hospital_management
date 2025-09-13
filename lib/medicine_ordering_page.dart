import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MedicineOrderingPage extends StatefulWidget {
  const MedicineOrderingPage({Key? key}) : super(key: key);

  @override
  State<MedicineOrderingPage> createState() => _MedicineOrderingPageState();
}

class _MedicineOrderingPageState extends State<MedicineOrderingPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Medicines'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(
              icon: Icon(Icons.medical_services),
              text: 'Prescribed Medicines',
            ),
            Tab(icon: Icon(Icons.shopping_cart), text: 'Order History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildPrescribedMedicinesTab(), _buildOrderHistoryTab()],
      ),
    );
  }

  Widget _buildPrescribedMedicinesTab() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please log in to view prescriptions'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('prescriptions')
          .where('patientId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'Prescribed')
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
                Text('No prescribed medicines found'),
                SizedBox(height: 8),
                Text(
                  'Medicines prescribed by doctors will appear here',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
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
                        Icon(Icons.medication, color: Colors.green),
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
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            data['status'] ?? 'Prescribed',
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
                      'Prescribed Date',
                      _formatDate(data['prescribedDate']),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _orderMedicine(prescription.id, data),
                            icon: const Icon(Icons.shopping_cart),
                            label: const Text('Order Medicine'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _viewPrescriptionDetails(data),
                            icon: const Icon(Icons.info),
                            label: const Text('View Details'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildOrderHistoryTab() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please log in to view order history'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('medicine_orders')
          .where('patientId', isEqualTo: user.uid)
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
                Icon(Icons.history, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text('No order history found'),
                SizedBox(height: 8),
                Text(
                  'Your medicine orders will appear here',
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
                    _buildInfoRow('Dosage', data['dosage'] ?? 'N/A'),
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
                    const SizedBox(height: 12),
                    if (data['status'] == 'Ordered' ||
                        data['status'] == 'Processing')
                      ElevatedButton.icon(
                        onPressed: () => _trackOrder(order.id, data),
                        icon: const Icon(Icons.track_changes),
                        label: const Text('Track Order'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
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
              // Medicine Details Summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Medicine Details:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Name: ${prescriptionData['medicineName']}'),
                    Text('Dosage: ${prescriptionData['dosage']}'),
                    Text('Frequency: ${prescriptionData['frequency']}'),
                    Text('Duration: ${prescriptionData['duration']}'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  hintText: 'Enter quantity needed',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.numbers),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Delivery Address',
                  hintText: 'Enter your complete address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contactController,
                decoration: const InputDecoration(
                  labelText: 'Contact Number',
                  hintText: 'Enter your phone number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
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
              if (_validateOrderForm(
                quantityController.text,
                addressController.text,
                contactController.text,
              )) {
                await _submitOrder(
                  prescriptionId,
                  prescriptionData,
                  quantityController.text,
                  addressController.text,
                  contactController.text,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Place Order'),
          ),
        ],
      ),
    );
  }

  bool _validateOrderForm(String quantity, String address, String contact) {
    if (quantity.isEmpty ||
        int.tryParse(quantity) == null ||
        int.parse(quantity) <= 0) {
      _showErrorSnackBar('Please enter a valid quantity');
      return false;
    }

    if (address.trim().isEmpty || address.trim().length < 10) {
      _showErrorSnackBar('Please enter a complete delivery address');
      return false;
    }

    if (contact.trim().isEmpty ||
        !RegExp(r'^\d{10,15}$').hasMatch(contact.trim())) {
      _showErrorSnackBar('Please enter a valid phone number');
      return false;
    }

    return true;
  }

  Future<void> _submitOrder(
    String prescriptionId,
    Map<String, dynamic> prescriptionData,
    String quantity,
    String address,
    String contact,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Generate a unique order ID
      final orderId = 'ORD${DateTime.now().millisecondsSinceEpoch}';

      final orderData = {
        'orderId': orderId,
        'patientId': user.uid,
        'prescriptionId': prescriptionId,
        'medicineName': prescriptionData['medicineName'],
        'dosage': prescriptionData['dosage'],
        'frequency': prescriptionData['frequency'],
        'duration': prescriptionData['duration'],
        'quantity': int.parse(quantity),
        'deliveryAddress': address.trim(),
        'contactNumber': contact.trim(),
        'status': 'Ordered',
        'orderDate': FieldValue.serverTimestamp(),
        'estimatedDelivery': DateTime.now().add(const Duration(days: 3)),
        'doctorName': prescriptionData['doctorName'],
        'instructions': prescriptionData['instructions'],
      };

      // Save order to Firestore
      await FirebaseFirestore.instance
          .collection('medicine_orders')
          .add(orderData);

      // Update prescription status
      await FirebaseFirestore.instance
          .collection('prescriptions')
          .doc(prescriptionId)
          .update({'status': 'Ordered'});

      Navigator.pop(context);
      _showSuccessSnackBar('Order placed successfully! Order ID: $orderId');

      // Switch to order history tab
      _tabController.animateTo(1);
    } catch (e) {
      _showErrorSnackBar('Failed to place order: $e');
    }
  }

  void _viewPrescriptionDetails(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Prescription Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Medicine Name', data['medicineName'] ?? 'N/A'),
              _buildDetailRow('Doctor', data['doctorName'] ?? 'N/A'),
              _buildDetailRow('Dosage', data['dosage'] ?? 'N/A'),
              _buildDetailRow('Frequency', data['frequency'] ?? 'N/A'),
              _buildDetailRow('Duration', data['duration'] ?? 'N/A'),
              _buildDetailRow('Instructions', data['instructions'] ?? 'N/A'),
              _buildDetailRow(
                'Prescribed Date',
                _formatDate(data['prescribedDate']),
              ),
              _buildDetailRow('Status', data['status'] ?? 'N/A'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _trackOrder(String orderId, Map<String, dynamic> orderData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Track Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order ID: ${orderData['orderId'] ?? orderId}'),
            const SizedBox(height: 8),
            Text('Medicine: ${orderData['medicineName']}'),
            const SizedBox(height: 8),
            Text('Status: ${orderData['status']}'),
            const SizedBox(height: 8),
            Text(
              'Estimated Delivery: ${_formatDate(orderData['estimatedDelivery'])}',
            ),
            if (orderData['trackingNumber'] != null) ...[
              const SizedBox(height: 8),
              Text('Tracking Number: ${orderData['trackingNumber']}'),
            ],
            const SizedBox(height: 16),
            _buildOrderStatusIndicator(orderData['status']),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStatusIndicator(String? status) {
    final statuses = ['Ordered', 'Processing', 'Shipped', 'Delivered'];
    final currentIndex = statuses.indexOf(status ?? 'Ordered');

    return Column(
      children: statuses.asMap().entries.map((entry) {
        final index = entry.key;
        final statusName = entry.value;
        final isCompleted = index <= currentIndex;
        final isActive = index == currentIndex;

        return Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? Colors.green
                    : isActive
                    ? Colors.orange
                    : Colors.grey.shade300,
              ),
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              statusName,
              style: TextStyle(
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isCompleted ? Colors.green : Colors.grey,
              ),
            ),
          ],
        );
      }).toList(),
    );
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

    if (timestamp is DateTime) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }

    return timestamp.toString();
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
