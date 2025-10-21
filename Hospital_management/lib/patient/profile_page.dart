import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'settings_page.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';

// Conditional import for web functionality
import 'dart:html'
    as html
    show FileUploadInputElement, FileReader, Blob, Url, AnchorElement;

// Abstract base class for profile sections
abstract class ProfileSection {
  String get title;
  IconData get icon;
  Color get color;
  Widget buildContent(
    BuildContext context,
    Map<String, dynamic> userData,
    VoidCallback onUpdate,
  );
}

// Personal Information Section
class PersonalInformationSection extends ProfileSection {
  @override
  String get title => 'Personal Information';
  @override
  IconData get icon => Icons.person;
  @override
  Color get color => Colors.blue;

  @override
  Widget buildContent(
    BuildContext context,
    Map<String, dynamic> userData,
    VoidCallback onUpdate,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Personal Information',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () =>
                      _editPersonalInfo(context, userData, onUpdate),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Name', userData['name'] ?? 'N/A'),
            _buildInfoRow('Age', userData['age']?.toString() ?? 'N/A'),
            _buildInfoRow('Date of Birth', userData['dateOfBirth'] ?? 'N/A'),
            _buildInfoRow('Gender', userData['gender'] ?? 'N/A'),
            _buildInfoRow('Phone', userData['phone'] ?? 'N/A'),
            _buildInfoRow('Address', userData['address'] ?? 'N/A'),
            _buildInfoRow(
              'Emergency Contact',
              userData['emergencyContact'] ?? 'N/A',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _editPersonalInfo(
    BuildContext context,
    Map<String, dynamic> userData,
    VoidCallback onUpdate,
  ) {
    final nameController = TextEditingController(text: userData['name'] ?? '');
    final ageController = TextEditingController(
      text: userData['age']?.toString() ?? '',
    );
    final dobController = TextEditingController(
      text: userData['dateOfBirth'] ?? '',
    );
    final phoneController = TextEditingController(
      text: userData['phone'] ?? '',
    );
    final addressController = TextEditingController(
      text: userData['address'] ?? '',
    );
    final emergencyController = TextEditingController(
      text: userData['emergencyContact'] ?? '',
    );
    String selectedGender = userData['gender'] ?? 'Male';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Personal Information'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ageController,
                decoration: const InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: dobController,
                decoration: const InputDecoration(
                  labelText: 'Date of Birth (DD/MM/YYYY)',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedGender,
                decoration: const InputDecoration(labelText: 'Gender'),
                items: ['Male', 'Female', 'Other'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (value) => selectedGender = value!,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Address'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emergencyController,
                decoration: const InputDecoration(
                  labelText: 'Emergency Contact',
                ),
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
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .update({
                      'name': nameController.text,
                      'age': int.tryParse(ageController.text) ?? 0,
                      'dateOfBirth': dobController.text,
                      'gender': selectedGender,
                      'phone': phoneController.text,
                      'address': addressController.text,
                      'emergencyContact': emergencyController.text,
                    });
                onUpdate();
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Personal information updated'),
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// Insurance Information Section
class InsuranceInformationSection extends ProfileSection {
  @override
  String get title => 'Insurance Information';
  @override
  IconData get icon => Icons.shield;
  @override
  Color get color => Colors.green;

  @override
  Widget buildContent(
    BuildContext context,
    Map<String, dynamic> userData,
    VoidCallback onUpdate,
  ) {
    final insuranceData = userData['insurance'];
    final insurance = Map<String, dynamic>.from(insuranceData ?? {});
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shield, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'Insurance Information',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editInsurance(context, insurance, onUpdate),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Provider', insurance['provider'] ?? 'N/A'),
            _buildInfoRow('Policy #', insurance['policyNumber'] ?? 'N/A'),
            _buildInfoRow('Group #', insurance['groupNumber'] ?? 'N/A'),
            _buildInfoRow('Phone', insurance['phone'] ?? 'N/A'),
            _buildInfoRow('Valid Through', insurance['validThrough'] ?? 'N/A'),
            _buildInfoRow('Plan Type', insurance['planType'] ?? 'N/A'),
            _buildInfoRow(
              'Coverage Level',
              insurance['coverageLevel'] ?? 'N/A',
            ),
            _buildInfoRow('Deductible', insurance['deductible'] ?? 'N/A'),
            _buildInfoRow('Copay', insurance['copay'] ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _editInsurance(
    BuildContext context,
    Map<String, dynamic> insurance,
    VoidCallback onUpdate,
  ) {
    final providerController = TextEditingController(
      text: insurance['provider'] ?? '',
    );
    final policyController = TextEditingController(
      text: insurance['policyNumber'] ?? '',
    );
    final groupController = TextEditingController(
      text: insurance['groupNumber'] ?? '',
    );
    final phoneController = TextEditingController(
      text: insurance['phone'] ?? '',
    );
    final validThroughController = TextEditingController(
      text: insurance['validThrough'] ?? '',
    );
    final planTypeController = TextEditingController(
      text: insurance['planType'] ?? '',
    );
    final coverageLevelController = TextEditingController(
      text: insurance['coverageLevel'] ?? '',
    );
    final deductibleController = TextEditingController(
      text: insurance['deductible'] ?? '',
    );
    final copayController = TextEditingController(
      text: insurance['copay'] ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Insurance Information'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: providerController,
                decoration: const InputDecoration(
                  labelText: 'Insurance Provider',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: policyController,
                decoration: const InputDecoration(labelText: 'Policy Number'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: groupController,
                decoration: const InputDecoration(labelText: 'Group Number'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Insurance Phone'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: validThroughController,
                decoration: const InputDecoration(
                  labelText: 'Valid Through (MM/YYYY)',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: planTypeController,
                decoration: const InputDecoration(
                  labelText: 'Plan Type (e.g., HMO, PPO)',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: coverageLevelController,
                decoration: const InputDecoration(
                  labelText: 'Coverage Level (e.g., Individual, Family)',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: deductibleController,
                decoration: const InputDecoration(
                  labelText: 'Deductible Amount',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: copayController,
                decoration: const InputDecoration(labelText: 'Copay Amount'),
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
            onPressed: () async {
              // Collect insurance data
              final insuranceData = {
                'provider': providerController.text.trim(),
                'policyNumber': policyController.text.trim(),
                'groupNumber': groupController.text.trim(),
                'phone': phoneController.text.trim(),
                'validThrough': validThroughController.text.trim(),
                'planType': planTypeController.text.trim(),
                'coverageLevel': coverageLevelController.text.trim(),
                'deductible': deductibleController.text.trim(),
                'copay': copayController.text.trim(),
              };

              // Validate data
              final errors = FirestoreService.validateInsuranceData(
                insuranceData,
              );
              if (errors.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Validation errors: ${errors.values.join(', ')}',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              // Save to Firestore using service
              final success = await FirestoreService.saveInsuranceInfo(
                insuranceData,
              );

              if (success) {
                onUpdate();
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Insurance information updated successfully',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to update insurance information'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// Basic Health Information Section
class BasicHealthInfoSection extends ProfileSection {
  @override
  String get title => 'Basic Health Info';
  @override
  IconData get icon => Icons.health_and_safety;
  @override
  Color get color => Colors.green;

  @override
  Widget buildContent(
    BuildContext context,
    Map<String, dynamic> userData,
    VoidCallback onUpdate,
  ) {
    final basicHealthInfo = userData['basicHealthInfo'] ?? {};
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.health_and_safety, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'Basic Health Information',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () =>
                      _editBasicHealthInfo(context, basicHealthInfo, onUpdate),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              'Blood Group',
              basicHealthInfo['bloodGroup'] ?? 'Not specified',
            ),
            _buildInfoRow(
              'Weight',
              basicHealthInfo['weight'] ?? 'Not specified',
            ),
            _buildInfoRow(
              'Height',
              basicHealthInfo['height'] ?? 'Not specified',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: value == 'Not specified' ? Colors.grey : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editBasicHealthInfo(
    BuildContext context,
    Map<String, dynamic> basicHealthInfo,
    VoidCallback onUpdate,
  ) {
    final bloodGroupController = TextEditingController(
      text: basicHealthInfo['bloodGroup'] ?? '',
    );
    final weightController = TextEditingController(
      text: basicHealthInfo['weight'] ?? '',
    );
    final heightController = TextEditingController(
      text: basicHealthInfo['height'] ?? '',
    );

    // Blood group dropdown options
    final bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
    String? selectedBloodGroup = basicHealthInfo['bloodGroup'] ?? '';
    if (!bloodGroups.contains(selectedBloodGroup)) {
      selectedBloodGroup = null;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Basic Health Info'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedBloodGroup,
                  decoration: const InputDecoration(
                    labelText: 'Blood Group',
                    border: OutlineInputBorder(),
                  ),
                  items: bloodGroups.map((String bloodGroup) {
                    return DropdownMenuItem<String>(
                      value: bloodGroup,
                      child: Text(bloodGroup),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setDialogState(() {
                      selectedBloodGroup = newValue;
                      bloodGroupController.text = newValue ?? '';
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: weightController,
                  decoration: const InputDecoration(
                    labelText: 'Weight',
                    hintText: 'e.g., 70 kg',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: heightController,
                  decoration: const InputDecoration(
                    labelText: 'Height',
                    hintText: 'e.g., 175 cm',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
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
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) return;

                // Collect basic health info data
                final healthData = {
                  'bloodGroup': selectedBloodGroup ?? '',
                  'weight': weightController.text.trim(),
                  'height': heightController.text.trim(),
                };

                // Simple validation
                if (healthData['weight']!.isNotEmpty &&
                    !RegExp(
                      r'^\d+(\.\d+)?\s*(kg|kgs?)?$',
                      caseSensitive: false,
                    ).hasMatch(healthData['weight']!)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please enter weight in valid format (e.g., 70 kg)',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (healthData['height']!.isNotEmpty &&
                    !RegExp(
                      r'^\d+(\.\d+)?\s*(cm|cms?)?$',
                      caseSensitive: false,
                    ).hasMatch(healthData['height']!)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please enter height in valid format (e.g., 175 cm)',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  // Save to Firestore
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .update({'basicHealthInfo': healthData});

                  onUpdate();
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Basic health info updated successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to update health info: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

// Profile Page Widget
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final List<ProfileSection> sections = [
    PersonalInformationSection(),
    BasicHealthInfoSection(),
  ];

  void _refreshProfile() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showPrivacySettings(context),
            tooltip: 'Settings',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final userData = snapshot.data?.data() as Map<String, dynamic>? ?? {};

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Profile Header with editable photo
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundImage:
                                  userData['profileImageUrl'] != null
                                  ? NetworkImage(userData['profileImageUrl'])
                                  : null,
                              child: userData['profileImageUrl'] == null
                                  ? const Icon(Icons.person, size: 40)
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.blue,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(
                                    Icons.camera_alt,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                  onPressed: () =>
                                      _editProfileImage(context, userData),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userData['name'] ?? 'User',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                user.email ?? 'No email',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.verified_user,
                                    size: 16,
                                    color: user.emailVerified
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    user.emailVerified
                                        ? 'Verified'
                                        : 'Not Verified',
                                    style: TextStyle(
                                      color: user.emailVerified
                                          ? Colors.green
                                          : Colors.orange,
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (!user.emailVerified) ...[
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () =>
                                          _sendVerificationEmail(context),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: const Text(
                                          'Verify',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Email Verification Banner (only show if not verified)
                if (!user.emailVerified)
                  Card(
                    color: Colors.amber.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.warning_amber,
                                color: Colors.amber.shade700,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Email Verification Required',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber.shade800,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Please verify your email to access all features and secure your account.',
                                      style: TextStyle(
                                        color: Colors.amber.shade700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () =>
                                      _showVerificationDialog(context),
                                  icon: const Icon(Icons.email),
                                  label: const Text('Verify Email'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber.shade600,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton(
                                onPressed: () =>
                                    _checkVerificationStatus(context),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.amber.shade700,
                                  side: BorderSide(
                                    color: Colors.amber.shade600,
                                  ),
                                ),
                                child: const Text('Refresh'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                if (!user.emailVerified) const SizedBox(height: 16),

                // Quick Stats Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quick Stats',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatColumn(
                              'Appointments',
                              '${userData['totalAppointments'] ?? 0}',
                              Icons.calendar_today,
                            ),
                            _buildStatColumn(
                              'Medicine Orders',
                              '${userData['totalMedicineOrders'] ?? 0}',
                              Icons.medication,
                            ),
                            _buildStatColumn(
                              'Profile',
                              '${_calculateProfileCompletion(userData)}%',
                              Icons.person,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Profile Sections
                ...sections.map(
                  (section) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: section.buildContent(
                      context,
                      userData,
                      _refreshProfile,
                    ),
                  ),
                ),

                // Additional Actions Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Account Actions',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (!user.emailVerified)
                          ListTile(
                            leading: const Icon(
                              Icons.verified_user,
                              color: Colors.blue,
                            ),
                            title: const Text('Verify Email'),
                            subtitle: const Text('Required for full access'),
                            onTap: () => _showVerificationDialog(context),
                          ),
                        ListTile(
                          leading: const Icon(
                            Icons.security,
                            color: Colors.orange,
                          ),
                          title: const Text('Privacy Settings'),
                          onTap: () => _showPrivacySettings(context),
                        ),
                        ListTile(
                          leading: const Icon(
                            Icons.download,
                            color: Colors.green,
                          ),
                          title: const Text('Download Data'),
                          onTap: () => _downloadUserData(context, userData),
                        ),
                        ListTile(
                          leading: const Icon(
                            Icons.delete_forever,
                            color: Colors.red,
                          ),
                          title: const Text('Delete Account'),
                          onTap: () => _showDeleteAccountDialog(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  int _calculateProfileCompletion(Map<String, dynamic> userData) {
    int completed = 0;
    int total = 12;

    // Personal Information (7 fields)
    if (userData['name']?.isNotEmpty == true) completed++;
    if (userData['phone']?.isNotEmpty == true) completed++;
    if (userData['address']?.isNotEmpty == true) completed++;
    if (userData['dateOfBirth']?.isNotEmpty == true) completed++;
    if (userData['gender']?.isNotEmpty == true) completed++;
    if (userData['emergencyContact']?.isNotEmpty == true) completed++;
    if (userData['profileImageUrl']?.isNotEmpty == true) completed++;

    // Medical Information (5 key fields)
    if (userData['medicalHistory']?['bloodType']?.isNotEmpty == true)
      completed++;
    if (userData['medicalHistory']?['allergies']?.isNotEmpty == true)
      completed++;
    if (userData['medicalHistory']?['conditions']?.isNotEmpty == true)
      completed++;
    if (userData['medicalHistory']?['weight']?.isNotEmpty == true) completed++;
    if (userData['medicalHistory']?['height']?.isNotEmpty == true) completed++;

    return ((completed / total) * 100).round();
  }

  void _editProfileImage(BuildContext context, Map<String, dynamic> userData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Profile Picture'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose how to update your profile picture:'),
            const SizedBox(height: 16),
            if (kIsWeb) ...[
              ElevatedButton.icon(
                onPressed: () => _pickImageWeb(context),
                icon: const Icon(Icons.file_upload),
                label: const Text('Choose from Files'),
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: () => _pickImage(context, ImageSource.camera),
                icon: const Icon(Icons.camera),
                label: const Text('Take Photo'),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => _pickImage(context, ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Choose from Gallery'),
              ),
            ],
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

  Future<void> _pickImageWeb(BuildContext context) async {
    try {
      final html.FileUploadInputElement uploadInput =
          html.FileUploadInputElement();
      uploadInput.accept = 'image/*';
      uploadInput.click();

      uploadInput.onChange.listen((e) async {
        final files = uploadInput.files;
        if (files!.isEmpty) return;

        final reader = html.FileReader();
        reader.readAsArrayBuffer(files[0]);
        reader.onLoadEnd.listen((e) async {
          final imageData = reader.result as Uint8List;
          await _uploadImageData(context, imageData, files[0].name);
        });
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);

      if (image != null) {
        final imageData = await image.readAsBytes();
        await _uploadImageData(context, imageData, image.name);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  Future<void> _uploadImageData(
    BuildContext context,
    Uint8List imageData,
    String fileName,
  ) async {
    try {
      Navigator.pop(context); // Close the dialog

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Uploading image...'),
            ],
          ),
        ),
      );

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Upload to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${user.uid}.jpg');

      await storageRef.putData(imageData);
      final downloadUrl = await storageRef.getDownloadURL();

      // Update user document with image URL
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'profileImageUrl': downloadUrl},
      );

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully!'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error uploading image: $e')));
      }
    }
  }

  void _showPrivacySettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsPage()),
    );
  }

  void _downloadUserData(BuildContext context, Map<String, dynamic> userData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download User Data'),
        content: const Text(
          'This will download all your personal data in JSON format. '
          'This includes your profile information, medical history, and appointment data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) return;

                // Collect all user data
                final userDoc = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .get();

                final appointmentsQuery = await FirebaseFirestore.instance
                    .collection('appointments')
                    .where('patientId', isEqualTo: user.uid)
                    .get();

                final exportData = {
                  'profile': userDoc.data(),
                  'appointments': appointmentsQuery.docs
                      .map((doc) => doc.data())
                      .toList(),
                  'exportDate': DateTime.now().toIso8601String(),
                };

                // For web, create and download file
                if (kIsWeb) {
                  final jsonString = exportData.toString();
                  final bytes = Uint8List.fromList(jsonString.codeUnits);
                  final blob = html.Blob([bytes]);
                  final url = html.Url.createObjectUrlFromBlob(blob);
                  html.AnchorElement(href: url)
                    ..setAttribute(
                      'download',
                      'user_data_${DateTime.now().millisecondsSinceEpoch}.json',
                    )
                    ..click();
                  html.Url.revokeObjectUrl(url);
                }

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('User data download initiated!'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error downloading data: $e')),
                  );
                }
              }
            },
            child: const Text('Download'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) return;

                // Show confirmation dialog
                final confirmed =
                    await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Final Confirmation'),
                        content: const Text(
                          'Type "DELETE" to confirm account deletion. This will permanently remove all your data.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextEditingController().text == 'DELETE'
                              ? ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text(
                                    'Delete Forever',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                )
                              : const SizedBox(),
                        ],
                      ),
                    ) ??
                    false;

                if (confirmed) {
                  // Delete user data from Firestore
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .delete();

                  // Delete user appointments
                  final appointments = await FirebaseFirestore.instance
                      .collection('appointments')
                      .where('patientId', isEqualTo: user.uid)
                      .get();

                  for (var doc in appointments.docs) {
                    await doc.reference.delete();
                  }

                  // Delete the user account
                  await user.delete();

                  if (context.mounted) {
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/', (route) => false);
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting account: $e')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  // Email verification methods
  Future<void> _sendVerificationEmail(BuildContext context) async {
    try {
      final authService = AuthService();
      final result = await authService.resendVerificationEmail();

      if (result['success']) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: result['cooldown'] ?? 3),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending verification email: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _checkVerificationStatus(BuildContext context) async {
    try {
      final authService = AuthService();
      final isVerified = await authService.isEmailVerified();

      if (isVerified) {
        // Update verification status in Firestore
        await authService.updateVerificationStatus(true);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email verified successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          // Refresh the profile to update UI
          setState(() {});
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email not yet verified. Please check your inbox.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking verification status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showVerificationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.email, color: Colors.blue),
            SizedBox(width: 8),
            Text('Email Verification'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your email address is not verified. Please verify your email to:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            const Text('• Access all features'),
            const Text('• Secure your account'),
            const Text('• Receive important notifications'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Check your inbox and click the verification link.',
                      style: TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _sendVerificationEmail(context);
            },
            child: const Text('Send Email'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _checkVerificationStatus(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('I\'ve Verified'),
          ),
        ],
      ),
    );
  }
}

// Utility class for Firestore data management
class ProfileDataManager {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Save insurance information to Firestore
  static Future<bool> saveInsuranceInfo(
    Map<String, dynamic> insuranceData,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'insurance': insuranceData,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        return true;
      }
      return false;
    } catch (e) {
      print('Error saving insurance info: $e');
      return false;
    }
  }

  // Save medical history to Firestore
  static Future<bool> saveMedicalHistory(
    Map<String, dynamic> medicalData,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'medicalHistory': medicalData,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        return true;
      }
      return false;
    } catch (e) {
      print('Error saving medical history: $e');
      return false;
    }
  }

  // Load user profile data from Firestore
  static Future<Map<String, dynamic>> loadUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        return doc.data() ?? {};
      }
      return {};
    } catch (e) {
      print('Error loading user profile: $e');
      return {};
    }
  }

  // Validate insurance data
  static Map<String, String?> validateInsuranceData(Map<String, dynamic> data) {
    Map<String, String?> errors = {};

    if (data['provider']?.toString().trim().isEmpty ?? true) {
      errors['provider'] = 'Provider is required';
    }

    if (data['policyNumber']?.toString().trim().isEmpty ?? true) {
      errors['policyNumber'] = 'Policy number is required';
    }

    // Validate phone number format
    final phone = data['phone']?.toString().trim() ?? '';
    if (phone.isNotEmpty &&
        !RegExp(r'^\+?[\d\s\-\(\)]{10,}$').hasMatch(phone)) {
      errors['phone'] = 'Invalid phone number format';
    }

    return errors;
  }

  // Validate medical history data
  static Map<String, String?> validateMedicalData(Map<String, dynamic> data) {
    Map<String, String?> errors = {};

    // Validate blood type
    final bloodType = data['bloodType']?.toString().trim() ?? '';
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
      errors['bloodType'] = 'Invalid blood type';
    }

    // Validate weight
    final weight = data['weight']?.toString().trim() ?? '';
    if (weight.isNotEmpty) {
      final weightNum = double.tryParse(weight);
      if (weightNum == null || weightNum <= 0 || weightNum > 1000) {
        errors['weight'] = 'Weight must be between 1 and 1000 kg';
      }
    }

    // Validate height
    final height = data['height']?.toString().trim() ?? '';
    if (height.isNotEmpty) {
      final heightNum = double.tryParse(height);
      if (heightNum == null || heightNum <= 0 || heightNum > 300) {
        errors['height'] = 'Height must be between 1 and 300 cm';
      }
    }

    return errors;
  }

  // Create backup of user data
  static Future<bool> createDataBackup() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userData = await loadUserProfile();
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('backups')
            .add({
              'data': userData,
              'timestamp': FieldValue.serverTimestamp(),
              'type': 'profile_backup',
            });
        return true;
      }
      return false;
    } catch (e) {
      print('Error creating backup: $e');
      return false;
    }
  }

  // Stream user profile data for real-time updates
  static Stream<DocumentSnapshot> getUserProfileStream() {
    final user = _auth.currentUser;
    if (user != null) {
      return _firestore.collection('users').doc(user.uid).snapshots();
    }
    return const Stream.empty();
  }
}
