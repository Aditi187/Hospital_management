import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DoctorConsultationPage extends StatefulWidget {
  const DoctorConsultationPage({Key? key}) : super(key: key);

  @override
  State<DoctorConsultationPage> createState() => _DoctorConsultationPageState();
}

class _DoctorConsultationPageState extends State<DoctorConsultationPage> {
  String? selectedDoctorId;
  String? selectedDoctorName;
  String selectedSpecialty = 'Cardiology';
  String selectedTimeSlot = '09:00 AM';
  DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
  final TextEditingController symptomsController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  bool isBooking = false;
  final List<String> specialties = [
    'Cardiology',
    'Dermatology',
    'Orthopedics',
    'Pediatrics',
    'Gynecology',
    'Neurology',
    'Psychiatry',
    'Radiology',
  ];
  final List<String> timeSlots = [
    '09:00 AM',
    '09:30 AM',
    '10:00 AM',
    '10:30 AM',
    '11:00 AM',
    '11:30 AM',
    '02:00 PM',
    '02:30 PM',
    '03:00 PM',
    '03:30 PM',
    '04:00 PM',
    '04:30 PM',
    '05:00 PM',
    '05:30 PM',
    '06:00 PM',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Consultation'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    colors: [
                      Colors.deepPurple.shade100,
                      Colors.deepPurple.shade50,
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.local_hospital,
                      size: 48,
                      color: Colors.deepPurple,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'HEALTHCARE MEDICAL CENTRE',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.deepPurple,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Book Your Consultation',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const Text(
                      'Choose your preferred doctor and time slot',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('Select Specialty'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: DropdownButtonFormField<String>(
                  value: selectedSpecialty,
                  decoration: const InputDecoration(
                    labelText: 'Medical Specialty',
                    border: OutlineInputBorder(),
                  ),
                  items: specialties
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => selectedSpecialty = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('Select Doctor'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('doctors')
                      .where('specialty', isEqualTo: selectedSpecialty)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Text('Error loading doctors');
                    }
                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return const Text('No doctors found for this specialty');
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: docs.length,
                      separatorBuilder: (context, index) => Divider(),
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        final docId = docs[index].id;
                        final isSelected = selectedDoctorId == docId;
                        return ListTile(
                          leading: CircleAvatar(child: Icon(Icons.person)),
                          title: Text(data['name'] ?? 'Doctor'),
                          subtitle: Text(data['specialty'] ?? ''),
                          trailing: isSelected
                              ? Icon(
                                  Icons.check_circle,
                                  color: Colors.deepPurple,
                                )
                              : null,
                          selected: isSelected,
                          selectedTileColor: Colors.deepPurple.shade50,
                          onTap: () {
                            setState(() {
                              selectedDoctorId = docId;
                              selectedDoctorName = data['name'] ?? 'Doctor';
                            });
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('Select Date and Time'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => _selectDate(context),
                      child: AbsorbPointer(
                        child: TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Appointment Date',
                            border: const OutlineInputBorder(),
                            suffixIcon: const Icon(Icons.calendar_today),
                          ),
                          controller: TextEditingController(
                            text:
                                '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedTimeSlot,
                      decoration: const InputDecoration(
                        labelText: 'Time Slot',
                        border: OutlineInputBorder(),
                      ),
                      items: timeSlots
                          .map(
                            (time) => DropdownMenuItem(
                              value: time,
                              child: Text(time),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => selectedTimeSlot = val);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('Additional Information'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextFormField(
                      controller: symptomsController,
                      decoration: const InputDecoration(
                        labelText: 'Symptoms',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Additional Notes (optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: () => _showBookingConfirmation(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: const Text(
                  'Book Appointment',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
            // ...existing code...
            // ...existing code...
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.deepPurple,
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  void _showBookingConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Appointment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please confirm your appointment details:'),
            const SizedBox(height: 12),
            Text('Specialty: $selectedSpecialty'),
            Text(
              'Date: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
            ),
            Text('Time: $selectedTimeSlot'),
            const SizedBox(height: 8),
            const Text(
              'Symptoms:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(symptomsController.text.trim()),
            if (notesController.text.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Notes:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(notesController.text.trim()),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: isBooking
                ? null
                : () {
                    Navigator.pop(context);
                    _bookAppointment();
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            child: isBooking
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Confirm Booking'),
          ),
        ],
      ),
    );
  }

  void _bookAppointment() async {
    if (selectedDoctorId == null) {
      _showError('Please select a doctor');
      return;
    }
    setState(() {
      isBooking = true;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showError('User not logged in');
        return;
      }
      // Remove any previous appointment for this user, doctor, date, and time
      final prev = await FirebaseFirestore.instance
          .collection('appointments')
          .where('patientId', isEqualTo: user.uid)
          .where('doctorId', isEqualTo: selectedDoctorId)
          .where('date', isEqualTo: selectedDate)
          .where('timeSlot', isEqualTo: selectedTimeSlot)
          .get();
      for (final doc in prev.docs) {
        await doc.reference.delete();
      }
      await FirebaseFirestore.instance.collection('appointments').add({
        'patientId': user.uid,
        'doctorId': selectedDoctorId,
        'specialty': selectedSpecialty,
        'date': selectedDate,
        'timeSlot': selectedTimeSlot,
        'symptoms': symptomsController.text.trim(),
        'notes': notesController.text.trim(),
        'status': 'pending',
      });
      _showSuccess('Appointment booked successfully');
      _resetForm();
    } catch (e) {
      _showError('Error booking appointment: $e');
    } finally {
      setState(() {
        isBooking = false;
      });
    }
  }

  void _resetForm() {
    setState(() {
      selectedDoctorId = null;
      selectedDoctorName = null;
      selectedSpecialty = 'Cardiology';
      selectedTimeSlot = '09:00 AM';
      selectedDate = DateTime.now().add(const Duration(days: 1));
      symptomsController.clear();
      notesController.clear();
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  // ...existing code...
}

// ...existing code...
