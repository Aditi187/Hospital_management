import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data' show Uint8List;

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection and document references
  static String get _userId => _auth.currentUser?.uid ?? '';
  static DocumentReference get _userDoc =>
      _firestore.collection('users').doc(_userId);
  static CollectionReference get _usersCollection =>
      _firestore.collection('users');

  // Insurance Information Operations
  static Future<bool> saveInsuranceInfo(
    Map<String, dynamic> insuranceData,
  ) async {
    try {
      if (_userId.isEmpty) return false;

      // Add metadata
      insuranceData['lastUpdated'] = FieldValue.serverTimestamp();
      insuranceData['updatedBy'] = _auth.currentUser?.email;

      await _userDoc.set({'insurance': insuranceData}, SetOptions(merge: true));

      // Create audit log
      await _createAuditLog('insurance_updated', insuranceData);

      return true;
    } catch (e) {
      print('Error saving insurance info: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>> getInsuranceInfo() async {
    try {
      if (_userId.isEmpty) return {};

      final doc = await _userDoc.get();
      final data = doc.data() as Map<String, dynamic>?;
      return data?['insurance'] ?? {};
    } catch (e) {
      print('Error loading insurance info: $e');
      return {};
    }
  }

  // Medical History Operations
  static Future<bool> saveMedicalHistory(
    Map<String, dynamic> medicalData,
  ) async {
    try {
      if (_userId.isEmpty) return false;

      // Add metadata
      medicalData['lastUpdated'] = FieldValue.serverTimestamp();
      medicalData['updatedBy'] = _auth.currentUser?.email;

      await _userDoc.set({
        'medicalHistory': medicalData,
      }, SetOptions(merge: true));

      // Create audit log
      await _createAuditLog('medical_history_updated', medicalData);

      return true;
    } catch (e) {
      print('Error saving medical history: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>> getMedicalHistory() async {
    try {
      if (_userId.isEmpty) return {};

      final doc = await _userDoc.get();
      final data = doc.data() as Map<String, dynamic>?;
      return data?['medicalHistory'] ?? {};
    } catch (e) {
      print('Error loading medical history: $e');
      return {};
    }
  }

  // Complete Profile Operations
  static Future<Map<String, dynamic>> getUserProfile() async {
    try {
      if (_userId.isEmpty) return {};

      final doc = await _userDoc.get();
      return doc.data() as Map<String, dynamic>? ?? {};
    } catch (e) {
      print('Error loading user profile: $e');
      return {};
    }
  }

  static Stream<DocumentSnapshot> getUserProfileStream() {
    if (_userId.isEmpty) return const Stream.empty();
    return _userDoc.snapshots();
  }

  // Batch Update Operations
  static Future<bool> updateMultipleFields(Map<String, dynamic> updates) async {
    try {
      if (_userId.isEmpty) return false;

      updates['lastUpdated'] = FieldValue.serverTimestamp();
      updates['updatedBy'] = _auth.currentUser?.email;

      await _userDoc.set(updates, SetOptions(merge: true));

      // Create audit log
      await _createAuditLog('profile_batch_update', updates);

      return true;
    } catch (e) {
      print('Error updating multiple fields: $e');
      return false;
    }
  }

  // Search and Query Operations
  static Future<List<Map<String, dynamic>>> searchUsersByInsuranceProvider(
    String provider,
  ) async {
    try {
      final query = await _usersCollection
          .where('insurance.provider', isEqualTo: provider)
          .get();

      return query.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('Error searching users by insurance provider: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getUsersByBloodType(
    String bloodType,
  ) async {
    try {
      final query = await _usersCollection
          .where('medicalHistory.bloodType', isEqualTo: bloodType)
          .get();

      return query.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('Error searching users by blood type: $e');
      return [];
    }
  }

  // Data Validation
  static Map<String, String?> validateInsuranceData(Map<String, dynamic> data) {
    Map<String, String?> errors = {};

    // Required fields
    if (data['provider']?.toString().trim().isEmpty ?? true) {
      errors['provider'] = 'Insurance provider is required';
    }

    if (data['policyNumber']?.toString().trim().isEmpty ?? true) {
      errors['policyNumber'] = 'Policy number is required';
    }

    // Optional field validations
    final phone = data['phone']?.toString().trim() ?? '';
    if (phone.isNotEmpty &&
        !RegExp(r'^\+?[\d\s\-\(\)]{10,}$').hasMatch(phone)) {
      errors['phone'] = 'Invalid phone number format';
    }

    final validThrough = data['validThrough']?.toString().trim() ?? '';
    if (validThrough.isNotEmpty &&
        !RegExp(r'^\d{2}/\d{4}$').hasMatch(validThrough)) {
      errors['validThrough'] = 'Use MM/YYYY format';
    }

    return errors;
  }

  static Map<String, String?> validateMedicalData(Map<String, dynamic> data) {
    Map<String, String?> errors = {};

    // Blood type validation
    final bloodType = data['bloodType']?.toString().trim().toUpperCase() ?? '';
    if (bloodType.isNotEmpty &&
        ![
          'A+',
          'A-',
          'B+',
          'B-',
          'AB+',
          'AB-',
          'O+',
          'O-',
        ].contains(bloodType)) {
      errors['bloodType'] =
          'Valid blood types: A+, A-, B+, B-, AB+, AB-, O+, O-';
    }

    // Weight validation
    final weight = data['weight']?.toString().trim() ?? '';
    if (weight.isNotEmpty) {
      final weightNum = double.tryParse(weight);
      if (weightNum == null || weightNum <= 0 || weightNum > 1000) {
        errors['weight'] = 'Weight must be between 1 and 1000 kg';
      }
    }

    // Height validation
    final height = data['height']?.toString().trim() ?? '';
    if (height.isNotEmpty) {
      final heightNum = double.tryParse(height);
      if (heightNum == null || heightNum <= 0 || heightNum > 300) {
        errors['height'] = 'Height must be between 1 and 300 cm';
      }
    }

    // Date validation for lastVisit
    final lastVisit = data['lastVisit']?.toString().trim() ?? '';
    if (lastVisit.isNotEmpty) {
      try {
        DateTime.parse(lastVisit);
      } catch (e) {
        errors['lastVisit'] = 'Use YYYY-MM-DD format';
      }
    }

    return errors;
  }

  // Backup and Recovery
  static Future<bool> createDataBackup() async {
    try {
      if (_userId.isEmpty) return false;

      final userData = await getUserProfile();
      await _userDoc.collection('backups').add({
        'data': userData,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'profile_backup',
        'version': '1.0',
      });

      return true;
    } catch (e) {
      print('Error creating backup: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getBackupHistory() async {
    try {
      if (_userId.isEmpty) return [];

      final query = await _userDoc
          .collection('backups')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      return query.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      print('Error loading backup history: $e');
      return [];
    }
  }

  // Audit Logging
  static Future<void> _createAuditLog(
    String action,
    Map<String, dynamic> data,
  ) async {
    try {
      if (_userId.isEmpty) return;

      await _userDoc.collection('audit_logs').add({
        'action': action,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': _userId,
        'userEmail': _auth.currentUser?.email,
        'dataKeys': data.keys.toList(),
        'changeCount': data.length,
      });
    } catch (e) {
      print('Error creating audit log: $e');
    }
  }

  // Data Export
  static Future<Map<String, dynamic>> exportUserData() async {
    try {
      if (_userId.isEmpty) return {};

      final profile = await getUserProfile();
      final auditLogs = await _userDoc
          .collection('audit_logs')
          .orderBy('timestamp', descending: true)
          .get();

      return {
        'profile': profile,
        'auditLogs': auditLogs.docs.map((doc) => doc.data()).toList(),
        'exportTimestamp': DateTime.now().toIso8601String(),
        'exportedBy': _auth.currentUser?.email,
      };
    } catch (e) {
      print('Error exporting user data: $e');
      return {};
    }
  }

  // Data Statistics
  static Future<Map<String, dynamic>> getDataStatistics() async {
    try {
      if (_userId.isEmpty) return {};

      final profile = await getUserProfile();
      final auditLogs = await _userDoc.collection('audit_logs').get();
      final backups = await _userDoc.collection('backups').get();

      return {
        'profileCompleteness': _calculateProfileCompleteness(profile),
        'totalAuditLogs': auditLogs.docs.length,
        'totalBackups': backups.docs.length,
        'lastUpdated': profile['lastUpdated'],
        'hasInsurance': profile.containsKey('insurance'),
        'hasMedicalHistory': profile.containsKey('medicalHistory'),
      };
    } catch (e) {
      print('Error getting data statistics: $e');
      return {};
    }
  }

  static double _calculateProfileCompleteness(Map<String, dynamic> profile) {
    final requiredFields = [
      'name',
      'email',
      'phone',
      'address',
      'insurance.provider',
      'insurance.policyNumber',
      'medicalHistory.bloodType',
      'medicalHistory.allergies',
    ];

    int completedFields = 0;
    for (final field in requiredFields) {
      if (field.contains('.')) {
        final parts = field.split('.');
        final value = profile[parts[0]]?[parts[1]];
        if (value != null && value.toString().trim().isNotEmpty) {
          completedFields++;
        }
      } else {
        final value = profile[field];
        if (value != null && value.toString().trim().isNotEmpty) {
          completedFields++;
        }
      }
    }

    return completedFields / requiredFields.length;
  }

  // Medical Records Operations
  static Future<bool> addMedicalRecord(
    String patientId,
    Map<String, dynamic> recordData,
  ) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      recordData['patientId'] = patientId;
      recordData['doctorId'] = currentUser.uid;
      recordData['doctorName'] =
          currentUser.displayName ?? currentUser.email ?? 'Doctor';
      recordData['timestamp'] = FieldValue.serverTimestamp();
      recordData['createdAt'] = DateTime.now().toIso8601String();

      await _firestore.collection('medical_reports').add(recordData);

      // Create audit log
      await _createAuditLog('medical_record_added', recordData);

      return true;
    } catch (e) {
      print('Error adding medical record: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getMedicalRecords(
    String patientId,
  ) async {
    try {
      final query = await _firestore
          .collection('medical_reports')
          .where('patientId', isEqualTo: patientId)
          .orderBy('timestamp', descending: true)
          .get();

      return query.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      print('Error getting medical records: $e');
      return [];
    }
  }

  static Stream<QuerySnapshot> getMedicalRecordsStream(String patientId) {
    return _firestore
        .collection('medical_reports')
        .where('patientId', isEqualTo: patientId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Prescription Operations
  static Future<bool> addPrescription(
    String patientId,
    Map<String, dynamic> prescriptionData,
  ) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      prescriptionData['patientId'] = patientId;
      prescriptionData['doctorId'] = currentUser.uid;
      prescriptionData['doctorName'] =
          currentUser.displayName ?? currentUser.email ?? 'Doctor';
      prescriptionData['status'] = prescriptionData['status'] ?? 'Prescribed';
      prescriptionData['prescribedDate'] = FieldValue.serverTimestamp();
      prescriptionData['createdAt'] = DateTime.now().toIso8601String();

      await _firestore.collection('prescriptions').add(prescriptionData);

      // Also add to medical record as prescription
      await addMedicalRecord(patientId, {
        'title': 'Prescription: ${prescriptionData['medicineName']}',
        'diagnosis': 'Medication prescribed',
        'treatment':
            '${prescriptionData['medicineName']} - ${prescriptionData['dosage']}',
        'notes':
            'Frequency: ${prescriptionData['frequency']}, Duration: ${prescriptionData['duration']}',
        'prescriptions': [
          {
            'medicine': prescriptionData['medicineName'],
            'dosage': prescriptionData['dosage'],
            'frequency': prescriptionData['frequency'],
            'duration': prescriptionData['duration'],
            'instructions': prescriptionData['instructions'],
          },
        ],
      });

      // Create audit log
      await _createAuditLog('prescription_added', prescriptionData);

      return true;
    } catch (e) {
      print('Error adding prescription: $e');
      return false;
    }
  }

  // Upload a prescription file for a patient (audit-enabled)
  // Returns the download URL on success, or null on failure.
  static Future<String?> uploadPatientPrescription({
    required String patientId,
    required Uint8List bytes,
    required String fileName,
    String? contentType,
  }) async {
    try {
      if (_userId.isEmpty) throw Exception('Not authenticated');

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final safeName = fileName.replaceAll(' ', '_');
      final storagePath =
          'patient_prescriptions/$patientId/${timestamp}_$safeName';

      final ref = FirebaseStorage.instance.ref().child(storagePath);
      final meta = SettableMetadata(
        contentType:
            contentType ??
            (fileName.toLowerCase().endsWith('.pdf')
                ? 'application/pdf'
                : 'image/jpeg'),
      );

      final uploadTask = await ref.putData(bytes, meta);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      final docData = {
        'patientId': patientId,
        'uploadedBy': _userId,
        'fileUrl': downloadUrl,
        'fileName': fileName,
        'status': 'UploadedByPatient',
        'uploadedAt': FieldValue.serverTimestamp(),
        'createdAt': DateTime.now().toIso8601String(),
      };

      final docRef = await _firestore.collection('prescriptions').add(docData);

      // Audit log entry
      await _createAuditLog('prescription_uploaded_by_patient', {
        'prescriptionDocId': docRef.id,
        'patientId': patientId,
        'fileName': fileName,
        'storagePath': storagePath,
      });

      return downloadUrl;
    } catch (e, st) {
      print('Error uploading patient prescription: $e\n$st');
      try {
        await _firestore.collection('debug_uploads').doc(patientId).set({
          'lastUploadAt': FieldValue.serverTimestamp(),
          'lastUploadError': e.toString(),
        }, SetOptions(merge: true));
      } catch (_) {}
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getPrescriptions(
    String patientId,
  ) async {
    try {
      final query = await _firestore
          .collection('prescriptions')
          .where('patientId', isEqualTo: patientId)
          .orderBy('prescribedDate', descending: true)
          .get();

      return query.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      print('Error getting prescriptions: $e');
      return [];
    }
  }

  static Stream<QuerySnapshot> getPrescriptionsStream(String patientId) {
    return _firestore
        .collection('prescriptions')
        .where('patientId', isEqualTo: patientId)
        .orderBy('prescribedDate', descending: true)
        .snapshots();
  }

  static Future<bool> updatePrescriptionStatus(
    String prescriptionId,
    String status,
  ) async {
    try {
      await _firestore.collection('prescriptions').doc(prescriptionId).update({
        'status': status,
        'statusUpdatedAt': FieldValue.serverTimestamp(),
      });

      // Create audit log
      await _createAuditLog('prescription_status_updated', {
        'prescriptionId': prescriptionId,
        'newStatus': status,
      });

      return true;
    } catch (e) {
      print('Error updating prescription status: $e');
      return false;
    }
  }

  // Patient Management Operations
  static Future<List<Map<String, dynamic>>> getAllPatients() async {
    try {
      final query = await _usersCollection.get();
      return query.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      print('Error getting patients: $e');
      return [];
    }
  }

  static Stream<QuerySnapshot> getAllPatientsStream() {
    return _usersCollection.snapshots();
  }

  static Future<Map<String, dynamic>> getPatientDetails(
    String patientId,
  ) async {
    try {
      final doc = await _usersCollection.doc(patientId).get();
      return doc.data() as Map<String, dynamic>? ?? {};
    } catch (e) {
      print('Error getting patient details: $e');
      return {};
    }
  }

  // Medicine Order Integration
  static Future<bool> orderMedicine(
    String prescriptionId,
    Map<String, dynamic> orderData,
  ) async {
    try {
      orderData['prescriptionId'] = prescriptionId;
      orderData['orderedBy'] = _auth.currentUser?.uid;
      orderData['orderDate'] = FieldValue.serverTimestamp();
      orderData['status'] = 'Ordered';
      orderData['createdAt'] = DateTime.now().toIso8601String();

      await _firestore.collection('medicine_orders').add(orderData);

      // Update prescription status
      await updatePrescriptionStatus(prescriptionId, 'Ordered');

      // Create audit log
      await _createAuditLog('medicine_ordered', orderData);

      return true;
    } catch (e) {
      print('Error ordering medicine: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getMedicineOrders(
    String patientId,
  ) async {
    try {
      final query = await _firestore
          .collection('medicine_orders')
          .where('patientId', isEqualTo: patientId)
          .orderBy('orderDate', descending: true)
          .get();

      return query.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      print('Error getting medicine orders: $e');
      return [];
    }
  }

  // Validation for medical records
  static Map<String, String?> validateMedicalRecord(Map<String, dynamic> data) {
    Map<String, String?> errors = {};

    if (data['title']?.toString().trim().isEmpty ?? true) {
      errors['title'] = 'Record title is required';
    }

    if (data['diagnosis']?.toString().trim().isEmpty ?? true) {
      errors['diagnosis'] = 'Diagnosis is required';
    }

    return errors;
  }

  // Validation for prescriptions
  static Map<String, String?> validatePrescription(Map<String, dynamic> data) {
    Map<String, String?> errors = {};

    if (data['medicineName']?.toString().trim().isEmpty ?? true) {
      errors['medicineName'] = 'Medicine name is required';
    }

    if (data['dosage']?.toString().trim().isEmpty ?? true) {
      errors['dosage'] = 'Dosage is required';
    }

    if (data['frequency']?.toString().trim().isEmpty ?? true) {
      errors['frequency'] = 'Frequency is required';
    }

    if (data['duration']?.toString().trim().isEmpty ?? true) {
      errors['duration'] = 'Duration is required';
    }

    return errors;
  }
}
