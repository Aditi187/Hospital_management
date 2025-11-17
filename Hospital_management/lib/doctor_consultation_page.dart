import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'specialties.dart';
import 'package:hospital_management/theme.dart';
import 'widgets/doctor_availability_calendar.dart';
import 'widgets/doctor_availability_card.dart';
import 'package:intl/intl.dart';

class DoctorConsultationPage extends StatefulWidget {
  const DoctorConsultationPage({Key? key}) : super(key: key);

  @override
  State<DoctorConsultationPage> createState() => _DoctorConsultationPageState();
}

class _DoctorConsultationPageState extends State<DoctorConsultationPage> {
  final _firestore = FirebaseFirestore.instance;
  StreamSubscription? _doctorsSub;
  StreamSubscription? _usersDoctorsSub;
  String? selectedDoctorId;
  String? selectedDoctorName;
  String? selectedDoctorSpecialty;
  String selectedSpecialty = 'All';
  DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
  String selectedTimeSlot = '09:00 AM';
  final symptomsController = TextEditingController();
  final notesController = TextEditingController();
  bool isBooking = false;

  List<String> specialties = ['All', ...canonicalSpecialties];
  final timeSlots = [
    '09:00 AM',
    '09:15 AM',
    '09:30 AM',
    '09:45 AM',
    '10:05 AM',
    '10:20 AM',
    '10:35 AM',
    '10:50 AM',
    '11:15 AM',
    '11:30 AM',
    '11:45 AM',
    '12:00 PM',
    '12:15 PM',
    '12:30 PM',
    '12:45 PM',
    '05:00 PM',
    '05:15 PM',
    '05:30 PM',
    '05:45 PM',
    '06:30 PM',
    '06:45 PM',
    '07:00 PM',
    '07:30 PM',
    '07:45 PM',
    '08:00 PM',
    '08:30 PM',
    '08:45 PM',
    '09:00 PM',
    '09:15 PM',
    '09:30 PM',
    '09:45 PM',
    '10:00 PM',
    '10:15 PM',
    '10:30 PM',
    '10:45 PM',
    '11:00 PM',

  ];

  @override
  void dispose() {
    _doctorsSub?.cancel();
    _usersDoctorsSub?.cancel();
    symptomsController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadSpecialties();
    _doctorsSub = _firestore.collection('doctors').snapshots().listen((snap) {
      _loadSpecialties();
    });
    _usersDoctorsSub = _firestore
        .collection('users')
        .where('role', isEqualTo: 'doctor')
        .snapshots()
        .listen((snap) {
          _loadSpecialties();
        });
  }

  Future<void> _loadSpecialties() async {
    try {
      final found = <String>{};
      final dSnap = await _firestore.collection('doctors').get();
      for (final doc in dSnap.docs) {
        final m = doc.data();
        final s = (m['specialty'] ?? m['specialization'] ?? '')
            .toString()
            .trim();
        if (s.isNotEmpty) found.add(s);
      }

      final uSnap = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'doctor')
          .get();
      for (final doc in uSnap.docs) {
        final m = doc.data();
        final s = (m['specialty'] ?? m['specialization'] ?? '')
            .toString()
            .trim();
        if (s.isNotEmpty) found.add(s);
      }

      final merged = <String>{...canonicalSpecialties, ...found};
      final list = merged.toList()..sort();
      if (mounted) {
        setState(() {
          specialties = ['All', ...list];
          if (!specialties.contains(selectedSpecialty))
            selectedSpecialty = 'All';
        });
      }
    } catch (_) {
      // ignore and keep defaults
    }
  }

  Stream<QuerySnapshot> _doctorsStream() =>
      _firestore.collection('doctors').snapshots();

  bool _matchesSpecialty(Map<String, dynamic> data) {
    if (selectedSpecialty == 'All') return true;
    final s = (data['specialty'] ?? data['specialization'] ?? '')
        .toString()
        .toLowerCase();
    return s.contains(selectedSpecialty.toLowerCase());
  }

  Future<void> _backfillDoctors() async {
    final q = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'doctor')
        .get();
    final batch = _firestore.batch();
    for (final u in q.docs) {
      final d = u.data();
      final ref = _firestore.collection('doctors').doc(u.id);
      batch.set(ref, {
        'name': d['name'] ?? d['email'] ?? '',
        'email': d['email'] ?? '',
        'specialty': d['specialty'] ?? d['specialization'] ?? '',
        'specialty_normalized': (d['specialty'] ?? d['specialization'] ?? '')
            .toString()
            .toLowerCase(),
        'personalId': d['personalId'] ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    await batch.commit();
    if (mounted)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Backfill complete')));
  }

  Future<void> _bookAppointment() async {
    if (selectedDoctorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a doctor first')),
      );
      return;
    }
    setState(() => isBooking = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please sign in first')));
        return;
      }
      await _firestore.collection('appointments').add({
        'doctorId': selectedDoctorId,
        'doctorName': selectedDoctorName ?? '',
        'doctorSpecialty': selectedDoctorSpecialty ?? '',
        'patientId': user.uid,
        'patientName': user.displayName ?? user.email ?? '',
        'specialty': selectedDoctorSpecialty ?? '',
        'date': Timestamp.fromDate(selectedDate),
        'timeSlot': selectedTimeSlot,
        'symptoms': symptomsController.text.trim(),
        'notes': notesController.text.trim(),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Appointment booked with Dr. $selectedDoctorName'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      _resetForm();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Booking failed: $e')));
    } finally {
      if (mounted) setState(() => isBooking = false);
    }
  }

  void _resetForm() {
    setState(() {
      selectedDoctorId = null;
      selectedDoctorName = null;
      selectedDoctorSpecialty = null;
      selectedSpecialty = 'All';
      selectedTimeSlot = timeSlots.first;
      selectedDate = DateTime.now().add(const Duration(days: 1));
      symptomsController.clear();
      notesController.clear();
    });
  }

  void _clearDoctorSelection() {
    setState(() {
      selectedDoctorId = null;
      selectedDoctorName = null;
      selectedDoctorSpecialty = null;
    });
  }

  Future<void> _openAvailabilityCalendar() async {
    if (selectedDoctorId == null || selectedDoctorName == null) return;

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => DoctorAvailabilityCalendar(
          doctorId: selectedDoctorId!,
          doctorName: selectedDoctorName!,
          onSlotSelected: (date, timeSlot) {
            // Close the calendar and return the selected slot
            Navigator.pop(context, {'date': date, 'timeSlot': timeSlot});
          },
        ),
      ),
    );

    // If user selected a slot, update the form
    if (result != null && mounted) {
      setState(() {
        selectedDate = result['date'] as DateTime;
        selectedTimeSlot = result['timeSlot'] as String;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Selected: ${DateFormat('MMM dd, yyyy').format(selectedDate)} at $selectedTimeSlot',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null && mounted) setState(() => selectedDate = d);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Doctor Consultation')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selected Doctor Section
            if (selectedDoctorId != null) ...[
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.medical_services,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Dr. $selectedDoctorName',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  selectedDoctorSpecialty ?? '',
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.clear, color: Colors.red),
                            onPressed: _clearDoctorSelection,
                            tooltip: 'Change doctor',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _openAvailabilityCalendar,
                        icon: const Icon(Icons.calendar_month),
                        label: const Text('View Availability Calendar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 45),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Appointment Details:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
            ],

            // Doctor Selection Section (only show when no doctor is selected)
            if (selectedDoctorId == null) ...[
              Row(
                children: [
                  const Text('Filter by Specialty: '),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: selectedSpecialty,
                    items: specialties
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => selectedSpecialty = v ?? 'All'),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () async {
                      await _backfillDoctors();
                      await _loadSpecialties();
                    },
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh doctors & specialties',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Select a Doctor:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _doctorsStream(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting)
                      return const Center(child: CircularProgressIndicator());
                    final docs = snap.data?.docs ?? [];
                    if (docs.isEmpty)
                      return const Center(child: Text('No doctors found'));
                    final filtered = docs
                        .where(
                          (d) => _matchesSpecialty(
                            d.data() as Map<String, dynamic>,
                          ),
                        )
                        .toList();
                    final list = filtered.isNotEmpty ? filtered : docs;
                    return ListView.separated(
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (c, i) {
                        final doc = list[i];
                        final m = doc.data() as Map<String, dynamic>;
                        final display =
                            (m['name'] ??
                                    m['email'] ??
                                    m['personalId'] ??
                                    'Doctor')
                                .toString();
                        final specialty = m['specialty']?.toString() ?? '';
                        final isSelected = selectedDoctorId == doc.id;

                        return DoctorAvailabilityCard(
                          doctorId: doc.id,
                          doctorName: display,
                          specialty: specialty,
                          isSelected: isSelected,
                          onTap: () => setState(() {
                            selectedDoctorId = doc.id;
                            selectedDoctorName = display;
                            selectedDoctorSpecialty = specialty;
                          }),
                        );
                      },
                    );
                  },
                ),
              ),
            ],

            // Appointment Form (only show when a doctor is selected)
            if (selectedDoctorId != null) ...[
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: _pickDate,
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.grey[100],
                                padding: const EdgeInsets.all(16),
                              ),
                              child: Text(
                                'Date: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                                style: const TextStyle(color: Colors.black87),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: DropdownButton<String>(
                                value: selectedTimeSlot,
                                isExpanded: true,
                                underline: const SizedBox(),
                                items: timeSlots
                                    .map(
                                      (t) => DropdownMenuItem(
                                        value: t,
                                        child: Text(t),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) => setState(
                                  () =>
                                      selectedTimeSlot = v ?? selectedTimeSlot,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: symptomsController,
                        decoration: const InputDecoration(
                          labelText: 'Symptoms',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes (optional)',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isBooking ? null : _bookAppointment,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: isBooking
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Book Appointment',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (selectedDoctorName != null)
                        Text(
                          'Booking with Dr. $selectedDoctorName',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
