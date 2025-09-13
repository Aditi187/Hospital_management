import 'services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'doctor_consultation_page.dart';
import 'appointment_history_page_fixed.dart';
import 'patient_information_page.dart';
import 'profile_page.dart';
import 'settings_page.dart';
import 'help_support_page.dart';
import 'medical_reports_page.dart';
import 'medicine_ordering_page.dart';

// Abstract Base Class for Dashboard Features (Abstraction)
abstract class DashboardFeature {
  String get title;
  IconData get icon;
  Color get primaryColor;
  Color get secondaryColor;
  String get description;
  List<String> get subFeatures;

  Widget buildCard(BuildContext context);
  void onTap(BuildContext context);
}

// Interface for Navigation (Polymorphism)
mixin NavigationMixin {
  void navigateToPage(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }
}

// Model Class for Dashboard Items (Encapsulation)
class DashboardItemModel {
  final String _title;
  final IconData _icon;
  final Color _primaryColor;
  final Color _secondaryColor;
  final String _description;
  final List<String> _subFeatures;
  final VoidCallback _onTap;

  const DashboardItemModel({
    required String title,
    required IconData icon,
    required Color primaryColor,
    required Color secondaryColor,
    required String description,
    required List<String> subFeatures,
    required VoidCallback onTap,
  }) : _title = title,
       _icon = icon,
       _primaryColor = primaryColor,
       _secondaryColor = secondaryColor,
       _description = description,
       _subFeatures = subFeatures,
       _onTap = onTap;

  // Getters (Encapsulation)
  String get title => _title;
  IconData get icon => _icon;
  Color get primaryColor => _primaryColor;
  Color get secondaryColor => _secondaryColor;
  String get description => _description;
  List<String> get subFeatures => _subFeatures;
  VoidCallback get onTap => _onTap;
}

// Concrete Implementation - Doctor Consultation Feature (Inheritance)
class DoctorConsultationFeature extends DashboardFeature with NavigationMixin {
  @override
  String get title => "Doctor Consultation";

  @override
  IconData get icon => Icons.medical_services;

  @override
  Color get primaryColor => Colors.orange;

  @override
  Color get secondaryColor => Colors.orange.shade100;

  @override
  String get description => "Book appointments with specialists";

  @override
  List<String> get subFeatures => [
    "Book Appointment",
    "Video Consultation",
    "Specialties",
  ];

  @override
  Widget buildCard(BuildContext context) {
    return ModernDashboardCard(feature: this);
  }

  @override
  void onTap(BuildContext context) {
    navigateToPage(context, const DoctorConsultationPage());
  }
}

// Medical Records Feature (Inheritance)
// Order Medicines Feature
class OrderMedicinesFeature extends DashboardFeature with NavigationMixin {
  @override
  String get title => "Order Medicines";

  @override
  IconData get icon => Icons.medication;

  @override
  Color get primaryColor => Colors.green;

  @override
  Color get secondaryColor => Colors.green.shade100;

  @override
  String get description => "Order prescribed medicines";

  @override
  List<String> get subFeatures => [
    "View Prescriptions",
    "Order Medicines",
    "Track Orders",
  ];

  @override
  Widget buildCard(BuildContext context) {
    return ModernDashboardCard(feature: this);
  }

  @override
  void onTap(BuildContext context) {
    navigateToPage(context, const MedicineOrderingPage());
  }
}

// Appointments Feature
class AppointmentsFeature extends DashboardFeature with NavigationMixin {
  @override
  String get title => "My Appointments";

  @override
  IconData get icon => Icons.calendar_today;

  @override
  Color get primaryColor => Colors.purple;

  @override
  Color get secondaryColor => Colors.purple.shade100;

  @override
  String get description => "View upcoming appointments";

  @override
  List<String> get subFeatures => ["Upcoming", "Past", "Reschedule"];

  @override
  Widget buildCard(BuildContext context) {
    return ModernDashboardCard(feature: this);
  }

  @override
  void onTap(BuildContext context) {
    // Only navigate to appointment history page that fetches real data from Firestore
    navigateToPage(context, const AppointmentHistoryPageFixed());
  }
}

// Patient Information Feature (Inheritance)
class PatientInformationFeature extends DashboardFeature with NavigationMixin {
  @override
  String get title => "Patient Information";

  @override
  IconData get icon => Icons.person_outline;

  @override
  Color get primaryColor => Colors.indigo;

  @override
  Color get secondaryColor => Colors.indigo.shade100;

  @override
  String get description => "Complete patient profile and records";

  @override
  List<String> get subFeatures => [
    "Personal Info",
    "Emergency Contacts",
    "Insurance Details",
  ];

  @override
  Widget buildCard(BuildContext context) {
    return ModernDashboardCard(feature: this);
  }

  @override
  void onTap(BuildContext context) {
    navigateToPage(context, const PatientInformationPage());
  }
}

// Medical Records Feature (Inheritance)
class MedicalRecordsFeature extends DashboardFeature with NavigationMixin {
  @override
  String get title => "Medical Records";

  @override
  IconData get icon => Icons.description;

  @override
  Color get primaryColor => Colors.teal;

  @override
  Color get secondaryColor => Colors.teal.shade100;

  @override
  String get description => "View records prescribed by doctors";

  @override
  List<String> get subFeatures => [
    "Prescription History",
    "Lab Reports",
    "Doctor Notes",
    "Treatment Plans",
  ];

  @override
  Widget buildCard(BuildContext context) {
    return ModernDashboardCard(feature: this);
  }

  @override
  void onTap(BuildContext context) {
    navigateToPage(context, const MedicalReportsPage());
  }
}

// Modern Dashboard Card Widget (Composition)
class ModernDashboardCard extends StatefulWidget {
  final DashboardFeature feature;

  const ModernDashboardCard({Key? key, required this.feature})
    : super(key: key);

  @override
  State<ModernDashboardCard> createState() => _ModernDashboardCardState();
}

class _ModernDashboardCardState extends State<ModernDashboardCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => _animationController.forward(),
        onTapUp: (_) {
          _animationController.reverse();
          widget.feature.onTap(context);
        },
        onTapCancel: () => _animationController.reverse(),
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.feature.primaryColor.withOpacity(0.1),
                      widget.feature.secondaryColor.withOpacity(0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: widget.feature.primaryColor.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.feature.primaryColor.withOpacity(0.2),
                      blurRadius: _isHovered ? 15 : 8,
                      spreadRadius: _isHovered ? 3 : 1,
                      offset: Offset(0, _isHovered ? 8 : 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icon Container
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: widget.feature.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: widget.feature.primaryColor.withOpacity(0.3),
                          ),
                        ),
                        child: Icon(
                          widget.feature.icon,
                          size: 32,
                          color: widget.feature.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Title
                      Text(
                        widget.feature.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: widget.feature.primaryColor.withOpacity(0.9),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),

                      // Description
                      Text(
                        widget.feature.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Sub-features
                      Wrap(
                        children: widget.feature.subFeatures.take(2).map((
                          feature,
                        ) {
                          return Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 2,
                              vertical: 2,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: widget.feature.primaryColor.withOpacity(
                                0.1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              feature,
                              style: TextStyle(
                                fontSize: 10,
                                color: widget.feature.primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

// Health Stats Section - Shows basic health info from Firestore
class HealthStatsSection extends StatefulWidget {
  const HealthStatsSection({Key? key}) : super(key: key);

  @override
  State<HealthStatsSection> createState() => _HealthStatsSectionState();
}

class _HealthStatsSectionState extends State<HealthStatsSection> {
  Map<String, dynamic> healthInfo = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHealthData();
  }

  void _loadHealthData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists && mounted) {
          setState(() {
            healthInfo = doc.data()?['basicHealthInfo'] ?? {};
            isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    }
  }

  void _editIndividualStat(String label, String currentValue) {
    final controller = TextEditingController(
      text: currentValue == 'Not Set' ? '' : currentValue,
    );

    // Determine field type and validation
    String fieldKey = '';
    String hintText = '';
    TextInputType inputType = TextInputType.text;
    List<String>? dropdownOptions;

    switch (label) {
      case 'Blood Group':
        fieldKey = 'bloodGroup';
        hintText = 'Select your blood group';
        dropdownOptions = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
        break;
      case 'Weight':
        fieldKey = 'weight';
        hintText = 'e.g., 70 kg';
        inputType = TextInputType.text;
        break;
      case 'Height':
        fieldKey = 'height';
        hintText = 'e.g., 175 cm';
        inputType = TextInputType.text;
        break;
      default:
        return;
    }

    String? selectedValue =
        (dropdownOptions != null && dropdownOptions.contains(currentValue))
        ? currentValue
        : null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Edit $label'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dropdownOptions != null) ...[
                DropdownButtonFormField<String>(
                  value: selectedValue,
                  decoration: InputDecoration(
                    labelText: label,
                    hintText: hintText,
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(_getIconForField(fieldKey)),
                  ),
                  items: dropdownOptions.map((String option) {
                    return DropdownMenuItem<String>(
                      value: option,
                      child: Text(option),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setDialogState(() {
                      selectedValue = newValue;
                      controller.text = newValue ?? '';
                    });
                  },
                ),
              ] else ...[
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: label,
                    hintText: hintText,
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(_getIconForField(fieldKey)),
                  ),
                  keyboardType: inputType,
                ),
              ],
              const SizedBox(height: 16),
              if (fieldKey == 'weight' || fieldKey == 'height')
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, size: 16, color: Colors.blue.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          fieldKey == 'weight'
                              ? 'Include unit (e.g., kg, lbs)'
                              : 'Include unit (e.g., cm, ft)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade600,
                          ),
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
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                String newValue = controller.text.trim();

                if (dropdownOptions != null) {
                  newValue = selectedValue ?? '';
                }

                if (_validateInput(fieldKey, newValue)) {
                  await _updateHealthStat(fieldKey, newValue);
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForField(String fieldKey) {
    switch (fieldKey) {
      case 'bloodGroup':
        return Icons.bloodtype;
      case 'weight':
        return Icons.monitor_weight;
      case 'height':
        return Icons.height;
      default:
        return Icons.edit;
    }
  }

  bool _validateInput(String fieldKey, String value) {
    if (value.isEmpty) {
      _showErrorSnackBar('Please enter a value');
      return false;
    }

    switch (fieldKey) {
      case 'weight':
        if (!RegExp(
          r'^\d+(\.\d+)?\s*(kg|kgs?|lb|lbs?|pounds?)?$',
          caseSensitive: false,
        ).hasMatch(value)) {
          _showErrorSnackBar(
            'Please enter weight in valid format (e.g., 70 kg)',
          );
          return false;
        }
        break;
      case 'height':
        if (!RegExp(
          r'^\d+(\.\d+)?\s*(cm|cms?|ft|feet|in|inch|inches)?$',
          caseSensitive: false,
        ).hasMatch(value)) {
          _showErrorSnackBar(
            'Please enter height in valid format (e.g., 175 cm)',
          );
          return false;
        }
        break;
    }
    return true;
  }

  Future<void> _updateHealthStat(String fieldKey, String value) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Update local state first for immediate UI feedback
      setState(() {
        healthInfo[fieldKey] = value;
      });

      // Update in Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'basicHealthInfo.$fieldKey': value},
      );

      _showSuccessSnackBar('Health information updated successfully');
    } catch (e) {
      // Revert local state on error
      _loadHealthData();
      _showErrorSnackBar('Failed to update: $e');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _editHealthInfo() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfilePage()),
    ).then((_) => _loadHealthData()); // Refresh data when returning
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Health Quick Stats',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade700,
                ),
              ),
              IconButton(
                onPressed: _editHealthInfo,
                icon: Icon(Icons.edit, color: Colors.teal.shade600),
                tooltip: 'Edit Health Info',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.green.shade50, Colors.teal.shade50],
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Blood Group',
                      healthInfo['bloodGroup'] ?? 'Not Set',
                      Icons.bloodtype,
                      Colors.red,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Weight',
                      healthInfo['weight'] ?? 'Not Set',
                      Icons.monitor_weight,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Height',
                      healthInfo['height'] ?? 'Not Set',
                      Icons.height,
                      Colors.purple,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return GestureDetector(
      onTap: () => _editIndividualStat(label, value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Column(
          children: [
            Stack(
              children: [
                Icon(icon, color: color, size: 24),
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit, color: Colors.white, size: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: value == 'Not Set'
                    ? Colors.grey.shade400
                    : Colors.grey.shade800,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'Tap to edit',
              style: TextStyle(
                fontSize: 8,
                color: color.withOpacity(0.7),
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class UserProfileSection extends StatefulWidget {
  const UserProfileSection({Key? key}) : super(key: key);

  @override
  State<UserProfileSection> createState() => _UserProfileSectionState();
}

class _UserProfileSectionState extends State<UserProfileSection> {
  String userName = "Loading...";
  String userEmail = "";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists && mounted) {
          setState(() {
            userName = doc.data()?['name'] ?? 'User';
            userEmail = user.email ?? '';
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            userName = 'User';
            userEmail = user.email ?? '';
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.teal.shade300, Colors.blue.shade400],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.shade200,
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Profile Avatar
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.teal.shade100,
              child: Icon(Icons.person, size: 35, color: Colors.teal.shade700),
            ),
          ),
          const SizedBox(width: 16),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hello, $userName! 👋",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        offset: Offset(1, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Welcome to Healthcare Medical Centre",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (userEmail.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    userEmail,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Notification Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.notifications,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}

// Dashboard Screen (Main Class using Composition)
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // List of Dashboard Features (Polymorphism)
  late final List<DashboardFeature> _features = [
    DoctorConsultationFeature(),
    OrderMedicinesFeature(),
    AppointmentsFeature(),
    MedicalRecordsFeature(),
    // PatientInformationFeature removed
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // User Profile Section
            SliverToBoxAdapter(child: const UserProfileSection()),

            // Health Stats Section
            SliverToBoxAdapter(child: const HealthStatsSection()),

            // Quick Actions Section
            SliverToBoxAdapter(child: _buildQuickActionsSection()),

            // Main Features Grid
            SliverToBoxAdapter(child: _buildFeaturesSection()),

            // Health Tips Section
            SliverToBoxAdapter(child: _buildHealthTipsSection()),

            // Bottom Padding
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      iconTheme: IconThemeData(color: Colors.teal.shade700),
      title: ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          colors: [Colors.teal.shade600, Colors.blue.shade600],
        ).createShader(bounds),
        child: const Text(
          'Healthcare Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.search, color: Colors.teal.shade700),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Search feature coming soon!')),
            );
          },
        ),
        IconButton(
          icon: Icon(Icons.notifications_outlined, color: Colors.teal.shade700),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No new notifications')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal.shade300, Colors.blue.shade400],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 50),
            const CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 50, color: Colors.teal),
            ),
            const SizedBox(height: 16),
            const Text(
              'Patient Portal',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            _buildDrawerItem(Icons.home, 'Dashboard', () {
              Navigator.pop(context);
            }),
            _buildDrawerItem(Icons.person, 'Profile', () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage()),
              );
            }),
            _buildDrawerItem(Icons.settings, 'Settings', () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            }),
            _buildDrawerItem(Icons.help, 'Help & Support', () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HelpSupportPage(),
                ),
              );
            }),
            const Spacer(),
            _buildDrawerItem(Icons.logout, 'Logout', () {
              _showLogoutDialog();
            }),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildQuickActionsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.teal.shade700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  'Emergency Call',
                  Icons.emergency,
                  Colors.red,
                  () => _showEmergencyDialog(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  'Health Tips',
                  Icons.favorite,
                  Colors.green,
                  () => _showHealthTipsDialog(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Healthcare Services',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.teal.shade700,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.85,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _features.length,
            itemBuilder: (context, index) {
              return _features[index].buildCard(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHealthTipsSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade100, Colors.blue.shade100],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.green.shade600),
              const SizedBox(width: 8),
              Text(
                'Daily Health Tip',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '💧 Remember to drink at least 8 glasses of water daily to stay hydrated and maintain good health.',
            style: TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const DoctorConsultationPage(),
          ),
        );
      },
      backgroundColor: Colors.teal,
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text(
        'Quick Book',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showLogoutDialog() {
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
              Navigator.pop(context);
              await AuthService().logout();
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/login', (route) => false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEmergencyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emergency Call'),
        content: const Text(
          'In a real emergency, this would call 118 immediately.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Call 118',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showHealthTipsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.favorite, color: Colors.green),
            SizedBox(width: 8),
            Text('Daily Health Tips'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHealthTip(
                '💧',
                'Stay Hydrated',
                'Drink at least 8 glasses of water daily',
              ),
              SizedBox(height: 12),
              _buildHealthTip(
                '🏃‍♂️',
                'Exercise Regularly',
                '30 minutes of daily activity keeps you healthy',
              ),
              SizedBox(height: 12),
              _buildHealthTip(
                '😴',
                'Get Quality Sleep',
                '7-9 hours of sleep improves your immune system',
              ),
              SizedBox(height: 12),
              _buildHealthTip(
                '🥗',
                'Eat Balanced Diet',
                'Include fruits, vegetables, and whole grains',
              ),
              SizedBox(height: 12),
              _buildHealthTip(
                '🧘‍♀️',
                'Manage Stress',
                'Practice meditation or deep breathing exercises',
              ),
              SizedBox(height: 12),
              _buildHealthTip(
                '📅',
                'Regular Checkups',
                'Schedule routine health screenings',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Could navigate to a dedicated health tips page
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Bookmark these tips for daily reminders!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text(
              'Save Tips',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthTip(String emoji, String title, String description) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Text(emoji, style: TextStyle(fontSize: 24)),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(color: Colors.green.shade700, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }
}

// Only real user data from Firebase is shown. No example/sample data logic remains.
