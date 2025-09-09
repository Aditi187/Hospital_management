import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'doctor_dashboard.dart';
import 'patient_dashboard.dart';

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
  final TextEditingController specializationController = TextEditingController();
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
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;

      String counterDoc = selectedRole == "Doctor" ? "doctorId" : "patientId";
      DocumentReference counterRef =
          FirebaseFirestore.instance.collection('counters').doc(counterDoc);

      String personalId = "";

      // 2️⃣ Transaction to generate personalId and save user data
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot counterSnapshot = await transaction.get(counterRef);

        int currentCount = counterSnapshot.exists ? counterSnapshot['current'] : 100;
        int newCount = currentCount + 1;

        personalId =
            (selectedRole == "Doctor" ? "D" : "P") + newCount.toString();

        transaction.set(counterRef, {'current': newCount},
            SetOptions(merge: true));

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

      // 3️⃣ Show dialog with personal ID
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Signup Successful 🎉"),
          content: Text(
              "Welcome $name!\n\nYour ID is: $personalId\n\nPlease use this ID when logging in."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        ),
      );

      // 4️⃣ Redirect to appropriate dashboard
      if (selectedRole == "Doctor") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DoctorDashboard()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PatientDashboard()),
        );
      }
    } catch (e) {
      // ⚠️ Rollback: Delete user from Auth if Firestore fails
      await FirebaseAuth.instance.currentUser?.delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Signup failed: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Full Name"),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            DropdownButton<String>(
              value: selectedRole,
              items: const [
                DropdownMenuItem(value: "Patient", child: Text("Patient")),
                DropdownMenuItem(value: "Doctor", child: Text("Doctor")),
              ],
              onChanged: (value) {
                setState(() {
                  selectedRole = value!;
                });
              },
            ),
            if (selectedRole == "Patient")
              TextField(
                controller: ageController,
                decoration: const InputDecoration(labelText: "Age"),
              ),
            if (selectedRole == "Doctor") ...[
              TextField(
                controller: specializationController,
                decoration: const InputDecoration(labelText: "Specialization"),
              ),
              TextField(
                controller: experienceController,
                decoration:
                    const InputDecoration(labelText: "Experience (Years)"),
              ),
            ],
            const SizedBox(height: 20),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _signup,
                    child: const Text("Sign Up"),
                  ),
          ],
        ),
      ),
    );
  }
}
