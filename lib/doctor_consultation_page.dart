import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'specialties.dart';

/// Minimal, clean Doctor Consultation page.
/// - Lists doctors from `doctors` (fallback to `users`)
/// - Specialty filter
/// - Book appointment (writes simple appointment doc)
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
  String selectedSpecialty = 'All';
  DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
  String selectedTimeSlot = '09:00 AM';
  final symptomsController = TextEditingController();
  final notesController = TextEditingController();
  bool isBooking = false;

  List<String> specialties = ['All', ...canonicalSpecialties];
  final timeSlots = [
    '09:00 AM',
    '10:00 AM',
    '11:00 AM',
    '02:00 PM',
    '04:00 PM',
    '05:00 PM',
    '10:00 PM',
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
    // subscribe to real-time updates so specialty dropdown stays current
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select a doctor')));
      return;
    }
    setState(() => isBooking = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Sign in first')));
        return;
      }
      await _firestore.collection('appointments').add({
        'doctorId': selectedDoctorId,
        'doctorName': selectedDoctorName ?? '',
        'patientId': user.uid,
        'patientName': user.displayName ?? user.email ?? '',
        'specialty': selectedSpecialty,
        'date': Timestamp.fromDate(selectedDate),
        'timeSlot': selectedTimeSlot,
        'symptoms': symptomsController.text.trim(),
        'notes': notesController.text.trim(),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Appointment booked')));
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
      selectedSpecialty = 'All';
      selectedTimeSlot = timeSlots.first;
      selectedDate = DateTime.now().add(const Duration(days: 1));
      symptomsController.clear();
      notesController.clear();
    });
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
            Row(
              children: [
                const Text('Specialty: '),
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
                        (d) =>
                            _matchesSpecialty(d.data() as Map<String, dynamic>),
                      )
                      .toList();
                  final list = filtered.isNotEmpty ? filtered : docs;
                  return ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (c, i) {
                      final doc = list[i];
                      final m = doc.data() as Map<String, dynamic>;
                      final display =
                          (m['name'] ??
                                  m['email'] ??
                                  m['personalId'] ??
                                  'Doctor')
                              .toString();
                      return ListTile(
                        title: Text(display),
                        subtitle: Text(m['specialty'] ?? ''),
                        selected: selectedDoctorId == doc.id,
                        onTap: () => setState(() {
                          selectedDoctorId = doc.id;
                          selectedDoctorName = display;
                        }),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _pickDate,
                    child: Text(
                      'Date: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    value: selectedTimeSlot,
                    items: timeSlots
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) => setState(
                      () => selectedTimeSlot = v ?? selectedTimeSlot,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: symptomsController,
              decoration: const InputDecoration(labelText: 'Symptoms'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isBooking ? null : _bookAppointment,
                child: isBooking
                    ? const CircularProgressIndicator()
                    : const Text('Book Appointment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
