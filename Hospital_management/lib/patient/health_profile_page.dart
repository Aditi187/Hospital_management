import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Abstract Base Class for Health Data (Abstraction)
abstract class HealthData {
  String get id;
  DateTime get timestamp;
  String get category;
  Map<String, dynamic> toJson();
  void fromJson(Map<String, dynamic> json);
  Widget buildDisplayWidget(BuildContext context);
}

// Interface for Health Metrics (Polymorphism)
mixin HealthMetricsMixin {
  double get normalMin;
  double get normalMax;
  bool isNormal(double value) => value >= normalMin && value <= normalMax;
  Color getStatusColor(double value) {
    if (isNormal(value)) return Colors.green;
    if (value < normalMin) return Colors.blue;
    return Colors.red;
  }
}

// Enum for Health Categories (Encapsulation)
enum HealthCategory {
  vitals('Vital Signs'),
  medical('Medical History'),
  allergies('Allergies'),
  medications('Medications'),
  lifestyle('Lifestyle');

  const HealthCategory(this.displayName);
  final String displayName;
}

// Model Class for Vital Signs (Inheritance)
class VitalSigns extends HealthData with HealthMetricsMixin {
  final String _id;
  final DateTime _timestamp;
  final double _bloodPressureSystolic;
  final double _bloodPressureDiastolic;
  final double _heartRate;
  final double _temperature;
  final double _weight;
  final double _height;

  VitalSigns({
    required String id,
    required DateTime timestamp,
    required double bloodPressureSystolic,
    required double bloodPressureDiastolic,
    required double heartRate,
    required double temperature,
    required double weight,
    required double height,
  }) : _id = id,
       _timestamp = timestamp,
       _bloodPressureSystolic = bloodPressureSystolic,
       _bloodPressureDiastolic = bloodPressureDiastolic,
       _heartRate = heartRate,
       _temperature = temperature,
       _weight = weight,
       _height = height;

  // Getters (Encapsulation)
  @override
  String get id => _id;

  @override
  DateTime get timestamp => _timestamp;

  @override
  String get category => HealthCategory.vitals.displayName;

  double get bloodPressureSystolic => _bloodPressureSystolic;
  double get bloodPressureDiastolic => _bloodPressureDiastolic;
  double get heartRate => _heartRate;
  double get temperature => _temperature;
  double get weight => _weight;
  double get height => _height;

  // BMI Calculation (Method)
  double get bmi => _weight / ((_height / 100) * (_height / 100));

  // Health Metrics Implementation
  @override
  double get normalMin => 60; // For heart rate

  @override
  double get normalMax => 100;

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': _id,
      'timestamp': _timestamp.toIso8601String(),
      'bloodPressureSystolic': _bloodPressureSystolic,
      'bloodPressureDiastolic': _bloodPressureDiastolic,
      'heartRate': _heartRate,
      'temperature': _temperature,
      'weight': _weight,
      'height': _height,
    };
  }

  @override
  void fromJson(Map<String, dynamic> json) {
    // Implementation for deserialization
  }

  @override
  Widget buildDisplayWidget(BuildContext context) {
    return VitalSignsCard(vitalSigns: this);
  }
}

// Model Class for Medical History (Inheritance)
class MedicalHistory extends HealthData {
  final String _id;
  final DateTime _timestamp;
  final String _condition;
  final String _diagnosis;
  final String _treatment;
  final String _doctor;
  final bool _isOngoing;

  MedicalHistory({
    required String id,
    required DateTime timestamp,
    required String condition,
    required String diagnosis,
    required String treatment,
    required String doctor,
    required bool isOngoing,
  }) : _id = id,
       _timestamp = timestamp,
       _condition = condition,
       _diagnosis = diagnosis,
       _treatment = treatment,
       _doctor = doctor,
       _isOngoing = isOngoing;

  // Getters
  @override
  String get id => _id;

  @override
  DateTime get timestamp => _timestamp;

  @override
  String get category => HealthCategory.medical.displayName;

  String get condition => _condition;
  String get diagnosis => _diagnosis;
  String get treatment => _treatment;
  String get doctor => _doctor;
  bool get isOngoing => _isOngoing;

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': _id,
      'timestamp': _timestamp.toIso8601String(),
      'condition': _condition,
      'diagnosis': _diagnosis,
      'treatment': _treatment,
      'doctor': _doctor,
      'isOngoing': _isOngoing,
    };
  }

  @override
  void fromJson(Map<String, dynamic> json) {
    // Implementation for deserialization
  }

  @override
  Widget buildDisplayWidget(BuildContext context) {
    return MedicalHistoryCard(medicalHistory: this);
  }
}

// Factory Pattern for Health Data Creation
class HealthDataFactory {
  static HealthData createHealthData(String type, Map<String, dynamic> data) {
    switch (type) {
      case 'vitals':
        return VitalSigns(
          id: data['id'],
          timestamp: DateTime.parse(data['timestamp']),
          bloodPressureSystolic: data['bloodPressureSystolic'].toDouble(),
          bloodPressureDiastolic: data['bloodPressureDiastolic'].toDouble(),
          heartRate: data['heartRate'].toDouble(),
          temperature: data['temperature'].toDouble(),
          weight: data['weight'].toDouble(),
          height: data['height'].toDouble(),
        );
      case 'medical':
        return MedicalHistory(
          id: data['id'],
          timestamp: DateTime.parse(data['timestamp']),
          condition: data['condition'],
          diagnosis: data['diagnosis'],
          treatment: data['treatment'],
          doctor: data['doctor'],
          isOngoing: data['isOngoing'],
        );
      default:
        throw ArgumentError('Unknown health data type: $type');
    }
  }
}

// Repository Pattern for Data Management (Dependency Injection)
abstract class HealthProfileRepository {
  Future<List<HealthData>> getHealthData();
  Future<void> saveHealthData(HealthData data);
  Future<void> updateHealthData(HealthData data);
  Future<void> deleteHealthData(String id);
}

class FirebaseHealthProfileRepository implements HealthProfileRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Future<List<HealthData>> getHealthData() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final snapshot = await _firestore
        .collection('health_profiles')
        .doc(user.uid)
        .collection('health_data')
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return HealthDataFactory.createHealthData(data['type'], data);
    }).toList();
  }

  @override
  Future<void> saveHealthData(HealthData data) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _firestore
        .collection('health_profiles')
        .doc(user.uid)
        .collection('health_data')
        .doc(data.id)
        .set(data.toJson());
  }

  @override
  Future<void> updateHealthData(HealthData data) async {
    await saveHealthData(data); // Same implementation for simplicity
  }

  @override
  Future<void> deleteHealthData(String id) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _firestore
        .collection('health_profiles')
        .doc(user.uid)
        .collection('health_data')
        .doc(id)
        .delete();
  }
}

// Business Logic Layer (Service Pattern)
class HealthProfileService {
  final HealthProfileRepository _repository;

  HealthProfileService(this._repository);

  Future<List<HealthData>> getHealthProfile() async {
    return await _repository.getHealthData();
  }

  Future<void> addVitalSigns({
    required double systolic,
    required double diastolic,
    required double heartRate,
    required double temperature,
    required double weight,
    required double height,
  }) async {
    final vitalSigns = VitalSigns(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      bloodPressureSystolic: systolic,
      bloodPressureDiastolic: diastolic,
      heartRate: heartRate,
      temperature: temperature,
      weight: weight,
      height: height,
    );

    await _repository.saveHealthData(vitalSigns);
  }

  Future<void> addMedicalHistory({
    required String condition,
    required String diagnosis,
    required String treatment,
    required String doctor,
    required bool isOngoing,
  }) async {
    final medicalHistory = MedicalHistory(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      condition: condition,
      diagnosis: diagnosis,
      treatment: treatment,
      doctor: doctor,
      isOngoing: isOngoing,
    );

    await _repository.saveHealthData(medicalHistory);
  }

  // Health Analytics (Business Logic)
  Map<String, dynamic> analyzeHealthTrends(List<VitalSigns> vitalsList) {
    if (vitalsList.isEmpty) return {};

    final avgHeartRate =
        vitalsList.map((v) => v.heartRate).reduce((a, b) => a + b) /
        vitalsList.length;

    final avgBMI =
        vitalsList.map((v) => v.bmi).reduce((a, b) => a + b) /
        vitalsList.length;

    return {
      'averageHeartRate': avgHeartRate,
      'averageBMI': avgBMI,
      'healthStatus': _getHealthStatus(avgHeartRate, avgBMI),
      'recommendations': _getRecommendations(avgHeartRate, avgBMI),
    };
  }

  String _getHealthStatus(double avgHeartRate, double avgBMI) {
    if (avgHeartRate >= 60 &&
        avgHeartRate <= 100 &&
        avgBMI >= 18.5 &&
        avgBMI <= 24.9) {
      return 'Excellent';
    } else if (avgHeartRate >= 50 &&
        avgHeartRate <= 110 &&
        avgBMI >= 17 &&
        avgBMI <= 27) {
      return 'Good';
    } else {
      return 'Needs Attention';
    }
  }

  List<String> _getRecommendations(double avgHeartRate, double avgBMI) {
    List<String> recommendations = [];

    if (avgHeartRate > 100) {
      recommendations.add(
        'Consider cardiovascular exercise to improve heart health',
      );
    }
    if (avgBMI > 24.9) {
      recommendations.add('Consider a balanced diet and regular exercise');
    }
    if (avgHeartRate < 60) {
      recommendations.add('Consult a doctor about your heart rate');
    }

    return recommendations;
  }
}

// UI Components using Composition

// Vital Signs Card Widget
class VitalSignsCard extends StatelessWidget {
  final VitalSigns vitalSigns;

  const VitalSignsCard({Key? key, required this.vitalSigns}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.pink.shade50, Colors.red.shade50],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.favorite, color: Colors.pink.shade600),
                const SizedBox(width: 8),
                Text(
                  'Vital Signs',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.pink.shade700,
                  ),
                ),
                const Spacer(),
                Text(
                  '${vitalSigns.timestamp.day}/${vitalSigns.timestamp.month}/${vitalSigns.timestamp.year}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildVitalRow(
              'Blood Pressure',
              '${vitalSigns.bloodPressureSystolic.toInt()}/${vitalSigns.bloodPressureDiastolic.toInt()} mmHg',
              Icons.monitor_heart,
            ),
            _buildVitalRow(
              'Heart Rate',
              '${vitalSigns.heartRate.toInt()} bpm',
              Icons.favorite,
              color: vitalSigns.getStatusColor(vitalSigns.heartRate),
            ),
            _buildVitalRow(
              'Temperature',
              '${vitalSigns.temperature.toStringAsFixed(1)}°C',
              Icons.thermostat,
            ),
            _buildVitalRow(
              'BMI',
              vitalSigns.bmi.toStringAsFixed(1),
              Icons.accessibility,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalRow(
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? Colors.pink.shade600),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

// Medical History Card Widget
class MedicalHistoryCard extends StatelessWidget {
  final MedicalHistory medicalHistory;

  const MedicalHistoryCard({Key? key, required this.medicalHistory})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.indigo.shade50],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.medical_information, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                Text(
                  'Medical History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: medicalHistory.isOngoing
                        ? Colors.orange.shade100
                        : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    medicalHistory.isOngoing ? 'Ongoing' : 'Resolved',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: medicalHistory.isOngoing
                          ? Colors.orange.shade700
                          : Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Condition', medicalHistory.condition),
            _buildInfoRow('Diagnosis', medicalHistory.diagnosis),
            _buildInfoRow('Treatment', medicalHistory.treatment),
            _buildInfoRow('Doctor', medicalHistory.doctor),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade700,
            ),
          ),
          Text(value, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// Main Health Profile Page (Presentation Layer)
class HealthProfilePage extends StatefulWidget {
  const HealthProfilePage({Key? key}) : super(key: key);

  @override
  State<HealthProfilePage> createState() => _HealthProfilePageState();
}

class _HealthProfilePageState extends State<HealthProfilePage>
    with SingleTickerProviderStateMixin {
  late HealthProfileService _healthService;
  late TabController _tabController;
  List<HealthData> _healthData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _healthService = HealthProfileService(FirebaseHealthProfileRepository());
    _tabController = TabController(length: 3, vsync: this);
    _loadHealthData();
  }

  Future<void> _loadHealthData() async {
    try {
      final data = await _healthService.getHealthProfile();
      if (mounted) {
        setState(() {
          _healthData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading health data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Health Profile'),
        backgroundColor: Colors.pink.shade600,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Vitals', icon: Icon(Icons.favorite)),
            Tab(text: 'History', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildVitalsTab(),
                _buildHistoryTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDataDialog,
        backgroundColor: Colors.pink.shade600,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildOverviewTab() {
    final vitals = _healthData.whereType<VitalSigns>().toList();
    final analysis = _healthService.analyzeHealthTrends(vitals);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Health Summary Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [Colors.pink.shade300, Colors.purple.shade300],
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Health Summary',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (analysis.isNotEmpty) ...[
                    _buildSummaryRow(
                      'Health Status',
                      analysis['healthStatus'] ?? 'Unknown',
                    ),
                    _buildSummaryRow(
                      'Avg Heart Rate',
                      '${(analysis['averageHeartRate'] ?? 0).toStringAsFixed(0)} bpm',
                    ),
                    _buildSummaryRow(
                      'Avg BMI',
                      (analysis['averageBMI'] ?? 0).toStringAsFixed(1),
                    ),
                  ] else
                    const Text(
                      'No health data available yet',
                      style: TextStyle(color: Colors.white70),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Quick Stats
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Records',
                  _healthData.length.toString(),
                  Icons.assessment,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Vitals Recorded',
                  vitals.length.toString(),
                  Icons.favorite,
                  Colors.red,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Recommendations
          if (analysis['recommendations'] != null &&
              (analysis['recommendations'] as List).isNotEmpty) ...[
            const Text(
              'Health Recommendations',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...((analysis['recommendations'] as List<String>).map(
              (rec) => Card(
                child: ListTile(
                  leading: const Icon(Icons.lightbulb, color: Colors.amber),
                  title: Text(rec),
                ),
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildVitalsTab() {
    final vitals = _healthData.whereType<VitalSigns>().toList();

    if (vitals.isEmpty) {
      return const Center(child: Text('No vital signs recorded yet'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: vitals.length,
      itemBuilder: (context, index) {
        return vitals[index].buildDisplayWidget(context);
      },
    );
  }

  Widget _buildHistoryTab() {
    final history = _healthData.whereType<MedicalHistory>().toList();

    if (history.isEmpty) {
      return const Center(child: Text('No medical history recorded yet'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: history.length,
      itemBuilder: (context, index) {
        return history[index].buildDisplayWidget(context);
      },
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.2)],
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDataDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AddHealthDataSheet(
        onDataAdded: () {
          _loadHealthData();
          Navigator.pop(context);
        },
        healthService: _healthService,
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

// Add Health Data Bottom Sheet
class AddHealthDataSheet extends StatefulWidget {
  final VoidCallback onDataAdded;
  final HealthProfileService healthService;

  const AddHealthDataSheet({
    Key? key,
    required this.onDataAdded,
    required this.healthService,
  }) : super(key: key);

  @override
  State<AddHealthDataSheet> createState() => _AddHealthDataSheetState();
}

class _AddHealthDataSheetState extends State<AddHealthDataSheet> {
  int _selectedTab = 0;
  final _formKey = GlobalKey<FormState>();

  // Vital Signs Controllers
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _heartRateController = TextEditingController();
  final _temperatureController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();

  // Medical History Controllers
  final _conditionController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _treatmentController = TextEditingController();
  final _doctorController = TextEditingController();
  bool _isOngoing = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text(
            'Add Health Data',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Tab Selector
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTab = 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _selectedTab == 0
                          ? Colors.pink.shade600
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Vital Signs',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _selectedTab == 0 ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTab = 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _selectedTab == 1
                          ? Colors.pink.shade600
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Medical History',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _selectedTab == 1 ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Form Content
          Expanded(
            child: Form(
              key: _formKey,
              child: _selectedTab == 0
                  ? _buildVitalsForm()
                  : _buildMedicalHistoryForm(),
            ),
          ),

          // Submit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink.shade600,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Save Data',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsForm() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _systolicController,
                  decoration: const InputDecoration(
                    labelText: 'Systolic BP',
                    suffixText: 'mmHg',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _diastolicController,
                  decoration: const InputDecoration(
                    labelText: 'Diastolic BP',
                    suffixText: 'mmHg',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _heartRateController,
            decoration: const InputDecoration(
              labelText: 'Heart Rate',
              suffixText: 'bpm',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _temperatureController,
            decoration: const InputDecoration(
              labelText: 'Temperature',
              suffixText: '°C',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _weightController,
                  decoration: const InputDecoration(
                    labelText: 'Weight',
                    suffixText: 'kg',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _heightController,
                  decoration: const InputDecoration(
                    labelText: 'Height',
                    suffixText: 'cm',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalHistoryForm() {
    return SingleChildScrollView(
      child: Column(
        children: [
          TextFormField(
            controller: _conditionController,
            decoration: const InputDecoration(
              labelText: 'Medical Condition',
              border: OutlineInputBorder(),
            ),
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _diagnosisController,
            decoration: const InputDecoration(
              labelText: 'Diagnosis',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _treatmentController,
            decoration: const InputDecoration(
              labelText: 'Treatment',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _doctorController,
            decoration: const InputDecoration(
              labelText: 'Doctor/Hospital',
              border: OutlineInputBorder(),
            ),
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            title: const Text('Ongoing Treatment'),
            value: _isOngoing,
            onChanged: (value) => setState(() => _isOngoing = value ?? false),
            activeColor: Colors.pink.shade600,
          ),
        ],
      ),
    );
  }

  void _submitData() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      if (_selectedTab == 0) {
        await widget.healthService.addVitalSigns(
          systolic: double.parse(_systolicController.text),
          diastolic: double.parse(_diastolicController.text),
          heartRate: double.parse(_heartRateController.text),
          temperature: double.parse(_temperatureController.text),
          weight: double.parse(_weightController.text),
          height: double.parse(_heightController.text),
        );
      } else {
        await widget.healthService.addMedicalHistory(
          condition: _conditionController.text,
          diagnosis: _diagnosisController.text,
          treatment: _treatmentController.text,
          doctor: _doctorController.text,
          isOngoing: _isOngoing,
        );
      }

      widget.onDataAdded();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Health data saved successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving data: $e')));
    }
  }

  @override
  void dispose() {
    _systolicController.dispose();
    _diastolicController.dispose();
    _heartRateController.dispose();
    _temperatureController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _conditionController.dispose();
    _diagnosisController.dispose();
    _treatmentController.dispose();
    _doctorController.dispose();
    super.dispose();
  }
}
