import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- Theme Colors ---
class AppTheme {
  // ✅ Modern hospital-friendly colors
  static const Color primary = Color(0xFF1976D2);       // Deep Blue
  static const Color primaryLight = Color(0xFFE3F2FD);  // Light Sky Blue
  static const Color primaryDark = Color(0xFF1565C0);   // Darker Blue
  static const Color success = Color(0xFF28A745);       // Green
  static const Color error = Color(0xFFDC3545);         // Red
  static const Color muted = Color(0xFF6E7582);         // Neutral Gray

  // Gradient button
  static const List<Color> buttonGradient = [primaryLight, primary];

  // ======= Animated Button =======
  static Widget animatedButton({required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: buttonGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(2, 2))],
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  // ======= Animated Card =======
  static Widget animatedCard({required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.95, end: 1.0),
      duration: const Duration(milliseconds: 300),
      builder: (context, scale, childWidget) {
        return Transform.scale(scale: scale, child: childWidget);
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: primaryLight,
        child: child,
      ),
    );
  }
}

// ===== Abstract Component =====
abstract class PatientInformationComponent {
  String get title;
  IconData get icon;
  Color get color;
  Widget buildContent(BuildContext context, Map<String, dynamic> data);
}

// ===== Patient Demographics =====
class PatientDemographics extends PatientInformationComponent {
  @override
  String get title => 'Personal Information';
  @override
  IconData get icon => Icons.person;
  @override
  Color get color => AppTheme.primary;

  @override
  Widget buildContent(BuildContext context, Map<String, dynamic> data) {
    final user = FirebaseAuth.instance.currentUser;
    return Column(
      children: [
        _buildRow(context, user, 'Full Name', 'fullName', data['fullName'] ?? 'Not provided'),
        _buildRow(context, user, 'DOB', 'dateOfBirth', data['dateOfBirth'] ?? 'Not provided'),
        _buildRow(context, user, 'Gender', 'gender', data['gender'] ?? 'Not provided'),
        _buildRow(context, user, 'Blood Type', 'bloodType', data['bloodType'] ?? 'Not provided'),
        _buildRow(context, user, 'Phone', 'phoneNumber', data['phoneNumber'] ?? 'Not provided'),
        _buildRow(context, user, 'Email', 'email', data['email'] ?? 'Not provided'),
        _buildRow(context, user, 'Address', 'address', data['address'] ?? 'Not provided'),
      ],
    );
  }

  Widget _buildRow(BuildContext context, User? user, String label, String field, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.muted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w500, color: AppTheme.primaryDark),
            ),
          ),
          if (user != null)
            IconButton(
              icon: Icon(Icons.edit, size: 20, color: AppTheme.primary),
              onPressed: () => _editDialog(context, user, label, field, value),
            ),
        ],
      ),
    );
  }

  void _editDialog(BuildContext context, User user, String label, String field, String value) {
    final controller = TextEditingController(text: value);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $label'),
        content: TextField(controller: controller, decoration: InputDecoration(labelText: label)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          AppTheme.animatedButton(
            label: 'Save',
            onTap: () async {
              final newValue = controller.text.trim();
              if (newValue.isEmpty) return;
              await FirebaseFirestore.instance.collection('patient_information').doc(user.uid).update({field: newValue});
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$label updated!'), backgroundColor: AppTheme.success),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ===== Emergency Contacts =====
class EmergencyContacts extends PatientInformationComponent {
  @override
  String get title => 'Emergency Contacts';
  @override
  IconData get icon => Icons.emergency;
  @override
  Color get color => AppTheme.error;

  @override
  Widget buildContent(BuildContext context, Map<String, dynamic> data) {
    List<dynamic> contacts = data['emergencyContacts'] ?? [];
    if (contacts.isEmpty)
      return Center(
        child: Text('No emergency contacts', style: TextStyle(color: AppTheme.muted, fontStyle: FontStyle.italic)),
      );

    return Column(
      children: contacts.map((c) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AppTheme.animatedCard(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c['name'] ?? 'Unknown', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.error)),
                  Text('Relationship: ${c['relationship'] ?? 'N/A'}', style: TextStyle(color: AppTheme.error.withOpacity(0.8))),
                  Text('Phone: ${c['phone'] ?? 'N/A'}', style: TextStyle(color: AppTheme.error.withOpacity(0.8))),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ===== Insurance Information =====
class InsuranceInformation extends PatientInformationComponent {
  @override
  String get title => 'Insurance Info';
  @override
  IconData get icon => Icons.shield;
  @override
  Color get color => AppTheme.success;

  @override
  Widget buildContent(BuildContext context, Map<String, dynamic> data) {
    Map<String, dynamic> insurance = data['insurance'] ?? {};
    if (insurance.isEmpty)
      return Center(
        child: Text('No insurance info', style: TextStyle(color: AppTheme.muted)),
      );

    return AppTheme.animatedCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _row('Provider', insurance['provider']),
            _row('Policy', insurance['policyNumber']),
            _row('Group', insurance['groupNumber']),
            _row('Effective', insurance['effectiveDate']),
            _row('Expiry', insurance['expiryDate']),
            _row('Coverage', insurance['coverageType']),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text('$label:', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.success.withOpacity(0.8)))),
          Expanded(child: Text(value ?? 'N/A', style: TextStyle(fontWeight: FontWeight.w500, color: AppTheme.success))),
        ],
      ),
    );
  }
}

// ===== Medical History =====
class MedicalHistorySummary extends PatientInformationComponent {
  @override
  String get title => 'Medical History';
  @override
  IconData get icon => Icons.history;
  @override
  Color get color => AppTheme.primaryDark;

  @override
  Widget buildContent(BuildContext context, Map<String, dynamic> data) {
    Map<String, dynamic> history = data['medicalHistory'] ?? {};
    return Column(
      children: [
        _section('Chronic Conditions', history['chronicConditions'] ?? [], AppTheme.primary),
        _section('Previous Surgeries', history['surgeries'] ?? [], AppTheme.primaryDark),
        _section('Family History', history['familyHistory'] ?? [], AppTheme.success),
        _section('Medications', history['currentMedications'] ?? [], AppTheme.error),
      ],
    );
  }

  Widget _section(String title, List<dynamic> items, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppTheme.animatedCard(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
              if (items.isEmpty)
                Text('No records', style: TextStyle(color: AppTheme.muted, fontStyle: FontStyle.italic))
              else
                ...items.map((i) => Text('• $i', style: TextStyle(color: color.withOpacity(0.8)))),
            ],
          ),
        ),
      ),
    );
  }
}

// ===== Main Page =====
class PatientInformationPage extends StatefulWidget {
  const PatientInformationPage({super.key});
  @override
  State<PatientInformationPage> createState() => _PatientInformationPageState();
}

class _PatientInformationPageState extends State<PatientInformationPage> with TickerProviderStateMixin {
  late TabController _tabController;
  final List<PatientInformationComponent> _components = [
    PatientDemographics(),
    EmergencyContacts(),
    InsuranceInformation(),
    MedicalHistorySummary(),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _components.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const Scaffold(body: Center(child: Text('Please log in')));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Information', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primary,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: _components.map((c) => Tab(icon: Icon(c.icon), text: c.title)).toList(),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('patient_information').doc(currentUser.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          Map<String, dynamic> data = {};
          if (snapshot.hasData && snapshot.data!.exists) data = snapshot.data!.data() as Map<String, dynamic>;
          return TabBarView(
            controller: _tabController,
            children: _components.map((c) => SingleChildScrollView(padding: const EdgeInsets.all(16), child: c.buildContent(context, data))).toList(),
          );
        },
      ),
    );
  }
}
