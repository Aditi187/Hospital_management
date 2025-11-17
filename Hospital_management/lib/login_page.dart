import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'doctor_dashboard.dart';
import 'patient/patient_dashboard.dart';
import 'admin/admin_dashboard.dart';
import 'signup_page.dart';
import 'theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController identifierController =
      TextEditingController(); // Personal ID or Email
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;

  void _login() async {
    String identifier = identifierController.text.trim();
    String password = passwordController.text.trim();

    if (identifier.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      String emailToUse = identifier;

      // 🔹 If user typed Personal ID instead of email
      if (!identifier.contains('@')) {
        QuerySnapshot query = await FirebaseFirestore.instance
            .collection('users')
            .where('personalId', isEqualTo: identifier)
            .limit(1)
            .get();

        if (query.docs.isEmpty) {
          throw Exception("Invalid Personal ID");
        }

        // ✅ Correct way to fetch field value
        Map<String, dynamic> userData =
            query.docs.first.data() as Map<String, dynamic>;
        emailToUse = userData['email'];
      }

      // 🔹 Login with Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: emailToUse, password: password);

      User? user = userCredential.user;

      // 🔹 Fetch role from Firestore
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      Map<String, dynamic> userDoc = doc.data() as Map<String, dynamic>;
      String role = userDoc['role'];

      // 🔹 Check if user is blocked
      if (userDoc['isBlocked'] == true) {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Your account has been blocked. Reason: ${userDoc['blockReason'] ?? 'No reason provided'}',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      // 🔹 Check doctor approval status
      if (role == 'doctor') {
        final approvalStatus = userDoc['approvalStatus'] ?? 'pending';
        if (approvalStatus != 'approved') {
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  approvalStatus == 'rejected'
                      ? 'Your doctor account has been rejected. Reason: ${userDoc['rejectionReason'] ?? 'No reason provided'}'
                      : 'Your doctor account is pending approval. Please wait for admin approval.',
                ),
                backgroundColor: approvalStatus == 'rejected'
                    ? Colors.red
                    : Colors.orange,
                duration: const Duration(seconds: 5),
              ),
            );
          }
          return;
        }
      }

      // 🔹 Redirect based on role
      if (role == "admin") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdminDashboard()),
        );
      } else if (role == "doctor") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DoctorDashboard()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Login failed: ${e.message}")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("An error occurred: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendPasswordReset() async {
    String identifier = identifierController.text.trim();

    if (identifier.isEmpty) {
      // ask user for email or personal id
      final TextEditingController askController = TextEditingController();
      final res = await showDialog<String?>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Reset password'),
          content: TextField(
            controller: askController,
            decoration: const InputDecoration(
              labelText: 'Email or Personal ID',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(askController.text.trim()),
              child: const Text('Send'),
            ),
          ],
        ),
      );

      if (res == null || res.isEmpty) return;
      identifier = res;
    }

    String emailToUse = identifier;

    try {
      // If they supplied a personal ID, resolve to email via users collection
      if (!identifier.contains('@')) {
        // try users collection first
        QuerySnapshot query = await FirebaseFirestore.instance
            .collection('users')
            .where('personalId', isEqualTo: identifier)
            .limit(1)
            .get();

        if (query.docs.isEmpty) {
          // fallback: doctors collection (some accounts are stored there)
          QuerySnapshot docQuery = await FirebaseFirestore.instance
              .collection('doctors')
              .where('personalId', isEqualTo: identifier)
              .limit(1)
              .get();
          if (docQuery.docs.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No account found for that ID')),
            );
            return;
          }
          Map<String, dynamic> docData =
              docQuery.docs.first.data() as Map<String, dynamic>;
          emailToUse = (docData['email'] ?? '').toString();
        } else {
          Map<String, dynamic> userData =
              query.docs.first.data() as Map<String, dynamic>;
          emailToUse = (userData['email'] ?? '').toString();
        }
      } else {
        // If user typed an email, confirm it exists in our users or doctors collection to avoid silent failures
        QuerySnapshot query = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: identifier)
            .limit(1)
            .get();
        if (query.docs.isEmpty) {
          QuerySnapshot docQuery = await FirebaseFirestore.instance
              .collection('doctors')
              .where('email', isEqualTo: identifier)
              .limit(1)
              .get();
          if (docQuery.docs.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No account found for that email')),
            );
            return;
          }
        }
      }

      if (emailToUse.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No email available for that account')),
        );
        return;
      }

      debugPrint('Sending password reset to: $emailToUse');

      await FirebaseAuth.instance.sendPasswordResetEmail(email: emailToUse);

      // write a small debug doc to help diagnose delivery issues
      try {
        final docId = emailToUse.replaceAll('@', '_at_').replaceAll('.', '_');
        await FirebaseFirestore.instance
            .collection('debug_auth_resets')
            .doc(docId)
            .set({
              'email': emailToUse,
              'sentAt': FieldValue.serverTimestamp(),
              'status': 'sent',
            }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Failed to write debug_auth_resets doc: $e');
      }

      // show masked email so user knows where to look (privacy-preserving)
      final parts = emailToUse.split('@');
      final local = parts[0];
      final domain = parts.length > 1 ? parts[1] : '';
      final maskedLocal = local.length <= 2
          ? '${local[0]}*'
          : '${local.substring(0, 2)}${'*' * (local.length - 2)}';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password reset email sent to $maskedLocal@$domain'),
        ),
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('sendPasswordResetEmail error: ${e.code} ${e.message}');
      try {
        final docId = (identifier.contains('@') ? identifier : identifier)
            .replaceAll('@', '_at_')
            .replaceAll('.', '_');
        await FirebaseFirestore.instance
            .collection('debug_auth_resets')
            .doc(docId)
            .set({
              'emailAttempt': emailToUse,
              'error': e.message,
              'code': e.code,
              'attemptAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
      } catch (_) {}
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
    } catch (e) {
      debugPrint('sendPasswordResetEmail unexpected error: $e');
      try {
        final docId = (identifier.contains('@') ? identifier : identifier)
            .replaceAll('@', '_at_')
            .replaceAll('.', '_');
        await FirebaseFirestore.instance
            .collection('debug_auth_resets')
            .doc(docId)
            .set({
              'emailAttempt': emailToUse,
              'error': e.toString(),
              'attemptAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
      } catch (_) {}
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryLight,
              AppTheme.primaryVariant,
              AppTheme.primary,
            ],
            stops: const [0.0, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: Column(
                children: [
                  const SizedBox(height: 80),

                  // Animated Header Section
                  TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 1200),
                    builder: (context, double value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Column(
                          children: [
                            Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.9),
                                    Colors.white.withOpacity(0.7),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(35),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 25,
                                    spreadRadius: 5,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.medical_services_rounded,
                                size: 70,
                                color: AppTheme.primary,
                              ),
                            ),
                            const SizedBox(height: 32),
                            Text(
                              'Welcome Back!',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.3),
                                    offset: const Offset(0, 2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Sign in to continue your healthcare journey',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w400,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 60),

                  // Login Form Card
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          spreadRadius: 0,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Email/ID Field
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey.shade200,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.shade200,
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: identifierController,
                            decoration: InputDecoration(
                              labelText: "Email or Personal ID",
                              labelStyle: TextStyle(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                              prefixIcon: Container(
                                margin: const EdgeInsets.all(12),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppTheme.primaryVariant,
                                      AppTheme.primary,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.person_outline_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 18,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Password Field
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey.shade200,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.shade200,
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: "Password",
                              labelStyle: TextStyle(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                              prefixIcon: Container(
                                margin: const EdgeInsets.all(12),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppTheme.primaryVariant,
                                      AppTheme.primary,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.lock_outline_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 18,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Admin Access - subtle and professional
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const SignupPage(isAdminMode: true),
                                  ),
                                );
                              },
                              child: Text(
                                'Admin Access',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: _sendPasswordReset,
                              child: Text(
                                'Forgot password?',
                                style: TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 36),

                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: _isLoading
                              ? Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppTheme.primaryVariant,
                                        AppTheme.primary,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  ),
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFF667eea),
                                        const Color(0xFF764ba2),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primary.withOpacity(
                                          0.35,
                                        ),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: Text(
                                      "Sign In",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Sign Up Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 16,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SignupPage(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            "Sign Up",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
