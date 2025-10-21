import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔹 Sign up user
  Future<User?> signUp(String email, String password, String role) async {
    try {
      // Create user in FirebaseAuth
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

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
      DocumentSnapshot doc = await _firestore
          .collection("users")
          .doc(uid)
          .get();
      return doc["role"];
    } catch (e) {
      print("Get Role Error: $e");
      return null;
    }
  }

  // 🔹 Send email verification
  Future<bool> sendEmailVerification() async {
    try {
      User? user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        return true;
      }
      return false;
    } catch (e) {
      print("Send Email Verification Error: $e");
      return false;
    }
  }

  // 🔹 Check if user email is verified
  Future<bool> isEmailVerified() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // Reload user to get latest verification status
        await user.reload();
        user = _auth.currentUser; // Get updated user
        return user?.emailVerified ?? false;
      }
      return false;
    } catch (e) {
      print("Check Email Verification Error: $e");
      return false;
    }
  }

  // 🔹 Update user verification status in Firestore
  Future<bool> updateVerificationStatus(bool isVerified) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection("users").doc(user.uid).update({
          "emailVerified": isVerified,
          "verificationUpdatedAt": FieldValue.serverTimestamp(),
        });
        return true;
      }
      return false;
    } catch (e) {
      print("Update Verification Status Error: $e");
      return false;
    }
  }

  // 🔹 Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // 🔹 Check if user needs verification
  Future<bool> needsEmailVerification() async {
    User? user = _auth.currentUser;
    if (user == null) return false;

    // Reload to get latest status
    await user.reload();
    user = _auth.currentUser;

    return !(user?.emailVerified ?? false);
  }

  // 🔹 Resend verification email with cooldown
  Future<Map<String, dynamic>> resendVerificationEmail() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'No user logged in'};
      }

      if (user.emailVerified) {
        return {'success': false, 'message': 'Email already verified'};
      }

      // Check last sent time from Firestore
      DocumentSnapshot userDoc = await _firestore
          .collection("users")
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        Timestamp? lastSent = userData['lastVerificationSent'];

        if (lastSent != null) {
          DateTime lastSentTime = lastSent.toDate();
          DateTime now = DateTime.now();
          Duration difference = now.difference(lastSentTime);

          // 1 minute cooldown
          if (difference.inMinutes < 1) {
            int remainingSeconds = 60 - difference.inSeconds;
            return {
              'success': false,
              'message':
                  'Please wait $remainingSeconds seconds before resending',
              'cooldown': remainingSeconds,
            };
          }
        }
      }

      // Send verification email
      await user.sendEmailVerification();

      // Update last sent time
      await _firestore.collection("users").doc(user.uid).update({
        'lastVerificationSent': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'message': 'Verification email sent successfully',
      };
    } catch (e) {
      print("Resend Verification Error: $e");
      return {
        'success': false,
        'message': 'Failed to send verification email: $e',
      };
    }
  }

  // 🔹 Logout
  Future<void> logout() async {
    await _auth.signOut();
  }
}
