import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔹 Sign up user
  Future<User?> signUp(String email, String password, String role) async {
    try {
      // Create user in FirebaseAuth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      // Save extra info (like role) in Firestore
      await _firestore.collection("users").doc(user!.uid).set({
        "email": email,
        "role": role,
      });

      return user;
    } catch (e) {
      print("Sign Up Error: $e");
      return null;
    }
  }

  // 🔹 Login user
  Future<User?> login(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return userCredential.user;
    } catch (e) {
      print("Login Error: $e");
      return null;
    }
  }

  // 🔹 Get user role from Firestore
  Future<String?> getUserRole(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection("users").doc(uid).get();
      return doc["role"];
    } catch (e) {
      print("Get Role Error: $e");
      return null;
    }
  }

  // 🔹 Logout
  Future<void> logout() async {
    await _auth.signOut();
  }
}
