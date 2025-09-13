import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'doctor_dashboard.dart';
import 'patient/patient_dashboard.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController specializationController =
      TextEditingController();
  final TextEditingController experienceController = TextEditingController();

  String selectedRole = "Patient";
  bool _isLoading = false;

  Future<void> _signup() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    String name = nameController.text.trim();

    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password must be at least 6 characters")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1️⃣ Create user in Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      User? user = userCredential.user;

      String counterDoc = selectedRole == "Doctor" ? "doctorId" : "patientId";
      DocumentReference counterRef = FirebaseFirestore.instance
          .collection('counters')
          .doc(counterDoc);

      String personalId = "";

      // 2️⃣ Transaction to generate personalId and save user data
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot counterSnapshot = await transaction.get(counterRef);

        int currentCount = counterSnapshot.exists
            ? counterSnapshot['current']
            : 100;
        int newCount = currentCount + 1;

        personalId =
            (selectedRole == "Doctor" ? "D" : "P") + newCount.toString();

        transaction.set(counterRef, {
          'current': newCount,
        }, SetOptions(merge: true));

        Map<String, dynamic> userData = {
          "email": email,
          "role": selectedRole.toLowerCase(),
          "name": name,
          "personalId": personalId,
          "createdAt": Timestamp.now(),
        };

        if (selectedRole == "Patient") {
          userData["age"] = ageController.text.trim();
        } else if (selectedRole == "Doctor") {
          userData["specialization"] = specializationController.text.trim();
          userData["experience"] = experienceController.text.trim();
        }

        transaction.set(
          FirebaseFirestore.instance.collection("users").doc(user!.uid),
          userData,
        );
      });

      // 3️⃣ Send email verification
      try {
        await user?.sendEmailVerification();
        print("Verification email sent to $email");
      } catch (verificationError) {
        print("Failed to send verification email: $verificationError");
      }

      // 4️⃣ Show dialog with personal ID and verification info
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Signup Successful 🎉"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Welcome $name!\n"),
              Text("Your ID is: $personalId\n"),
              const Text(
                "📧 A verification email has been sent to your email address.",
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: const Text(
                  "Please verify your email to access all features. You can continue using the app, but some features may be limited until verification.",
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        ),
      );

      // 5️⃣ Redirect to appropriate dashboard
      if (selectedRole == "Doctor") {
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
    } catch (e) {
      // ⚠️ Rollback: Delete user from Auth if Firestore fails
      await FirebaseAuth.instance.currentUser?.delete();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Signup failed: $e")));
    } finally {
      setState(() => _isLoading = false);
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
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              const Color(0xFF667eea),
              const Color(0xFF764ba2),
              Colors.purple.shade200,
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
                  const SizedBox(height: 60),

                  // Header Section
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Join Us Today!',
                        style: TextStyle(
                          fontSize: 28,
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
                      const Spacer(),
                      const SizedBox(width: 44), // Balance the back button
                    ],
                  ),

                  const SizedBox(height: 20),

                  Text(
                    'Create your healthcare account',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 40),

                  // Signup Form Card
                  Container(
                    padding: const EdgeInsets.all(28),
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
                        // Full Name Field
                        _buildTextField(
                          controller: nameController,
                          label: "Full Name",
                          icon: Icons.person_outline_rounded,
                        ),

                        const SizedBox(height: 20),

                        // Email Field
                        _buildTextField(
                          controller: emailController,
                          label: "Email Address",
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),

                        const SizedBox(height: 20),

                        // Password Field
                        _buildTextField(
                          controller: passwordController,
                          label: "Password",
                          icon: Icons.lock_outline_rounded,
                          isPassword: true,
                        ),

                        const SizedBox(height: 24),

                        // Role Selection
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey.shade200,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => selectedRole = "Patient"),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: selectedRole == "Patient"
                                          ? const Color(0xFF667eea)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: selectedRole == "Patient"
                                          ? [
                                              BoxShadow(
                                                color: const Color(
                                                  0xFF667eea,
                                                ).withOpacity(0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.healing_rounded,
                                          color: selectedRole == "Patient"
                                              ? Colors.white
                                              : Colors.grey.shade600,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          "Patient",
                                          style: TextStyle(
                                            color: selectedRole == "Patient"
                                                ? Colors.white
                                                : Colors.grey.shade600,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => selectedRole = "Doctor"),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: selectedRole == "Doctor"
                                          ? const Color(0xFF667eea)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: selectedRole == "Doctor"
                                          ? [
                                              BoxShadow(
                                                color: const Color(
                                                  0xFF667eea,
                                                ).withOpacity(0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.medical_services_rounded,
                                          color: selectedRole == "Doctor"
                                              ? Colors.white
                                              : Colors.grey.shade600,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          "Doctor",
                                          style: TextStyle(
                                            color: selectedRole == "Doctor"
                                                ? Colors.white
                                                : Colors.grey.shade600,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Role-specific fields
                        if (selectedRole == "Patient") ...[
                          _buildTextField(
                            controller: ageController,
                            label: "Age",
                            icon: Icons.cake_outlined,
                            keyboardType: TextInputType.number,
                          ),
                        ],

                        if (selectedRole == "Doctor") ...[
                          _buildTextField(
                            controller: specializationController,
                            label: "Specialization",
                            icon: Icons.local_hospital_outlined,
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: experienceController,
                            label: "Experience (Years)",
                            icon: Icons.work_outline_rounded,
                            keyboardType: TextInputType.number,
                          ),
                        ],

                        const SizedBox(height: 36),

                        // Sign Up Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: _isLoading
                              ? Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFF667eea),
                                        const Color(0xFF764ba2),
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
                                        color: const Color(
                                          0xFF667eea,
                                        ).withOpacity(0.4),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _signup,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: Text(
                                      "Create Account",
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF667eea), const Color(0xFF764ba2)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
      ),
    );
  }
}
