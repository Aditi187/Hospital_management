import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';

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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Basic Health Info'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: bloodGroupController,
                decoration: const InputDecoration(
                  labelText: 'Blood Group',
                  border: OutlineInputBorder(),
                ),
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
                'bloodGroup': bloodGroupController.text.trim(),
                'weight': weightController.text.trim(),
                'height': heightController.text.trim(),
              };

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
                // Profile Header
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.blue.shade100,
                          child: const Icon(Icons.person, size: 40, color: Colors.blue),
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
                              // Patient ID Display Box
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue.shade200),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.badge,
                                      size: 16,
                                      color: Colors.blue.shade700,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Patient ID: ${userData['patientId'] ?? 'N/A'}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue.shade800,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

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
            onPressed: () {
              // Implementation for downloading data
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Download feature would be implemented here'),
                ),
              );
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
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deletion feature would be implemented here'),
                ),
              );
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