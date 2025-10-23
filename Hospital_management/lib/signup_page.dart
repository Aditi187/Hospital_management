import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'doctor_dashboard.dart';
import 'patient/patient_dashboard.dart';
import 'specialties.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  // Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController specialtyController = TextEditingController();
  final TextEditingController experienceController = TextEditingController();

  String selectedRole = 'Patient';
  String? selectedBloodGroup;
  bool _isLoading = false;
  String selectedSpecialtyChoice = 'Cardiology';

  // Use canonicalSpecialties from shared file

  Future<void> _signup() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill name, email and password')),
      );
      return;
    }

    setState(() => _isLoading = true);
    User? user;
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      user = cred.user;
      if (user == null) throw Exception('Auth user creation failed');

      final uid = user.uid;
      final counterRef = FirebaseFirestore.instance
          .collection('counters')
          .doc(selectedRole == 'Doctor' ? 'doctorId' : 'patientId');

      String personalId = '';
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(counterRef);
        int curr = 100;
        if (snap.exists) curr = (snap.data()?['current'] as int?) ?? 100;
        final next = curr + 1;
        personalId = (selectedRole == 'Doctor' ? 'D' : 'P') + next.toString();
        tx.set(counterRef, {'current': next}, SetOptions(merge: true));

        final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
        final Map<String, dynamic> udata = {
          'name': name,
          'email': email,
          'role': selectedRole.toLowerCase(),
          'personalId': personalId,
          'createdAt': Timestamp.now(),
        };
        
        // For patients, only store blood group during signup
        if (selectedRole == 'Patient') {
          udata['bloodGroup'] = selectedBloodGroup ?? '';
          // Weight and height will be added later through patient dashboard
          udata['weight'] = ''; // Initialize as empty
          udata['height'] = ''; // Initialize as empty
        } else {
          udata['specialization'] = specialtyController.text.trim();
          udata['experience'] = experienceController.text.trim();
          final raw = specialtyController.text.trim();
          String matched = raw;
          try {
            matched = canonicalSpecialties.firstWhere((s) {
              final a = s.toLowerCase();
              final b = raw.toLowerCase();
              return a == b || b.contains(a) || a.contains(b);
            }, orElse: () => raw);
          } catch (_) {}
          final normalized = matched.toLowerCase();
          final doctorRef = FirebaseFirestore.instance
              .collection('doctors')
              .doc(uid);
          tx.set(doctorRef, {
            'name': name,
            'email': email,
            'specialty': matched,
            'specialty_normalized': normalized,
            'personalId': personalId,
            'createdAt': Timestamp.now(),
          });
        }
        
        // write a reverse index for personalId -> uid to speed up login by ID
        final indexRef = FirebaseFirestore.instance
            .collection('personalIdIndex')
            .doc(personalId);
        tx.set(indexRef, {
          'uid': uid,
          'role': selectedRole.toLowerCase(),
        }, SetOptions(merge: true));

        tx.set(userRef, udata);
      });

      try {
        await user.sendEmailVerification();
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Signup successful')));
      }

      if (!mounted) return;
      // If doctor, show the generated personal ID (non-blocking) and navigate to dashboard
      if (selectedRole == 'Doctor') {
        // show a SnackBar with the ID and a copy action, then navigate immediately
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Your Doctor ID: $personalId'),
            action: SnackBarAction(
              label: 'Copy',
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: personalId));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Doctor ID copied to clipboard'),
                    ),
                  );
                }
              },
            ),
            duration: const Duration(seconds: 6),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DoctorDashboard()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    } catch (e) {
      // try rollback
      try {
        if (user != null) await user.delete();
      } catch (_) {}
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Signup failed: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    specialtyController.dispose();
    experienceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign up'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Full name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => selectedRole = 'Patient'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedRole == 'Patient'
                          ? Colors.deepPurple
                          : Colors.grey,
                    ),
                    child: const Text('Patient'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => selectedRole = 'Doctor'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedRole == 'Doctor'
                          ? Colors.deepPurple
                          : Colors.grey,
                    ),
                    child: const Text('Doctor'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (selectedRole == 'Patient') ...[
              DropdownButtonFormField<String>(
                value: selectedBloodGroup,
                decoration: const InputDecoration(labelText: 'Blood group'),
                items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => selectedBloodGroup = v),
              ),
              const SizedBox(height: 8),
              // Note: Weight and height removed from signup - will be collected in dashboard
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Note: Weight and height can be added later in your dashboard profile',
                  style: TextStyle(
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ] else ...[
              DropdownButtonFormField<String>(
                value: selectedSpecialtyChoice,
                decoration: const InputDecoration(labelText: 'Specialty'),
                items: [...canonicalSpecialties, 'Other']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    selectedSpecialtyChoice = v ?? 'Other';
                    // If the user picked a canonical specialty, copy it into the controller
                    if (selectedSpecialtyChoice != 'Other') {
                      specialtyController.text = selectedSpecialtyChoice;
                    } else {
                      specialtyController.text = '';
                    }
                  });
                },
              ),
              const SizedBox(height: 8),
              if (selectedSpecialtyChoice == 'Other')
                TextField(
                  controller: specialtyController,
                  decoration: const InputDecoration(
                    labelText: 'Specialty (please specify)',
                  ),
                ),
              const SizedBox(height: 8),
              TextField(
                controller: experienceController,
                decoration: const InputDecoration(
                  labelText: 'Experience (years)',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _signup,
                      child: const Text('Create account'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}