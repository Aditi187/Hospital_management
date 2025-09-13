import 'services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'doctor_consultation_page.dart';
import 'appointment_history_page_fixed.dart';
import 'medical_reports_page.dart';
import 'patient_information_page.dart';
import 'profile_page.dart';
import 'settings_page.dart';
import 'help_support_page.dart';

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
class MedicalRecordsFeature extends DashboardFeature with NavigationMixin {
  @override
  String get title => "Medical Records";

  @override
  IconData get icon => Icons.folder_special;

  @override
  Color get primaryColor => Colors.blue;

  @override
  Color get secondaryColor => Colors.blue.shade100;

  @override
  String get description => "View your health records";

  @override
  List<String> get subFeatures => ["Lab Reports", "Prescriptions", "History"];

  @override
  Widget buildCard(BuildContext context) {
    return ModernDashboardCard(feature: this);
  }

  @override
  void onTap(BuildContext context) {
    navigateToPage(context, const MedicalReportsPage());
  }
}

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
    "Prescription Upload",
    "Find Hospital",
    "Quick Order",
  ];

  @override
  Widget buildCard(BuildContext context) {
    return ModernDashboardCard(feature: this);
  }

  @override
  void onTap(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Medicine ordering feature coming soon!'),
        backgroundColor: primaryColor,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
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
    "Medical History",
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

// User Profile Widget (Composition)
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
    MedicalRecordsFeature(),
    OrderMedicinesFeature(),
    AppointmentsFeature(),
    PatientInformationFeature(),
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
                MaterialPageRoute(builder: (context) => const ProfilePage()),
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
                  'Health Profile',
                  Icons.favorite,
                  Colors.pink,
                  () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Health profile feature coming soon!'),
                    ),
                  ),
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
          'In a real emergency, this would call 911 immediately.',
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

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }
}

// Only real user data from Firebase is shown. No example/sample data logic remains.
