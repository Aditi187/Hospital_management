import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hospital_management/theme.dart';
import '../widgets/user_chat_widget.dart';
import 'dart:async';

class AppointmentHistoryPage extends StatefulWidget {
  const AppointmentHistoryPage({Key? key}) : super(key: key);

  @override
  State<AppointmentHistoryPage> createState() => _AppointmentHistoryPageState();
}

class _AppointmentHistoryPageState extends State<AppointmentHistoryPage> {
  StreamSubscription? _notifSub;

  Future<void> _clearMyAppointments(BuildContext context, String uid) async {
    try {
      final appointments = await FirebaseFirestore.instance
          .collection('appointments')
          .where('patientId', isEqualTo: uid)
          .get();
      for (final doc in appointments.docs) {
        await doc.reference.delete();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Your appointments have been cleared.'),
          backgroundColor: AppTheme.primaryVariant,
        ),
      );
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error clearing appointments: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Appointment History'),
          backgroundColor: AppTheme.primary,
          foregroundColor: AppTheme.onPrimary,
        ),
        body: const Center(
          child: Text('Please log in to view your appointments'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Appointments'),
        backgroundColor: AppTheme.primary,
        foregroundColor: AppTheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Clear My Appointments',
            onPressed: () => _clearMyAppointments(context, currentUser.uid),
          ),
        ],
      ),
      body: Column(
        children: [
          // Main content
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('appointments')
                  .where('patientId', isEqualTo: currentUser.uid)
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
                        Text('Error: ${snapshot.error}'),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Close'),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 64,
                          color: AppTheme.muted,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No appointments found',
                          style: TextStyle(fontSize: 18, color: AppTheme.muted),
                        ),
                        const Text(
                          'Book your first appointment to see it here',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Go Back'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: AppTheme.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final appointment = snapshot.data!.docs[index];
                    final data = appointment.data() as Map<String, dynamic>;

                    return _buildAppointmentCard(context, data, appointment.id);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // set up listener for incoming message notifications (unread)
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _notifSub = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('notifications')
          .where('type', isEqualTo: 'message')
          .where('read', isEqualTo: false)
          .snapshots()
          .listen((snap) async {
            if (!mounted) return;
            for (final change in snap.docChanges) {
              if (change.type == DocumentChangeType.added) {
                final doc = change.doc;
                final data = doc.data() as Map<String, dynamic>? ?? {};
                final body = data['body'] ?? 'New message';
                final chatId = data['chatId'] as String?;

                // show a SnackBar with an Open action
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(body),
                    action: SnackBarAction(
                      label: 'Open',
                      onPressed: () async {
                        // mark as read and open chat
                        try {
                          await doc.reference.update({'read': true});
                        } catch (_) {}
                        if (chatId != null) {
                          await _openChatByChatId(chatId);
                        }
                      },
                    ),
                    duration: const Duration(seconds: 6),
                  ),
                );
              }
            }
          });
    }
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    super.dispose();
  }

  Future<void> _openChat(
    BuildContext context, {
    required String doctorId,
    required String doctorName,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.7,
          child: UserChatWidget(
            currentUserId: currentUser.uid,
            otherUserId: doctorId,
            otherUserName: doctorName,
          ),
        ),
      ),
    );
  }

  Future<void> _openChatByChatId(String chatId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    final chatDoc = await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .get();
    if (!chatDoc.exists) return;
    final data = chatDoc.data() as Map<String, dynamic>? ?? {};
    final participants = (data['participants'] as List?)?.cast<String>() ?? [];
    final other = participants.firstWhere(
      (p) => p != currentUser.uid,
      orElse: () => '',
    );
    if (other.isEmpty) return;
    final userSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(other)
        .get();
    final name =
        (userSnap.exists ? (userSnap.data()?['name'] as String?) : null) ??
        'User';
    // open chat dialog
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.7,
          child: UserChatWidget(
            currentUserId: currentUser.uid,
            otherUserId: other,
            otherUserName: name,
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(
    BuildContext context,
    Map<String, dynamic> data,
    String appointmentId,
  ) {
    final DateTime date = (data['date'] as Timestamp).toDate();
    final String status = data['status'] ?? 'pending';

    Color statusColor;
    IconData statusIcon;

    switch (status.toLowerCase()) {
      case 'confirmed':
        statusColor = AppTheme.primaryVariant;
        statusIcon = Icons.check_circle;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'completed':
        statusColor = AppTheme.primaryVariant;
        statusIcon = Icons.done_all;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with specialty and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    data['specialty'] ?? 'General Medicine',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
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

            // Date and time
            Row(
              children: [
                Icon(Icons.calendar_today, color: AppTheme.muted, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 24),
                Icon(Icons.access_time, color: Colors.grey[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  data['timeSlot'] ?? 'Time not set',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Symptoms
            if (data['symptoms'] != null &&
                data['symptoms'].toString().isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.healing, color: AppTheme.muted, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Symptoms:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          data['symptoms'],
                          style: const TextStyle(fontSize: 14),
                        ),
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
                  Icon(Icons.note, color: AppTheme.muted, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Notes:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          data['notes'],
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Appointment ID
            Text(
              'Appointment ID: ${data['appointmentId'] ?? appointmentId.substring(0, 8)}',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.muted,
                fontFamily: 'monospace',
              ),
            ),

            // Action buttons
            if (status.toLowerCase() == 'pending') ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _cancelAppointment(context, appointmentId),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () =>
                        _rescheduleAppointment(context, appointmentId, data),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: AppTheme.onPrimary,
                    ),
                    child: const Text('Reschedule'),
                  ),
                ],
              ),
            ],

            // Feedback section for completed appointments
            if (status.toLowerCase() == 'completed') ...[
              const SizedBox(height: 16),
              _buildFeedbackSection(context, appointmentId, data),
            ],

            // Medicine Report section for confirmed and completed appointments
            if (status.toLowerCase() == 'confirmed' ||
                status.toLowerCase() == 'completed') ...[
              const SizedBox(height: 16),
              _buildMedicineReportSection(context, appointmentId, data),
              const SizedBox(height: 12),
              // Chat button to message the doctor for confirmed/completed appointments
              if ((data['doctorId'] ?? '').toString().isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () => _openChat(
                      context,
                      doctorId: (data['doctorId'] ?? '').toString(),
                      doctorName: (data['doctorName'] ?? 'Doctor').toString(),
                    ),
                    icon: const Icon(Icons.chat),
                    label: const Text('Chat with Doctor'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: AppTheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  void _cancelAppointment(BuildContext context, String appointmentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: const Text(
          'Are you sure you want to cancel this appointment?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('appointments')
                    .doc(appointmentId)
                    .update({'status': 'cancelled'});

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Appointment cancelled successfully'),
                    backgroundColor: Colors.orange,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error cancelling appointment: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _rescheduleAppointment(
    BuildContext context,
    String appointmentId,
    Map<String, dynamic> data,
  ) {
    // This would open a dialog or navigate to a reschedule page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reschedule functionality would be implemented here'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildMedicineReportSection(
    BuildContext context,
    String appointmentId,
    Map<String, dynamic> data,
  ) {
    final bool hasMedicineReport = data['medicineReport'] != null;

    if (hasMedicineReport) {
      final medicineReport = data['medicineReport'] as Map<String, dynamic>;
      final List<dynamic> prescriptions = medicineReport['prescriptions'] ?? [];
      final String doctorNotes = medicineReport['doctorNotes'] ?? '';
      final String diagnosis = medicineReport['diagnosis'] ?? '';
      final DateTime reportDate =
          (medicineReport['date'] as Timestamp?)?.toDate() ?? DateTime.now();

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.primaryLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.primaryLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.medication,
                  color: AppTheme.primaryVariant,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Medicine Report',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const Spacer(),
                Text(
                  '${reportDate.day}/${reportDate.month}/${reportDate.year}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Diagnosis
            if (diagnosis.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.medical_information,
                    color: AppTheme.primaryVariant,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Diagnosis:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        Text(diagnosis, style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Prescriptions
            if (prescriptions.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.local_pharmacy,
                    color: AppTheme.primaryVariant,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Prescribed Medications:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ...prescriptions.map((prescription) {
                final med = prescription as Map<String, dynamic>;
                return Container(
                  margin: const EdgeInsets.only(left: 24, bottom: 6),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.primaryLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        med['name'] ?? 'Unknown Medicine',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      if (med['dosage'] != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Dosage: ${med['dosage']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                      if (med['frequency'] != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Frequency: ${med['frequency']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                      if (med['duration'] != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Duration: ${med['duration']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                      if (med['instructions'] != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Instructions: ${med['instructions']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 8),
            ],

            // Doctor Notes
            if (doctorNotes.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.note_alt,
                    color: AppTheme.primaryVariant,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Doctor Notes:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        Text(doctorNotes, style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _viewFullMedicineReport(
                    context,
                    appointmentId,
                    medicineReport,
                  ),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('View Full Report'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryVariant,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _downloadMedicineReport(
                    context,
                    appointmentId,
                    medicineReport,
                    data,
                  ),
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Download'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.primaryLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.primaryLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppTheme.primaryVariant,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Medical Records',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Why are medical records not showing?',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '• Medical records are only available after doctor consultation\n'
              '• Records include diagnosis, prescriptions, and doctor notes',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Status: ${data['status']?.toString().toUpperCase() ?? 'PENDING'}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _getStatusColor(data['status'] ?? 'pending'),
                    ),
                  ),
                ),
                // ...existing code...
              ],
            ),
          ],
        ),
      );
    }
  }

  void _viewFullMedicineReport(
    BuildContext context,
    String appointmentId,
    Map<String, dynamic> medicineReport,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (medicineReport['prescriptions'] != null) ...[
                  const Row(
                    children: [
                      Icon(Icons.local_pharmacy, color: Colors.teal),
                      SizedBox(width: 8),
                      Text(
                        'Prescribed Medications',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...((medicineReport['prescriptions'] as List<dynamic>).map((
                    prescription,
                  ) {
                    final med = prescription as Map<String, dynamic>;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.teal.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            med['name'] ?? 'Unknown Medicine',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (med['dosage'] != null)
                            _buildMedicineDetail('Dosage', med['dosage']),
                          if (med['frequency'] != null)
                            _buildMedicineDetail('Frequency', med['frequency']),
                          if (med['duration'] != null)
                            _buildMedicineDetail('Duration', med['duration']),
                          if (med['instructions'] != null)
                            _buildMedicineDetail(
                              'Instructions',
                              med['instructions'],
                            ),
                        ],
                      ),
                    );
                  })),
                  const SizedBox(height: 16),
                ],
                if (medicineReport['doctorNotes'] != null &&
                    medicineReport['doctorNotes'].toString().isNotEmpty) ...[
                  _buildReportSection(
                    'Doctor Notes',
                    Icons.note_alt,
                    medicineReport['doctorNotes'].toString(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportSection(String title, IconData icon, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.teal),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(content, style: const TextStyle(fontSize: 14)),
        ),
      ],
    );
  }

  Widget _buildMedicineDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  void _downloadMedicineReport(
    BuildContext context,
    String appointmentId,
    Map<String, dynamic> medicineReport,
    Map<String, dynamic> appointmentData,
  ) {
    // In a real app, this would generate and download a PDF
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Medicine report download started'),
        backgroundColor: Colors.teal,
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () =>
              _viewFullMedicineReport(context, appointmentId, medicineReport),
        ),
      ),
    );
  }

  // ...existing code...

  Widget _buildFeedbackSection(
    BuildContext context,
    String appointmentId,
    Map<String, dynamic> data,
  ) {
    final bool hasFeedback = data['feedback'] != null;

    if (hasFeedback) {
      final feedback = data['feedback'] as Map<String, dynamic>;
      final int rating = feedback['rating'] ?? 0;
      final String comment = feedback['comment'] ?? '';
      final DateTime feedbackDate =
          (feedback['date'] as Timestamp?)?.toDate() ?? DateTime.now();

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.primaryLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.primaryLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.feedback, color: AppTheme.primaryVariant, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Your Feedback',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const Spacer(),
                Text(
                  '${feedbackDate.day}/${feedbackDate.month}/${feedbackDate.year}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Star rating display
            Row(
              children: [
                ...List.generate(5, (index) {
                  return Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 20,
                  );
                }),
                const SizedBox(width: 8),
                Text(
                  '$rating/5',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),

            if (comment.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(comment, style: const TextStyle(fontSize: 14)),
            ],

            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () =>
                      _editFeedback(context, appointmentId, feedback),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryVariant,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.primaryLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.primaryLight),
        ),
        child: Row(
          children: [
            Icon(Icons.rate_review, color: AppTheme.primaryVariant, size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'How was your appointment?',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () =>
                  _showFeedbackDialog(context, appointmentId, data),
              icon: const Icon(Icons.star, size: 16),
              label: const Text('Rate'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryVariant,
                foregroundColor: AppTheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  void _showFeedbackDialog(
    BuildContext context,
    String appointmentId,
    Map<String, dynamic> appointmentData,
  ) {
    int selectedRating = 0;
    final commentController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.feedback, color: AppTheme.primaryVariant),
              const SizedBox(width: 12),
              const Text('Rate Your Experience'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Appointment info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointmentData['specialty'] ?? 'General Medicine',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Appointment on ${_formatDate((appointmentData['date'] as Timestamp).toDate())}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Rating section
                const Text(
                  'Overall Rating',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedRating = index + 1;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          index < selectedRating
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 40,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    _getRatingText(selectedRating),
                    style: TextStyle(
                      color: _getRatingColor(selectedRating),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Comment section
                const Text(
                  'Additional Comments (Optional)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: commentController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText:
                        'Share your experience, suggestions, or any concerns...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 16),

                // Quick feedback options
                const Text(
                  'Quick Feedback',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildQuickFeedbackChip(
                      'Professional Staff',
                      Icons.people,
                      () => _addQuickFeedback(
                        commentController,
                        'Professional and courteous staff',
                      ),
                    ),
                    _buildQuickFeedbackChip(
                      'On Time',
                      Icons.schedule,
                      () => _addQuickFeedback(
                        commentController,
                        'Appointment was on time',
                      ),
                    ),
                    _buildQuickFeedbackChip(
                      'Clean Facility',
                      Icons.cleaning_services,
                      () => _addQuickFeedback(
                        commentController,
                        'Clean and well-maintained facility',
                      ),
                    ),
                    _buildQuickFeedbackChip(
                      'Thorough Examination',
                      Icons.medical_services,
                      () => _addQuickFeedback(
                        commentController,
                        'Thorough and comprehensive examination',
                      ),
                    ),
                    _buildQuickFeedbackChip(
                      'Clear Explanation',
                      Icons.chat,
                      () => _addQuickFeedback(
                        commentController,
                        'Doctor provided clear explanations',
                      ),
                    ),
                    _buildQuickFeedbackChip(
                      'Easy Booking',
                      Icons.calendar_month,
                      () => _addQuickFeedback(
                        commentController,
                        'Easy appointment booking process',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSubmitting || selectedRating == 0
                  ? null
                  : () async {
                      setState(() {
                        isSubmitting = true;
                      });
                      await _submitFeedback(
                        context,
                        appointmentId,
                        selectedRating,
                        commentController.text.trim(),
                        appointmentData,
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Submit Feedback'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickFeedbackChip(
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.primaryLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primaryLight),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppTheme.primaryVariant),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.primaryVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addQuickFeedback(TextEditingController controller, String feedback) {
    final currentText = controller.text;
    final newText = currentText.isEmpty
        ? feedback
        : currentText.endsWith('.') ||
              currentText.endsWith('!') ||
              currentText.endsWith('?')
        ? '$currentText $feedback'
        : '$currentText. $feedback';
    controller.text = newText;
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return 'Select a rating';
    }
  }

  Color _getRatingColor(int rating) {
    switch (rating) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.yellow.shade700;
      case 4:
        return Colors.lightGreen;
      case 5:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _submitFeedback(
    BuildContext context,
    String appointmentId,
    int rating,
    String comment,
    Map<String, dynamic> appointmentData,
  ) async {
    try {
      final feedbackData = {
        'rating': rating,
        'comment': comment,
        'date': FieldValue.serverTimestamp(),
        'patientId': FirebaseAuth.instance.currentUser?.uid,
        'specialty': appointmentData['specialty'],
        'appointmentDate': appointmentData['date'],
      };

      // Update appointment with feedback
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId)
          .update({'feedback': feedbackData});

      // Also save to a separate feedback collection for analytics
      await FirebaseFirestore.instance.collection('feedback').add({
        ...feedbackData,
        'appointmentId': appointmentId,
        'submittedAt': FieldValue.serverTimestamp(),
      });

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'Thank you for your ${_getRatingText(rating).toLowerCase()} feedback!',
              ),
            ],
          ),
          backgroundColor: AppTheme.primaryVariant,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting feedback: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _editFeedback(
    BuildContext context,
    String appointmentId,
    Map<String, dynamic> existingFeedback,
  ) {
    int selectedRating = existingFeedback['rating'] ?? 0;
    final commentController = TextEditingController(
      text: existingFeedback['comment'] ?? '',
    );
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.edit, color: AppTheme.primaryVariant),
              const SizedBox(width: 12),
              const Text('Edit Your Feedback'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rating section
                const Text(
                  'Overall Rating',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedRating = index + 1;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          index < selectedRating
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 40,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    _getRatingText(selectedRating),
                    style: TextStyle(
                      color: _getRatingColor(selectedRating),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Comment section
                const Text(
                  'Comments',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: commentController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Update your feedback...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: isSubmitting
                  ? null
                  : () => _deleteFeedback(context, appointmentId),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
            ElevatedButton(
              onPressed: isSubmitting || selectedRating == 0
                  ? null
                  : () async {
                      setState(() {
                        isSubmitting = true;
                      });
                      await _updateFeedback(
                        context,
                        appointmentId,
                        selectedRating,
                        commentController.text.trim(),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryVariant,
                foregroundColor: AppTheme.onPrimary,
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateFeedback(
    BuildContext context,
    String appointmentId,
    int rating,
    String comment,
  ) async {
    try {
      final feedbackData = {
        'rating': rating,
        'comment': comment,
        'date': FieldValue.serverTimestamp(),
        'updated': true,
      };

      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId)
          .update({'feedback': feedbackData});

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              const Text('Feedback updated successfully!'),
            ],
          ),
          backgroundColor: AppTheme.primaryVariant,
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating feedback: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _deleteFeedback(BuildContext context, String appointmentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Feedback'),
        content: const Text(
          'Are you sure you want to delete your feedback? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('appointments')
                    .doc(appointmentId)
                    .update({'feedback': FieldValue.delete()});

                Navigator.pop(context); // Close delete dialog
                Navigator.pop(context); // Close edit dialog

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Feedback deleted successfully'),
                    backgroundColor: AppTheme.primaryVariant,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting feedback: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Helper method to get status color
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return AppTheme.primaryVariant;
      case 'completed':
        return AppTheme.primaryVariant;
      case 'cancelled':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }
}
