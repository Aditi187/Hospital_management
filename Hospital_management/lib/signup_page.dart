import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'patient/patient_dashboard.dart';
import 'admin/admin_dashboard.dart';
import 'specialties.dart';

class SignupPage extends StatefulWidget {
  final bool isAdminMode;

  const SignupPage({super.key, this.isAdminMode = false});

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
  final TextEditingController adminCodeController = TextEditingController();

  String selectedRole = 'Patient';
  String? selectedBloodGroup;
  bool _isLoading = false;
  String selectedSpecialtyChoice = 'Cardiology';

  // Secret admin code
  static const String ADMIN_SECRET_CODE = 'ADMIN101';

  @override
  void initState() {
    super.initState();
    // If in admin mode, set role to Admin
    if (widget.isAdminMode) {
      selectedRole = 'Admin';
    }
  }

  // Use canonicalSpecialties from shared file

  Future<void> _verifyAdminCode() async {
    final code = adminCodeController.text.trim();

    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the admin code')),
      );
      return;
    }

    if (code != ADMIN_SECRET_CODE) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid admin code. Access denied.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Code is correct, navigate to admin dashboard
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdminDashboard()),
      );
    }
  }

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
          .doc(
            selectedRole == 'Doctor'
                ? 'doctorId'
                : selectedRole == 'Admin'
                ? 'adminId'
                : 'patientId',
          );

      String personalId = '';
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(counterRef);
        int curr = 100;
        if (snap.exists) curr = (snap.data()?['current'] as int?) ?? 100;
        final next = curr + 1;
        personalId =
            (selectedRole == 'Doctor'
                ? 'D'
                : selectedRole == 'Admin'
                ? 'A'
                : 'P') +
            next.toString();
        tx.set(counterRef, {'current': next}, SetOptions(merge: true));

        final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
        final Map<String, dynamic> udata = {
          'name': name,
          'email': email,
          'role': selectedRole.toLowerCase(),
          'personalId': personalId,
          'createdAt': Timestamp.now(),
          'isBlocked': false, // Initialize as not blocked
        };

        // For patients, only store blood group during signup
        if (selectedRole == 'Patient') {
          udata['bloodGroup'] = selectedBloodGroup ?? '';
          // Weight and height will be added later through patient dashboard
          udata['weight'] = ''; // Initialize as empty
          udata['height'] = ''; // Initialize as empty
        } else if (selectedRole == 'Doctor') {
          // For doctors, set approval status to pending
          udata['approvalStatus'] = 'pending';
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
            'approvalStatus': 'pending', // Also set in doctors collection
          });
        }
        // Admin role doesn't need extra fields or approval

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
        // Doctors need approval - sign them out and show message
        await FirebaseAuth.instance.signOut();

        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.pending_actions, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Account Pending Approval'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your doctor account has been created successfully!',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'Your Doctor ID: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Expanded(
                          child: Text(
                            personalId,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 20),
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(text: personalId),
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('ID copied to clipboard'),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '⏳ Your account is pending admin approval.',
                    style: TextStyle(color: Colors.orange),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'You will receive a notification once your account is approved. Only approved doctors can login and use the app.',
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '📧 Please check your email for verification.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Go back to login
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } else if (selectedRole == 'Admin') {
        // Admin goes directly to admin dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboard()),
        );
      } else {
        // Patient goes to patient dashboard
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
        title: Text(widget.isAdminMode ? 'Admin Access' : 'Sign up'),
        backgroundColor: widget.isAdminMode
            ? Colors.orange[700]
            : Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Admin mode - only show code input
            if (widget.isAdminMode) ...[
              const SizedBox(height: 40),
              Icon(
                Icons.admin_panel_settings,
                size: 80,
                color: Colors.orange[700],
              ),
              const SizedBox(height: 24),
              Text(
                'Administrator Access',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Enter the secret admin code to access the dashboard',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: adminCodeController,
                decoration: InputDecoration(
                  labelText: 'Admin Secret Code',
                  hintText: 'Enter admin code',
                  prefixIcon: Icon(Icons.lock, color: Colors.orange[700]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.orange[700]!,
                      width: 2,
                    ),
                  ),
                ),
                obscureText: true,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyAdminCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Enter Dashboard',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Login'),
              ),
            ]
            // Regular signup for Patient/Doctor
            else ...[
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
              // Only show role buttons if NOT in admin mode
              if (!widget.isAdminMode)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () =>
                            setState(() => selectedRole = 'Patient'),
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
                        onPressed: () =>
                            setState(() => selectedRole = 'Doctor'),
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
              if (!widget.isAdminMode) const SizedBox(height: 12),
              // Show admin badge if in admin mode
              if (widget.isAdminMode)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange[700]!, Colors.orange[900]!],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.admin_panel_settings,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Administrator Account',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              if (widget.isAdminMode) const SizedBox(height: 12),
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
                    style: TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ] else if (selectedRole == 'Admin' && !widget.isAdminMode) ...[
                // This section only shows when user selects Admin in normal signup mode
                // (which shouldn't happen since we removed the button, but kept for safety)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.admin_panel_settings,
                            color: Colors.orange[700],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Administrator Account',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'As an Admin, you will have full access to:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('✓ View all doctors and patients'),
                          Text('✓ Block or remove any user'),
                          Text('✓ Approve doctor registrations'),
                          Text('✓ Send announcements to patients'),
                          Text('✓ Send alerts to doctors'),
                          Text('✓ Manage all system users'),
                        ],
                      ),
                    ],
                  ),
                ),
              ] else if (selectedRole == 'Doctor') ...[
                // Doctor-specific fields
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
            ], // Close the else block
          ],
        ),
      ),
    );
  }
}
