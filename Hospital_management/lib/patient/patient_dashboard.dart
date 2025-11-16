import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hospital_management/theme.dart';
import '../login_page.dart';
import 'medical_reports_page.dart';
import 'appointment_history_page.dart';
import 'chatbot_widget.dart';
import '../config.dart';
import '../doctor_consultation_page.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/draggable_fab.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  final User? currentUser = FirebaseAuth.instance.currentUser;
  bool _isChatOpen = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryLight,
      appBar: AppBar(
        title: const Text(
          'Patient Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: AppTheme.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: Stack(
        children: [
          currentUser == null
              ? const Center(child: CircularProgressIndicator())
              : StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(currentUser!.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    Map<String, dynamic> userData =
                        snapshot.data!.data() as Map<String, dynamic>? ?? {};

                    return FadeTransition(
                      opacity: _fadeController,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Welcome Section
                            _buildWelcomeSection(userData),
                            const SizedBox(height: 12),
                            // Tip of the Day (creative, low-risk feature)
                            _buildTipOfTheDay(userData),
                            const SizedBox(height: 16),

                            // Patient information (phone, DOB, gender, address, weight, height)
                            _buildPatientInfoSection(userData),
                            const SizedBox(height: 24),

                            // Exercise Tips removed by request

                            // Recent Prescriptions Section
                            _buildRecentPrescriptionsSection(currentUser!.uid),
                            const SizedBox(height: 24),

                            // Healthcare Services (only key actions kept)
                            _buildQuickActionsSection(),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          // Floating chat overlay + draggable FAB
          if (_isChatOpen)
            Positioned(
              right: 16,
              bottom: 90,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = MediaQuery.of(context).size.width;
                  final panelWidth = width > 420 ? 380.0 : width - 32.0;
                  final panelHeight = MediaQuery.of(context).size.height * 0.5;
                  return Material(
                    elevation: 12,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: panelWidth,
                      height: panelHeight,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Assistant',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                  ),
                                  onPressed: () =>
                                      setState(() => _isChatOpen = false),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ChatWidget(
                              openAiApiKey: openAiApiKey,
                              onRequestOpenAppointments: () {
                                // close overlay and open appointments
                                setState(() => _isChatOpen = false);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const AppointmentHistoryPage(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

          DraggableFab(
            child: const Icon(Icons.chat, color: Colors.white),
            onPressed: () => setState(() => _isChatOpen = !_isChatOpen),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(Map<String, dynamic> userData) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryVariant],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: 3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.surface.withOpacity(0.3),
                      AppTheme.surface.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: AppTheme.surface.withOpacity(0.4),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.surface.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: AppTheme.surface.withOpacity(0.05),
                  child: Icon(
                    Icons.waving_hand,
                    size: 32,
                    color: AppTheme.onPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Hi ',
                          style: TextStyle(
                            color: AppTheme.onPrimary.withOpacity(0.95),
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${userData['name'] ?? 'There'}!',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Patient ID Display Box
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surface.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.surface.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.badge,
                            size: 16,
                            color: AppTheme.onPrimary.withOpacity(0.9),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Patient ID: ${userData['personalId'] ?? 'N/A'}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.onPrimary.withOpacity(0.95),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surface.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.surface.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.email_outlined,
                            color: AppTheme.onPrimary.withOpacity(0.9),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            userData['email'] ?? 'No email',
                            style: TextStyle(
                              color: AppTheme.onPrimary.withOpacity(0.9),
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
        ],
      ),
    );
  }

  Widget _buildPatientInfoSection(Map<String, dynamic> userData) {
    final phone = userData['phone'] ?? 'Not set';
    final dob = userData['dateOfBirth'] ?? 'Not set';
    final gender = userData['gender'] ?? 'Not set';
    final address = userData['address'] ?? 'Not set';
    final bloodGroup = userData['bloodGroup'] ?? 'Not set';

    // Handle weight and height with proper formatting
    final weight = userData['weight'];
    final height = userData['height'];

    String weightDisplay =
        (weight != null && weight.toString().isNotEmpty && weight != '')
        ? '$weight kg'
        : 'Not set';
    String heightDisplay =
        (height != null && height.toString().isNotEmpty && height != '')
        ? '$height cm'
        : 'Not set';

    Widget infoRow(String label, String value, {IconData? icon}) {
      return Row(
        children: [
          if (icon != null) Icon(icon, size: 18, color: AppTheme.muted),
          if (icon != null) const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: value == 'Not set'
                        ? Colors.orange
                        : Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.muted.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: AppTheme.muted.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.info_outline, color: AppTheme.primary),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Patient Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                tooltip: 'Edit patient information',
                onPressed: () => _editPatientInfo(userData),
                icon: Icon(Icons.edit, color: AppTheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          infoRow('Phone', phone.toString(), icon: Icons.phone),
          const SizedBox(height: 8),
          infoRow('Date of Birth', dob.toString(), icon: Icons.cake),
          const SizedBox(height: 8),
          infoRow('Gender', gender.toString(), icon: Icons.person),
          const SizedBox(height: 8),
          infoRow('Blood Group', bloodGroup.toString(), icon: Icons.bloodtype),
          const SizedBox(height: 8),
          infoRow('Address', address.toString(), icon: Icons.location_on),
          const SizedBox(height: 8),
          infoRow('Weight', weightDisplay, icon: Icons.monitor_weight),
          const SizedBox(height: 8),
          infoRow('Height', heightDisplay, icon: Icons.height),
        ],
      ),
    );
  }

  Widget _buildRecentPrescriptionsSection(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('prescriptions')
          .where('personalId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final prescriptions = snapshot.data!.docs;
        prescriptions.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTs = aData['prescribedDate'] as Timestamp?;
          final bTs = bData['prescribedDate'] as Timestamp?;
          if (aTs == null) return 1;
          if (bTs == null) return -1;
          return bTs.compareTo(aTs);
        });
        final recentPrescriptions = prescriptions.take(3);

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryLight, Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 5),
                spreadRadius: 1,
              ),
            ],
            border: Border.all(
              color: AppTheme.primary.withOpacity(0.08),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primaryVariant, AppTheme.primary],
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.medication,
                      color: AppTheme.onPrimary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Recent Prescriptions',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...recentPrescriptions.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.muted.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.medication,
                          color: AppTheme.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['medicineName'] ?? 'Medicine',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Dr. ${data['doctorName'] ?? 'Unknown'}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.primary, width: 1),
                        ),
                        child: Text(
                          data['status'] ?? 'Pending',
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
              Center(
                child: TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MedicalReportsPage(),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('View All Prescriptions'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActionsSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryLight, AppTheme.surface],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.muted.withOpacity(0.18),
            blurRadius: 15,
            offset: const Offset(0, 5),
            spreadRadius: 1,
          ),
        ],
        border: Border.all(color: AppTheme.muted.withOpacity(0.06), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryVariant, AppTheme.primary],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.medical_services,
                  color: AppTheme.onPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Healthcare Services',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.1,
            children: [
              _buildActionCard(
                'Doctor Consultation',
                Icons.book_online,
                AppTheme.primaryVariant,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DoctorConsultationPage(),
                  ),
                ),
              ),
              _buildActionCard(
                'Medical Records',
                Icons.medical_information,
                AppTheme.primaryVariant,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MedicalReportsPage(),
                  ),
                ),
              ),
              _buildActionCard(
                'Appointments',
                Icons.calendar_today,
                AppTheme.primaryVariant,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AppointmentHistoryPage(),
                  ),
                ),
              ),
              _buildActionCard(
                'Health Tips',
                Icons.health_and_safety,
                AppTheme.primaryVariant,
                _showHealthTips,
              ),
              // Chatbot is accessible via the floating draggable FAB; removed
              // from quick actions to avoid duplicate entry.
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return DashboardCard(title: title, icon: icon, color: color, onTap: onTap);
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.blue.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 35, color: Colors.blue),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Patient Portal',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  currentUser?.email ?? 'Patient',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            icon: Icons.dashboard,
            title: 'Dashboard',
            onTap: () => Navigator.pop(context),
          ),
          _buildDrawerItem(
            icon: Icons.video_call,
            title: 'Doctor Consultation',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DoctorConsultationPage(),
                ),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.medical_information,
            title: 'Medical Records',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MedicalReportsPage(),
                ),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.calendar_today,
            title: 'Appointments',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AppointmentHistoryPage(),
                ),
              );
            },
          ),
          const Divider(),
          _buildDrawerItem(
            icon: Icons.logout,
            title: 'Logout',
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue.shade600),
      title: Text(title),
      onTap: onTap,
      hoverColor: Colors.blue.shade50,
    );
  }

  void _showHealthTips() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.health_and_safety, color: Colors.green),
            SizedBox(width: 8),
            Text('Health Tips'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Daily Health Tips',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    _buildHealthTip(
                      Icons.water_drop,
                      'Stay Hydrated',
                      'Drink at least 8 glasses of water daily to maintain proper hydration.',
                      Colors.blue,
                    ),
                    _buildHealthTip(
                      Icons.directions_walk,
                      'Regular Exercise',
                      'Aim for 30 minutes of moderate exercise 5 days a week.',
                      Colors.orange,
                    ),
                    // Insert exercise tips (general guidance) into Health Tips
                    _buildHealthTip(
                      Icons.fitness_center,
                      'Exercise Tips',
                      'Warm up 5–10 minutes before activity and cool down afterwards.\n'
                          'Aim for at least 150 minutes/week of moderate aerobic activity (e.g., brisk walking) and include strength training 2×/week.\n'
                          'Start slowly, progress duration before intensity, and split sessions into shorter bouts if needed.\n'
                          'Stop and seek medical advice for chest pain, severe breathlessness, dizziness, or fainting.\n'
                          'If you have a chronic condition (diabetes, hypertension, heart disease, COPD, arthritis, osteoporosis, back pain, asthma, depression, obesity), consult your clinician for personalised exercise recommendations.',
                      Colors.indigo,
                    ),
                    _buildHealthTip(
                      Icons.restaurant,
                      'Balanced Diet',
                      'Include fruits, vegetables, and whole grains in your daily meals.',
                      Colors.green,
                    ),
                    _buildHealthTip(
                      Icons.bedtime,
                      'Quality Sleep',
                      'Get 7-9 hours of quality sleep each night for better health.',
                      Colors.purple,
                    ),
                    _buildHealthTip(
                      Icons.self_improvement,
                      'Mental Health',
                      'Practice mindfulness and stress management techniques daily.',
                      Colors.teal,
                    ),
                  ],
                ),
              ),
            ],
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

  void _editPatientInfo(Map<String, dynamic> userData) {
    final phoneController = TextEditingController(
      text: userData['phone'] ?? '',
    );
    final dobController = TextEditingController(
      text: userData['dateOfBirth'] ?? '',
    );
    final addressController = TextEditingController(
      text: userData['address'] ?? '',
    );
    final weightController = TextEditingController(
      text: userData['weight']?.toString() ?? '',
    );
    final heightController = TextEditingController(
      text: userData['height']?.toString() ?? '',
    );
    String selectedGender = userData['gender'] ?? 'Male';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Patient Information'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dobController,
                decoration: const InputDecoration(
                  labelText: 'Date of Birth (DD/MM/YYYY)',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedGender,
                decoration: const InputDecoration(labelText: 'Gender'),
                items: ['Male', 'Female', 'Other']
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) => selectedGender = v ?? selectedGender,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: weightController,
                decoration: const InputDecoration(labelText: 'Weight (kg)'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: heightController,
                decoration: const InputDecoration(labelText: 'Height (cm)'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Address'),
                maxLines: 2,
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

              // Parse weight and height properly
              String weightValue = weightController.text.trim();
              String heightValue = heightController.text.trim();

              final updates = {
                'phone': phoneController.text.trim(),
                'dateOfBirth': dobController.text.trim(),
                'gender': selectedGender,
                'weight': weightValue.isNotEmpty ? weightValue : null,
                'height': heightValue.isNotEmpty ? heightValue : null,
                'address': addressController.text.trim(),
                'updatedAt': FieldValue.serverTimestamp(),
              };

              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .set(updates, SetOptions(merge: true));

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Patient information updated successfully'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update: $e')),
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

  Widget _buildHealthTip(
    IconData icon,
    String title,
    String description,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withOpacity(0.2),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: color,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipOfTheDay(Map<String, dynamic> userData) {
    final tips = [
      {
        'title': '2-minute Breathing Break',
        'desc':
            'Try 2 minutes of box breathing: inhale 4s, hold 4s, exhale 4s, hold 4s. Repeat 4 times to reduce stress.',
      },
      {
        'title': 'Desk Stretch',
        'desc':
            'Stand up and do a gentle neck and shoulder roll. Stretch arms overhead for 30 seconds to ease tension.',
      },
      {
        'title': 'Hydration Nudge',
        'desc':
            'Have a glass of water now — small hydration boosts focus and digestion.',
      },
      {
        'title': 'Posture Check',
        'desc':
            'Sit tall with feet flat, shoulders relaxed. Set a 25-minute timer and re-check your posture afterwards.',
      },
      {
        'title': 'Mini Walk',
        'desc':
            'Take a 5-minute walk around your room or building to increase circulation and clear your mind.',
      },
    ];

    // Pick a deterministic index so the tip is stable during a session
    final name = (userData['name'] ?? '') as String;
    final idx =
        (name.isNotEmpty
            ? name.codeUnits.reduce((a, b) => a + b)
            : DateTime.now().day) %
        tips.length;
    final tip = tips[idx];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppTheme.muted.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: AppTheme.muted.withOpacity(0.04)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.lightbulb, color: AppTheme.primary, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tip['title']!,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  tip['desc']!,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(tip['title']!),
                content: Text(tip['desc']!),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
            child: const Text('Learn more'),
          ),
        ],
      ),
    );
  }
}
