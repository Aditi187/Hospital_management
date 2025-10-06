import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String currentDoctorId = '';
  Map<String, dynamic> doctorData = {};
  List<Map<String, dynamic>> patients = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    currentDoctorId = user?.uid ?? '';
    if (currentDoctorId.isNotEmpty) {
      _loadDoctorProfileAndPatients();
    }
  }

  Future<void> _loadDoctorProfileAndPatients() async {
    setState(() {
      isLoading = true;
    });
    try {
      final docSnap = await _firestore.collection('doctors').doc(currentDoctorId).get();
      if (docSnap.exists) {
        doctorData = docSnap.data() ?? {};
      } else {
        final userSnap = await _firestore.collection('users').doc(currentDoctorId).get();
        doctorData = userSnap.exists ? (userSnap.data() ?? {}) : {};
      }

      // Load patients who have appointments with this doctor
      final apptSnap = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: currentDoctorId)
          .get();

      final patientIds = apptSnap.docs.map((doc) {
        final data = doc.data();
        return data['patientId'] as String?;
      }).whereType<String>().where((pid) => pid != currentDoctorId).toSet();

      patients = [];

      for (var pid in patientIds) {
        final patientSnap = await _firestore.collection('users').doc(pid).get();
        if (patientSnap.exists) {
          final pdata = patientSnap.data()!;
          patients.add({'id': pid, 'data': pdata});
        }
      }
    } catch (e) {
      // ignore errors, keep doctorData and patients as is
    }
    setState(() {
      isLoading = false;
    });
  }

  void _showPatientDetailsDialog(Map<String, dynamic> patient) {
    showDialog(
      context: context,
      builder: (context) {
        return PatientDetailsDialog(
          patientId: patient['id'],
          patientData: patient['data'],
          doctorName: doctorData['name'] ?? doctorData['email'] ?? 'Doctor',
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Doctor Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeSection(),
                  const SizedBox(height: 24),
                  Text(
                    'My Patients',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal.shade800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  patients.isEmpty
                      ? const Text('No patients found.')
                      : GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          childAspectRatio: 3,
                          children: List.generate(patients.length, (index) {
                            final patient = patients[index];
                            final pdata = patient['data'] as Map<String, dynamic>;
                            final name = pdata['name'] ?? 'Unknown Patient';
                            final email = pdata['email'] ?? '';
                            return InkWell(
                              onTap: () => _showPatientDetailsDialog(patient),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.teal.shade50, Colors.teal.shade100],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.teal.shade100.withValues(alpha: 0.5),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                  border: Border.all(color: Colors.teal.shade200, width: 1.5),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: Colors.teal.shade200,
                                      child: Text(
                                        name.isNotEmpty ? name[0].toUpperCase() : 'P',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            name,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.teal.shade900,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Text(
                                            email,
                                            style: TextStyle(
                                              color: Colors.teal.shade700,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade600, Colors.teal.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.shade600.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: 3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome,',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 24,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            doctorData['name'] ?? 'Doctor',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            doctorData['email'] ?? '',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade600, Colors.teal.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.medical_services, size: 35, color: Colors.teal),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Doctor Portal',
                  style: TextStyle(
                    color: Colors.teal,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  doctorData['email'] ?? 'Doctor',
                  style: const TextStyle(color: Colors.tealAccent, fontSize: 14),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.dashboard, color: Colors.teal.shade600),
            title: const Text('Dashboard'),
            onTap: () => Navigator.pop(context),
            hoverColor: Colors.teal.shade50,
          ),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.teal.shade600),
            title: const Text('Logout'),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
            hoverColor: Colors.teal.shade50,
          ),
        ],
      ),
    );
  }
}

class PatientDetailsDialog extends StatefulWidget {
  final String patientId;
  final Map<String, dynamic> patientData;
  final String doctorName;

  const PatientDetailsDialog({
    super.key,
    required this.patientId,
    required this.patientData,
    required this.doctorName,
  });

  @override
  State<PatientDetailsDialog> createState() => _PatientDetailsDialogState();
}

class _PatientDetailsDialogState extends State<PatientDetailsDialog> with TickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> appointments = [];
  bool isLoadingAppointments = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadAppointments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      isLoadingAppointments = true;
    });
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .where('patientId', isEqualTo: widget.patientId)
          .where('doctorId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .where('status', isEqualTo: 'pending')
          .get();

      appointments = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'date': data['date'],
          'timeSlot': data['timeSlot'],
          'status': data['status'],
          'isApproved': data['isApproved'] ?? false,
          'isRejected': data['isRejected'] ?? false,
          'notes': data['notes'] ?? '',
        };
      }).toList();
    } catch (e) {
      appointments = [];
    }
    setState(() {
      isLoadingAppointments = false;
    });
  }

  Future<void> _approveAppointment(String appointmentId) async {
    try {
      await FirebaseFirestore.instance.collection('appointments').doc(appointmentId).update({
        'status': 'confirmed',
        'isApproved': true,
        'approvedAt': FieldValue.serverTimestamp(),
      });

      // create a notification for the patient
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.patientId)
          .collection('notifications')
          .add({
            'title': 'Appointment Approved',
            'body':
                'Your appointment has been approved by Dr. ${widget.doctorName}.',
            'type': 'appointment',
            'appointmentId': appointmentId,
            'createdAt': FieldValue.serverTimestamp(),
            'read': false,
          });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Appointment approved')));
      await _loadAppointments();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error approving appointment: $e')));
    }
  }

  Future<void> _rejectAppointment(String appointmentId) async {
    try {
      await FirebaseFirestore.instance.collection('appointments').doc(appointmentId).update({
        'status': 'rejected',
        'isApproved': false,
        'rejectedAt': FieldValue.serverTimestamp(),
      });

      // create a notification for the patient
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.patientId)
          .collection('notifications')
          .add({
            'title': 'Appointment Not Approved',
            'body':
                'Your appointment was not approved by Dr. ${widget.doctorName}. Please reschedule or contact the clinic.',
            'type': 'appointment',
            'appointmentId': appointmentId,
            'createdAt': FieldValue.serverTimestamp(),
            'read': false,
          });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Appointment rejected and patient notified')));
      await _loadAppointments();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error rejecting appointment: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final patient = widget.patientData;
    final patientId = widget.patientId;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.maxFinite,
        height: 600,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.teal.shade50,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.teal.shade200,
                    child: Text(
                      patient['name']?.isNotEmpty == true ? patient['name'][0].toUpperCase() : 'P',
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
                          patient['name'] ?? 'Unknown Patient',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                        Text(
                          patient['email'] ?? '',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        Text(
                          'Patient ID: $patientId',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              labelColor: Colors.teal,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.teal,
              tabs: const [
                Tab(icon: Icon(Icons.person), text: 'Profile'),
                Tab(icon: Icon(Icons.medical_services), text: 'Medical Records'),
                Tab(icon: Icon(Icons.medication), text: 'Prescriptions'),
                Tab(icon: Icon(Icons.add_circle), text: 'Add Record'),
                Tab(icon: Icon(Icons.event_note), text: 'Appointments'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  PatientProfileTab(patient: patient),
                  MedicalRecordsTab(patientId: patientId),
                  PrescriptionsTab(patientId: patientId),
                  AddRecordTab(patientId: patientId, doctorName: widget.doctorName),
                  _buildAppointmentsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentsTab() {
    if (isLoadingAppointments) {
      return const Center(child: CircularProgressIndicator());
    }

    if (appointments.isEmpty) {
      return const Center(child: Text('No pending appointments.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appt = appointments[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Date: ${appt['date'] ?? 'N/A'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('Time Slot: ${appt['timeSlot'] ?? 'N/A'}'),
                if (appt['notes'] != null && appt['notes'].isNotEmpty)
                  Text('Notes: ${appt['notes']}'),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () => _approveAppointment(appt['id']),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text('Approve'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () => _rejectAppointment(appt['id']),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Reject'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}



class PatientProfileTab extends StatelessWidget {
  final Map<String, dynamic> patient;

  const PatientProfileTab({
    super.key,
    required this.patient,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Patient Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.teal.shade800,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Name', patient['name'] ?? 'N/A'),
          _buildInfoRow('Email', patient['email'] ?? 'N/A'),
          _buildInfoRow('Phone', patient['phone'] ?? 'N/A'),
          _buildInfoRow('Date of Birth', patient['dateOfBirth'] ?? 'N/A'),
          _buildInfoRow('Gender', patient['gender'] ?? 'N/A'),
          _buildInfoRow('Address', patient['address'] ?? 'N/A'),
          _buildInfoRow('Disease', patient['disease'] ?? 'N/A'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
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
}

class MedicalRecordsTab extends StatelessWidget {
  final String patientId;

  const MedicalRecordsTab({
    super.key,
    required this.patientId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('medical_reports')
          .where('patientId', isEqualTo: patientId)
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

        // Sort reports by timestamp descending
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
                          color: Colors.teal,
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
}

class PrescriptionsTab extends StatelessWidget {
  final String patientId;

  const PrescriptionsTab({
    super.key,
    required this.patientId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('prescriptions')
          .where('patientId', isEqualTo: patientId)
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
        prescriptions.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTs = aData['prescribedDate'] as Timestamp?;
          final bTs = bData['prescribedDate'] as Timestamp?;
          if (aTs == null) return 1;
          if (bTs == null) return -1;
          return bTs.compareTo(aTs);
        });

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
}

class AddRecordTab extends StatefulWidget {
  final String patientId;
  final String doctorName;

  const AddRecordTab({
    super.key,
    required this.patientId,
    required this.doctorName,
  });

  @override
  State<AddRecordTab> createState() => _AddRecordTabState();
}

class _AddRecordTabState extends State<AddRecordTab> with TickerProviderStateMixin {
  late TabController _recordTabController;
  final _medicalFormKey = GlobalKey<FormState>();
  final _prescriptionFormKey = GlobalKey<FormState>();

  // Medical Record Controllers
  final _titleController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _treatmentController = TextEditingController();
  final _notesController = TextEditingController();

  // Prescription Controllers
  final _medicineNameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _frequencyController = TextEditingController();
  final _durationController = TextEditingController();
  final _instructionsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _recordTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _recordTabController.dispose();
    _titleController.dispose();
    _diagnosisController.dispose();
    _treatmentController.dispose();
    _notesController.dispose();
    _medicineNameController.dispose();
    _dosageController.dispose();
    _frequencyController.dispose();
    _durationController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _saveMedicalRecord() async {
    // Remove validation for title field to allow empty input
    // if (!_medicalFormKey.currentState!.validate()) return;

    try {
      await FirebaseFirestore.instance.collection('medical_reports').add({
        'patientId': widget.patientId,
        'doctorId': FirebaseAuth.instance.currentUser?.uid,
        'doctorName': widget.doctorName,
        'title': _titleController.text.trim(),
        'diagnosis': _diagnosisController.text.trim(),
        'treatment': _treatmentController.text.trim(),
        'notes': _notesController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medical record added successfully')),
      );

      // Clear form
      _titleController.clear();
      _diagnosisController.clear();
      _treatmentController.clear();
      _notesController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding medical record: $e')),
      );
    }
  }

  Future<void> _savePrescription() async {
    if (!_prescriptionFormKey.currentState!.validate()) return;

    try {
      await FirebaseFirestore.instance.collection('prescriptions').add({
        'patientId': widget.patientId,
        'doctorId': FirebaseAuth.instance.currentUser?.uid,
        'doctorName': widget.doctorName,
        'medicineName': _medicineNameController.text.trim(),
        'dosage': _dosageController.text.trim(),
        'frequency': _frequencyController.text.trim(),
        'duration': _durationController.text.trim(),
        'instructions': _instructionsController.text.trim(),
        'status': 'Prescribed',
        'prescribedDate': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prescription added successfully')),
      );

      // Clear form
      _medicineNameController.clear();
      _dosageController.clear();
      _frequencyController.clear();
      _durationController.clear();
      _instructionsController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding prescription: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _recordTabController,
          labelColor: Colors.teal,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.teal,
          tabs: const [
            Tab(icon: Icon(Icons.medical_services), text: 'Medical Record'),
            Tab(icon: Icon(Icons.medication), text: 'Prescription'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _recordTabController,
            children: [
              // Medical Record Tab
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _medicalFormKey,
                  child: ListView(
                    children: [
                      Text(
                        'Add Medical Record',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _diagnosisController,
                        decoration: const InputDecoration(
                          labelText: 'Diagnosis',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _treatmentController,
                        decoration: const InputDecoration(
                          labelText: 'Treatment',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 4,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _saveMedicalRecord,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Save Medical Record'),
                      ),
                    ],
                  ),
                ),
              ),

              // Prescription Tab
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _prescriptionFormKey,
                  child: ListView(
                    children: [
                      Text(
                        'Add Prescription',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _medicineNameController,
                        decoration: const InputDecoration(
                          labelText: 'Medicine Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter medicine name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _dosageController,
                        decoration: const InputDecoration(
                          labelText: 'Dosage (e.g., 500mg)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter dosage';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _frequencyController,
                        decoration: const InputDecoration(
                          labelText: 'Frequency (e.g., twice daily)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter frequency';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _durationController,
                        decoration: const InputDecoration(
                          labelText: 'Duration (e.g., 7 days)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter duration';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _instructionsController,
                        decoration: const InputDecoration(
                          labelText: 'Instructions',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _savePrescription,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Save Prescription'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
