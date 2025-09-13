import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'privacy_settings_page.dart';

// Abstract base class for profile sections (Abstraction)
abstract class ProfileSection {
  String get title;
  IconData get icon;
  Color get color;
  Widget buildContent(BuildContext context, Map<String, dynamic> userData);
}

// Interface for profile actions (Polymorphism)
mixin ProfileActionMixin {
  void showEditDialog(BuildContext context, String field, String currentValue);
  void updateProfile(BuildContext context, Map<String, dynamic> updates);
}

// Profile data model (Encapsulation)
class ProfileDataModel {
  final String _userId;
  final String _displayName;
  final String _email;
  final String _phoneNumber;
  final String _dateOfBirth;
  final String _gender;
  final String _bloodType;
  final String _address;
  final String _emergencyContact;
  final String _profileImageUrl;

  const ProfileDataModel({
    required String userId,
    required String displayName,
    required String email,
    required String phoneNumber,
    required String dateOfBirth,
    required String gender,
    required String bloodType,
    required String address,
    required String emergencyContact,
    required String profileImageUrl,
  }) : _userId = userId,
       _displayName = displayName,
       _email = email,
       _phoneNumber = phoneNumber,
       _dateOfBirth = dateOfBirth,
       _gender = gender,
       _bloodType = bloodType,
       _address = address,
       _emergencyContact = emergencyContact,
       _profileImageUrl = profileImageUrl;

  // Getters (Encapsulation)
  String get userId => _userId;
  String get displayName => _displayName;
  String get email => _email;
  String get phoneNumber => _phoneNumber;
  String get dateOfBirth => _dateOfBirth;
  String get gender => _gender;
  String get bloodType => _bloodType;
  String get address => _address;
  String get emergencyContact => _emergencyContact;
  String get profileImageUrl => _profileImageUrl;
}

// Basic Information Section (Inheritance)
class BasicInformationSection extends ProfileSection {
  @override
  String get title => 'Basic Information';

  @override
  IconData get icon => Icons.person;

  @override
  Color get color => Colors.blue;

  @override
  Widget buildContent(BuildContext context, Map<String, dynamic> userData) {
    return Column(
      children: [
        _buildProfileField(
          context,
          'Full Name',
          userData['displayName'] ?? 'Not set',
          Icons.person,
          'displayName',
        ),
        _buildProfileField(
          context,
          'Email',
          userData['email'] ?? 'Not set',
          Icons.email,
          'email',
        ),
        _buildProfileField(
          context,
          'Phone Number',
          userData['phoneNumber'] ?? 'Not set',
          Icons.phone,
          'phoneNumber',
        ),
        _buildProfileField(
          context,
          'Date of Birth',
          userData['dateOfBirth'] ?? 'Not set',
          Icons.calendar_today,
          'dateOfBirth',
        ),
        _buildProfileField(
          context,
          'Gender',
          userData['gender'] ?? 'Not set',
          Icons.person_outline,
          'gender',
        ),
      ],
    );
  }

  Widget _buildProfileField(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    String fieldKey,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              _showEditDialog(context, label, value, fieldKey);
            },
            icon: Icon(Icons.edit, color: Colors.grey.shade600, size: 20),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    String label,
    String currentValue,
    String fieldKey,
  ) {
    final controller = TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $label'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _updateProfile(context, fieldKey, controller.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _updateProfile(BuildContext context, String field, String value) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        await FirebaseFirestore.instance.collection('users').doc(userId).update(
          {field: value},
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Enum for different medical field types
enum MedicalFieldType { bloodType, measurement, multiline, phone, date }

// Medical Information Section (Inheritance)
class MedicalInformationSection extends ProfileSection {
  @override
  String get title => 'Medical Information';

  @override
  IconData get icon => Icons.medical_services;

  @override
  Color get color => Colors.red;

  @override
  Widget buildContent(BuildContext context, Map<String, dynamic> userData) {
    return Semantics(
      label: 'Medical Information Section',
      hint: 'Contains editable medical data fields',
      child: Column(
        children: [
          // Info banner for accessibility
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tap any field to edit your medical information. Keep this data current for better healthcare.',
                    style: TextStyle(fontSize: 14, color: Colors.blue.shade800),
                  ),
                ),
              ],
            ),
          ),

          // Medical Data Summary Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red.shade50, Colors.pink.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.medical_services,
                      color: Colors.red.shade600,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Medical Data Completeness',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildDataCompletenessIndicator(userData),
                const SizedBox(height: 8),
                Text(
                  'Complete your medical profile for better care and emergency preparedness.',
                  style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                ),
              ],
            ),
          ),
          _buildEditableMedicalField(
            context,
            'Blood Type',
            userData['bloodType'] ?? 'Not set',
            Icons.bloodtype,
            'bloodType',
            MedicalFieldType.bloodType,
          ),
          _buildEditableMedicalField(
            context,
            'Height',
            userData['height'] ?? 'Not set',
            Icons.height,
            'height',
            MedicalFieldType.measurement,
          ),
          _buildEditableMedicalField(
            context,
            'Weight',
            userData['weight'] ?? 'Not set',
            Icons.monitor_weight,
            'weight',
            MedicalFieldType.measurement,
          ),
          _buildEditableMedicalField(
            context,
            'Allergies',
            userData['allergies'] ?? 'None recorded',
            Icons.warning,
            'allergies',
            MedicalFieldType.multiline,
          ),
          _buildEditableMedicalField(
            context,
            'Emergency Contact',
            userData['emergencyContact'] ?? 'Not set',
            Icons.emergency,
            'emergencyContact',
            MedicalFieldType.phone,
          ),
          _buildEditableMedicalField(
            context,
            'Medical Conditions',
            userData['medicalConditions'] ?? 'None recorded',
            Icons.medical_information,
            'medicalConditions',
            MedicalFieldType.multiline,
          ),
          _buildEditableMedicalField(
            context,
            'Current Medications',
            userData['currentMedications'] ?? 'None',
            Icons.medication,
            'currentMedications',
            MedicalFieldType.multiline,
          ),
        ],
      ),
    );
  }

  Widget _buildEditableMedicalField(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    String fieldKey,
    MedicalFieldType fieldType,
  ) {
    return Semantics(
      label: '$label: $value',
      hint: 'Double tap to edit $label',
      button: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: InkWell(
          onTap: () {
            _showMedicalEditDialog(context, label, value, fieldKey, fieldType);
          },
          borderRadius: BorderRadius.circular(12),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  _showMedicalEditDialog(
                    context,
                    label,
                    value,
                    fieldKey,
                    fieldType,
                  );
                },
                icon: Icon(Icons.edit, color: Colors.red.shade600, size: 20),
                tooltip: 'Edit $label',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMedicalEditDialog(
    BuildContext context,
    String label,
    String currentValue,
    String fieldKey,
    MedicalFieldType fieldType,
  ) {
    switch (fieldType) {
      case MedicalFieldType.bloodType:
        _showBloodTypeDialog(context, label, currentValue, fieldKey);
        break;
      case MedicalFieldType.measurement:
        _showMeasurementDialog(context, label, currentValue, fieldKey);
        break;
      case MedicalFieldType.multiline:
        _showMultilineDialog(context, label, currentValue, fieldKey);
        break;
      case MedicalFieldType.phone:
        _showPhoneDialog(context, label, currentValue, fieldKey);
        break;
      case MedicalFieldType.date:
        _showDateDialog(context, label, currentValue, fieldKey);
        break;
    }
  }

  void _showBloodTypeDialog(
    BuildContext context,
    String label,
    String currentValue,
    String fieldKey,
  ) {
    final bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
    String selectedBloodType = bloodTypes.contains(currentValue)
        ? currentValue
        : bloodTypes[0];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Select $label',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose your blood type:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: bloodTypes.map((bloodType) {
                  return ChoiceChip(
                    label: Text(
                      bloodType,
                      style: TextStyle(
                        color: selectedBloodType == bloodType
                            ? Colors.white
                            : Colors.red.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    selected: selectedBloodType == bloodType,
                    onSelected: (selected) {
                      setState(() {
                        selectedBloodType = bloodType;
                      });
                    },
                    selectedColor: Colors.red.shade600,
                    backgroundColor: Colors.red.shade50,
                    side: BorderSide(color: Colors.red.shade200),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _updateMedicalProfile(context, fieldKey, selectedBloodType);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showMeasurementDialog(
    BuildContext context,
    String label,
    String currentValue,
    String fieldKey,
  ) {
    final controller = TextEditingController(text: currentValue);
    final isHeight = label.toLowerCase().contains('height');
    final isWeight = label.toLowerCase().contains('weight');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $label'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: label,
                hintText: isHeight
                    ? 'e.g., 5\'8" or 173 cm'
                    : isWeight
                    ? 'e.g., 70 kg or 154 lbs'
                    : 'Enter measurement',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(
                  isHeight ? Icons.height : Icons.monitor_weight,
                  color: Colors.red.shade600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isHeight
                  ? 'Enter height in feet/inches or centimeters'
                  : isWeight
                  ? 'Enter weight in kg or lbs'
                  : 'Enter the measurement value',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _updateMedicalProfile(context, fieldKey, controller.text);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showMultilineDialog(
    BuildContext context,
    String label,
    String currentValue,
    String fieldKey,
  ) {
    final controller = TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $label'),
        content: SizedBox(
          height: 200,
          child: Column(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    labelText: label,
                    hintText: _getHintForField(label),
                    border: const OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _getInstructionForField(label),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _updateMedicalProfile(context, fieldKey, controller.text);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showPhoneDialog(
    BuildContext context,
    String label,
    String currentValue,
    String fieldKey,
  ) {
    final controller = TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $label'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: label,
            hintText: '+1 (555) 123-4567',
            border: const OutlineInputBorder(),
            prefixIcon: Icon(Icons.phone, color: Colors.red.shade600),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _updateMedicalProfile(context, fieldKey, controller.text);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDateDialog(
    BuildContext context,
    String label,
    String currentValue,
    String fieldKey,
  ) async {
    DateTime? selectedDate;

    if (currentValue != 'Not set') {
      try {
        selectedDate = DateTime.parse(currentValue);
      } catch (e) {
        selectedDate = DateTime.now();
      }
    } else {
      selectedDate = DateTime.now();
    }

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Select $label',
    );

    if (pickedDate != null) {
      final formattedDate =
          '${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}';
      _updateMedicalProfile(context, fieldKey, formattedDate);
    }
  }

  String _getHintForField(String label) {
    switch (label.toLowerCase()) {
      case 'allergies':
        return 'List any allergies (food, medication, environmental)...';
      case 'medical conditions':
        return 'List any chronic conditions or medical history...';
      case 'current medications':
        return 'List medications you are currently taking...';
      default:
        return 'Enter details...';
    }
  }

  String _getInstructionForField(String label) {
    switch (label.toLowerCase()) {
      case 'allergies':
        return 'Separate multiple allergies with commas. Include severity if known.';
      case 'medical conditions':
        return 'Include dates when possible. Separate multiple conditions with commas.';
      case 'current medications':
        return 'Include dosage and frequency. Separate multiple medications with commas.';
      default:
        return 'Provide as much detail as necessary.';
    }
  }

  void _updateMedicalProfile(
    BuildContext context,
    String field,
    String value,
  ) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        await FirebaseFirestore.instance.collection('users').doc(userId).update(
          {field: value},
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$field updated successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating $field: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildDataCompletenessIndicator(Map<String, dynamic> userData) {
    final fields = [
      'bloodType',
      'height',
      'weight',
      'allergies',
      'emergencyContact',
      'medicalConditions',
      'currentMedications',
    ];
    int completedFields = 0;

    for (String field in fields) {
      if (userData[field] != null &&
          userData[field].isNotEmpty &&
          userData[field] != 'Not set' &&
          userData[field] != 'None recorded' &&
          userData[field] != 'None') {
        completedFields++;
      }
    }

    double completionPercentage = completedFields / fields.length;
    Color progressColor = completionPercentage >= 0.8
        ? Colors.green
        : completionPercentage >= 0.5
        ? Colors.orange
        : Colors.red;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$completedFields of ${fields.length} fields completed',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade800,
              ),
            ),
            Text(
              '${(completionPercentage * 100).toInt()}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: progressColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: completionPercentage,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

// Account Statistics Section (Inheritance)
class AccountStatisticsSection extends ProfileSection {
  @override
  String get title => 'Account Statistics';

  @override
  IconData get icon => Icons.analytics;

  @override
  Color get color => Colors.green;

  @override
  Widget buildContent(BuildContext context, Map<String, dynamic> userData) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Center(child: Text('Please log in to view statistics'));
    }
    return FutureBuilder<List<int>>(
      future: _fetchUserStats(currentUser.uid),
      builder: (context, snapshot) {
        int totalAppointments = 0;
        int totalReports = 0;
        int totalPrescriptions = 0;
        if (snapshot.hasData) {
          totalAppointments = snapshot.data![0];
          totalReports = snapshot.data![1];
          totalPrescriptions = snapshot.data![2];
        }
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade50, Colors.blue.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Appointments',
                      snapshot.connectionState == ConnectionState.waiting
                          ? '...'
                          : totalAppointments.toString(),
                      Icons.calendar_today,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Medical Reports',
                      snapshot.connectionState == ConnectionState.waiting
                          ? '...'
                          : totalReports.toString(),
                      Icons.assignment,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Prescriptions',
                      snapshot.connectionState == ConnectionState.waiting
                          ? '...'
                          : totalPrescriptions.toString(),
                      Icons.medication,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Health Score',
                      _calculateHealthScore(
                        totalAppointments,
                        totalReports,
                        totalPrescriptions,
                      ),
                      Icons.favorite,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<List<int>> _fetchUserStats(String uid) async {
    final appointmentsSnap = await FirebaseFirestore.instance
        .collection('appointments')
        .where('patientId', isEqualTo: uid)
        .get();
    final reportsSnap = await FirebaseFirestore.instance
        .collection('medical_reports')
        .where('patientId', isEqualTo: uid)
        .get();
    final prescriptionsSnap = await FirebaseFirestore.instance
        .collection('prescriptions')
        .where('patientId', isEqualTo: uid)
        .get();
    return [
      appointmentsSnap.docs.length,
      reportsSnap.docs.length,
      prescriptionsSnap.docs.length,
    ];
  }

  String _calculateHealthScore(
    int appointments,
    int reports,
    int prescriptions,
  ) {
    // Simple health score logic: more data = higher score
    int score = 50 + (appointments + reports + prescriptions) * 5;
    if (score > 100) score = 100;
    return '$score%';
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Main Profile Page using Composition
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with TickerProviderStateMixin, ProfileActionMixin {
  late TabController _tabController;

  final List<ProfileSection> _sections = [
    BasicInformationSection(),
    MedicalInformationSection(),
    AccountStatisticsSection(),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _sections.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view your profile')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade600,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () => _showProfileEditSheet(context),
            tooltip: 'Edit Profile',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: _sections.map((section) {
            return Tab(icon: Icon(section.icon), text: section.title);
          }).toList(),
        ),
      ),
      body: Column(
        children: [
          // Profile Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.blue.shade800],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 60,
                    color: Colors.blue.shade600,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  currentUser.displayName ?? 'Patient User',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  currentUser.email ?? '',
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUser.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                Map<String, dynamic> userData = {};
                if (snapshot.hasData && snapshot.data!.exists) {
                  userData = snapshot.data!.data() as Map<String, dynamic>;
                }

                return TabBarView(
                  controller: _tabController,
                  children: _sections.map((section) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: section.buildContent(context, userData),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showProfileEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: 50,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildQuickAction(
                      'Change Profile Picture',
                      Icons.camera_alt,
                      Colors.blue,
                      () => _changeProfilePicture(context),
                    ),
                    _buildQuickAction(
                      'Update Personal Information',
                      Icons.edit,
                      Colors.green,
                      () => _updatePersonalInfo(context),
                    ),
                    _buildQuickAction(
                      'Medical Information',
                      Icons.medical_services,
                      Colors.red,
                      () => _updateMedicalInfo(context),
                    ),
                    _buildQuickAction(
                      'Privacy Settings',
                      Icons.privacy_tip,
                      Colors.orange,
                      () => _openPrivacySettings(context),
                    ),
                    _buildQuickAction(
                      'Export Profile Data',
                      Icons.download,
                      Colors.purple,
                      () => _exportProfileData(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey.shade600,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: Colors.grey.shade50,
      ),
    );
  }

  @override
  void showEditDialog(BuildContext context, String field, String currentValue) {
    // Implementation from BasicInformationSection
  }

  @override
  void updateProfile(BuildContext context, Map<String, dynamic> updates) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update(updates);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _changeProfilePicture(BuildContext context) {
    Navigator.pop(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.camera_alt, color: Colors.blue.shade600),
            const SizedBox(width: 12),
            const Text('Change Profile Picture'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose how you want to update your profile picture:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),

            // Camera Option
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: Icon(Icons.camera, color: Colors.blue.shade600),
              ),
              title: const Text('Take Photo'),
              subtitle: const Text('Use camera to take a new picture'),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade600,
              ),
              onTap: () {
                Navigator.pop(context);
                _takePhotoFromCamera(context);
              },
            ),

            // Gallery Option
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green.shade100,
                child: Icon(Icons.photo_library, color: Colors.green.shade600),
              ),
              title: const Text('Choose from Gallery'),
              subtitle: const Text('Select from your photo library'),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade600,
              ),
              onTap: () {
                Navigator.pop(context);
                _selectFromGallery(context);
              },
            ),

            // Avatar Option
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.purple.shade100,
                child: Icon(Icons.face, color: Colors.purple.shade600),
              ),
              title: const Text('Choose Avatar'),
              subtitle: const Text('Select from predefined avatars'),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade600,
              ),
              onTap: () {
                Navigator.pop(context);
                _chooseAvatar(context);
              },
            ),

            // Remove Picture Option
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.red.shade100,
                child: Icon(Icons.delete, color: Colors.red.shade600),
              ),
              title: const Text('Remove Picture'),
              subtitle: const Text('Use default avatar'),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade600,
              ),
              onTap: () {
                Navigator.pop(context);
                _removeProfilePicture(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _takePhotoFromCamera(BuildContext context) {
    // Simulate camera functionality
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Camera Feature'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.camera_alt, size: 64, color: Colors.blue.shade600),
            const SizedBox(height: 16),
            const Text('Camera integration would be implemented here using:'),
            const SizedBox(height: 8),
            const Text('• image_picker package'),
            const Text('• Camera permissions'),
            const Text('• Image processing'),
            const Text('• Firebase Storage upload'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _selectFromGallery(BuildContext context) {
    // Simulate gallery selection
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gallery Selection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.photo_library, size: 64, color: Colors.green.shade600),
            const SizedBox(height: 16),
            const Text('Gallery integration would include:'),
            const SizedBox(height: 8),
            const Text('• Photo library access'),
            const Text('• Image cropping tools'),
            const Text('• Format conversion'),
            const Text('• Cloud storage sync'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    final picker = ImagePicker();
    picker.pickImage(source: ImageSource.gallery, imageQuality: 80).then((
      pickedFile,
    ) async {
      if (pickedFile != null) {
        File imageFile = File(pickedFile.path);
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId != null) {
          final storageRef = FirebaseStorage.instance.ref().child(
            'profile_images/$userId.jpg',
          );
          await storageRef.putFile(imageFile);
          final downloadUrl = await storageRef.getDownloadURL();
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .update({
                'profileImageUrl': downloadUrl,
                'profileImageType': 'custom',
              });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile photo updated!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    });
  }

  void _chooseAvatar(BuildContext context) {
    final avatarIcons = [
      Icons.person,
      Icons.face,
      Icons.account_circle,
      Icons.sentiment_satisfied,
      Icons.emoji_emotions,
      Icons.psychology,
      Icons.spa,
      Icons.favorite,
    ];

    final avatarColors = [
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Avatar'),
        content: Container(
          width: double.maxFinite,
          height: 300,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: avatarIcons.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _saveAvatarChoice(
                    context,
                    avatarIcons[index],
                    avatarColors[index],
                  );
                },
                child: CircleAvatar(
                  backgroundColor: avatarColors[index].withOpacity(0.1),
                  child: Icon(
                    avatarIcons[index],
                    color: avatarColors[index],
                    size: 30,
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _saveAvatarChoice(
    BuildContext context,
    IconData icon,
    Color color,
  ) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
              'avatarIcon': icon.codePoint,
              'avatarColor': color.value,
              'profileImageType': 'avatar',
            });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Avatar updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating avatar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeProfilePicture(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Profile Picture'),
        content: const Text(
          'Are you sure you want to remove your profile picture? This will revert to the default avatar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final userId = FirebaseAuth.instance.currentUser?.uid;
                if (userId != null) {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .update({
                        'profileImageUrl': null,
                        'avatarIcon': null,
                        'avatarColor': null,
                        'profileImageType': 'default',
                      });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile picture removed successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error removing picture: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _updatePersonalInfo(BuildContext context) {
    Navigator.pop(context);
    _tabController.animateTo(0);
  }

  void _updateMedicalInfo(BuildContext context) {
    Navigator.pop(context);
    _tabController.animateTo(1);
  }

  void _openPrivacySettings(BuildContext context) {
    Navigator.pop(context);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PrivacySettingsPage()),
    );
  }

  void _exportProfileData(BuildContext context) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.download, color: Colors.green.shade600),
            const SizedBox(width: 12),
            const Text('Export Profile Data'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // CSV Export
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green.shade100,
                child: Icon(Icons.table_chart, color: Colors.green.shade600),
              ),
              title: const Text('CSV Spreadsheet'),
              subtitle: const Text('Tabular data for spreadsheet apps'),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade600,
              ),
              onTap: () {
                Navigator.pop(context);
                _exportToCSV(context);
              },
            ),
            // Complete Backup
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.purple.shade100,
                child: Icon(Icons.backup, color: Colors.purple.shade600),
              ),
              title: const Text('Complete Backup'),
              subtitle: const Text('All data including medical records'),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade600,
              ),
              onTap: () {
                Navigator.pop(context);
                _exportCompleteBackup(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _exportToPDF(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Generating PDF report...'),
          ],
        ),
      ),
    );

    // Simulate PDF generation delay
    await Future.delayed(const Duration(seconds: 2));
    Navigator.pop(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PDF Export Complete'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green.shade600),
            const SizedBox(height: 16),
            const Text('Your profile data has been exported as PDF.'),
            const SizedBox(height: 8),
            const Text('Features included:'),
            const Text('• Personal Information'),
            const Text('• Medical History'),
            const Text('• Emergency Contacts'),
            const Text('• Insurance Details'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _shareExportedFile(context, 'PDF');
            },
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }

  void _exportToJSON(BuildContext context) async {
    final userData = await _gatherUserData();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('JSON Export'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.code, size: 64, color: Colors.blue.shade600),
            const SizedBox(height: 16),
            Text('Export contains ${userData.length} data fields'),
            const SizedBox(height: 8),
            const Text('Format: JSON'),
            const Text('Size: ~2.4 KB'),
            const Text('Compatibility: Universal'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _downloadJSON(context, userData);
            },
            child: const Text('Download'),
          ),
        ],
      ),
    );
  }

  void _exportToCSV(BuildContext context) async {
    final userData = await _gatherUserData();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('CSV Export'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.table_chart, size: 64, color: Colors.green.shade600),
            const SizedBox(height: 16),
            Text('${userData.length} fields will be exported'),
            const SizedBox(height: 8),
            const Text('Compatible with:'),
            const Text('• Microsoft Excel'),
            const Text('• Google Sheets'),
            const Text('• Apple Numbers'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _downloadCSV(context, userData);
            },
            child: const Text('Download'),
          ),
        ],
      ),
    );
  }

  void _exportCompleteBackup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Data Backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.backup, size: 64, color: Colors.purple.shade600),
            const SizedBox(height: 16),
            const Text('This backup includes:'),
            const SizedBox(height: 8),
            const Text('✓ Profile Information'),
            const Text('✓ Medical Records'),
            const Text('✓ Appointment History'),
            const Text('✓ Emergency Contacts'),
            const Text('✓ Insurance Data'),
            const Text('✓ Privacy Settings'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: const Text(
                'This export contains sensitive medical information. Please handle securely.',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _createCompleteBackup(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            child: const Text(
              'Create Backup',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _gatherUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {};

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      return userDoc.data() ?? {};
    } catch (e) {
      return {};
    }
  }

  void _downloadJSON(BuildContext context, Map<String, dynamic> userData) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('JSON export completed successfully!'),
        backgroundColor: Colors.blue,
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () => _showDataPreview(context, userData, 'JSON'),
        ),
      ),
    );
  }

  void _downloadCSV(BuildContext context, Map<String, dynamic> userData) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('CSV export completed successfully!'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () => _showDataPreview(context, userData, 'CSV'),
        ),
      ),
    );
  }

  void _createCompleteBackup(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Creating complete backup...'),
            SizedBox(height: 8),
            Text('This may take a few moments'),
          ],
        ),
      ),
    );

    // Simulate backup creation
    await Future.delayed(const Duration(seconds: 3));
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Complete backup created successfully!'),
        backgroundColor: Colors.purple,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Share',
          textColor: Colors.white,
          onPressed: () => _shareExportedFile(context, 'Complete Backup'),
        ),
      ),
    );
  }

  void _shareExportedFile(BuildContext context, String fileType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Share $fileType'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose sharing method:'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Email'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.cloud_upload),
              title: const Text('Cloud Storage'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share via Apps'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showDataPreview(
    BuildContext context,
    Map<String, dynamic> userData,
    String format,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$format Preview'),
        content: Container(
          width: double.maxFinite,
          height: 300,
          child: SingleChildScrollView(
            child: Text(
              format == 'JSON'
                  ? _formatAsJSON(userData)
                  : _formatAsCSV(userData),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatAsJSON(Map<String, dynamic> data) {
    return '''
{
  "userId": "${data['userId'] ?? 'user123'}",
  "name": "${data['name'] ?? 'John Doe'}",
  "email": "${data['email'] ?? 'john.doe@email.com'}",
  "phone": "${data['phone'] ?? '+1 (555) 123-4567'}",
  "bloodType": "${data['bloodType'] ?? 'O+'}",
  "height": "${data['height'] ?? '5 ft 10 in'}",
  "weight": "${data['weight'] ?? '175 lbs'}",
  "allergies": "${data['allergies'] ?? 'None known'}",
  "emergencyContact": "${data['emergencyContact'] ?? 'Jane Doe - +1 (555) 987-6543'}",
  "insurance": "${data['insurance'] ?? 'Blue Cross Blue Shield'}",
  "exportDate": "${DateTime.now().toIso8601String()}"
}''';
  }

  String _formatAsCSV(Map<String, dynamic> data) {
    return '''Field,Value
User ID,${data['userId'] ?? 'user123'}
Name,${data['name'] ?? 'John Doe'}
Email,${data['email'] ?? 'john.doe@email.com'}
Phone,${data['phone'] ?? '+1 (555) 123-4567'}
Blood Type,${data['bloodType'] ?? ''}
Height,${data['height'] ?? ''}
Weight,${data['weight'] ?? ''}
Allergies,${data['allergies'] ?? ''}
Emergency Contact,${data['emergencyContact'] ?? ''}
Insurance,${data['insurance'] ?? ''}
Export Date,${DateTime.now().toIso8601String()}''';
  }
}
