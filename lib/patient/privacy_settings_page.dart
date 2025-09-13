import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PrivacySettingsPage extends StatefulWidget {
  const PrivacySettingsPage({super.key});

  @override
  State<PrivacySettingsPage> createState() => _PrivacySettingsPageState();
}

class _PrivacySettingsPageState extends State<PrivacySettingsPage> {
  // Privacy Settings State
  bool _shareDataWithPartners = false;
  bool _allowResearchParticipation = false;
  bool _shareAnonymousStatistics = true;
  bool _enableLocationTracking = false;
  bool _allowMarketingCommunication = false;
  bool _profileVisibilityPublic = false;
  bool _showOnlineStatus = true;
  bool _allowDataAnalytics = true;
  bool _enableCookies = true;
  bool _shareWithInsurance = false;

  // Data Retention Settings
  String _dataRetentionPeriod = '5 years';
  bool _autoDeleteInactiveData = true;
  bool _keepMedicalHistoryIndefinitely = true;

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  void _loadPrivacySettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('settings')
            .doc('privacy')
            .get();

        if (doc.exists) {
          final data = doc.data()!;
          setState(() {
            _shareDataWithPartners = data['shareDataWithPartners'] ?? false;
            _allowResearchParticipation =
                data['allowResearchParticipation'] ?? false;
            _shareAnonymousStatistics =
                data['shareAnonymousStatistics'] ?? true;
            _enableLocationTracking = data['enableLocationTracking'] ?? false;
            _allowMarketingCommunication =
                data['allowMarketingCommunication'] ?? false;
            _profileVisibilityPublic = data['profileVisibilityPublic'] ?? false;
            _showOnlineStatus = data['showOnlineStatus'] ?? true;
            _allowDataAnalytics = data['allowDataAnalytics'] ?? true;
            _enableCookies = data['enableCookies'] ?? true;
            _shareWithInsurance = data['shareWithInsurance'] ?? false;
            _dataRetentionPeriod = data['dataRetentionPeriod'] ?? '5 years';
            _autoDeleteInactiveData = data['autoDeleteInactiveData'] ?? true;
            _keepMedicalHistoryIndefinitely =
                data['keepMedicalHistoryIndefinitely'] ?? true;
          });
        }
      } catch (e) {
        print('Error loading privacy settings: $e');
      }
    }
  }

  void _savePrivacySettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('settings')
            .doc('privacy')
            .set({
              'shareDataWithPartners': _shareDataWithPartners,
              'allowResearchParticipation': _allowResearchParticipation,
              'shareAnonymousStatistics': _shareAnonymousStatistics,
              'enableLocationTracking': _enableLocationTracking,
              'allowMarketingCommunication': _allowMarketingCommunication,
              'profileVisibilityPublic': _profileVisibilityPublic,
              'showOnlineStatus': _showOnlineStatus,
              'allowDataAnalytics': _allowDataAnalytics,
              'enableCookies': _enableCookies,
              'shareWithInsurance': _shareWithInsurance,
              'dataRetentionPeriod': _dataRetentionPeriod,
              'autoDeleteInactiveData': _autoDeleteInactiveData,
              'keepMedicalHistoryIndefinitely': _keepMedicalHistoryIndefinitely,
              'lastUpdated': FieldValue.serverTimestamp(),
            });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Privacy settings saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Settings'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _savePrivacySettings,
            tooltip: 'Save Privacy Settings',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade50, Colors.blue.shade100],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.security, size: 32, color: Colors.blue.shade600),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Privacy Matters',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Control how your data is used and shared',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Data Sharing Section
            _buildSectionHeader('Data Sharing & Usage', Icons.share),
            _buildPrivacyToggle(
              'Share data with healthcare partners',
              'Allow sharing with trusted medical institutions',
              _shareDataWithPartners,
              (value) => setState(() => _shareDataWithPartners = value),
              Colors.blue,
            ),
            _buildPrivacyToggle(
              'Participate in medical research',
              'Help advance healthcare through anonymized data',
              _allowResearchParticipation,
              (value) => setState(() => _allowResearchParticipation = value),
              Colors.green,
            ),
            _buildPrivacyToggle(
              'Share anonymous statistics',
              'Help improve app functionality',
              _shareAnonymousStatistics,
              (value) => setState(() => _shareAnonymousStatistics = value),
              Colors.purple,
            ),
            _buildPrivacyToggle(
              'Share with insurance providers',
              'Allow insurance companies access to relevant data',
              _shareWithInsurance,
              (value) => setState(() => _shareWithInsurance = value),
              Colors.orange,
            ),

            const SizedBox(height: 24),

            // Profile Visibility Section
            _buildSectionHeader('Profile & Visibility', Icons.visibility),
            _buildPrivacyToggle(
              'Public profile visibility',
              'Make your profile visible to other users',
              _profileVisibilityPublic,
              (value) => setState(() => _profileVisibilityPublic = value),
              Colors.indigo,
            ),
            _buildPrivacyToggle(
              'Show online status',
              'Let others see when you\'re online',
              _showOnlineStatus,
              (value) => setState(() => _showOnlineStatus = value),
              Colors.teal,
            ),

            const SizedBox(height: 24),

            // Tracking & Analytics Section
            _buildSectionHeader('Tracking & Analytics', Icons.analytics),
            _buildPrivacyToggle(
              'Enable location tracking',
              'Allow location-based features and services',
              _enableLocationTracking,
              (value) => setState(() => _enableLocationTracking = value),
              Colors.red,
            ),
            _buildPrivacyToggle(
              'Allow data analytics',
              'Help us understand app usage patterns',
              _allowDataAnalytics,
              (value) => setState(() => _allowDataAnalytics = value),
              Colors.blue,
            ),
            _buildPrivacyToggle(
              'Enable cookies and tracking',
              'Improve your browsing experience',
              _enableCookies,
              (value) => setState(() => _enableCookies = value),
              Colors.brown,
            ),

            const SizedBox(height: 24),

            // Communications Section
            _buildSectionHeader('Communications', Icons.email),
            _buildPrivacyToggle(
              'Marketing communications',
              'Receive promotional emails and updates',
              _allowMarketingCommunication,
              (value) => setState(() => _allowMarketingCommunication = value),
              Colors.pink,
            ),

            const SizedBox(height: 24),

            // Data Retention Section
            _buildSectionHeader('Data Retention', Icons.schedule),
            _buildDataRetentionSettings(),

            const SizedBox(height: 24),

            // Action Buttons
            _buildActionButtons(),

            const SizedBox(height: 24),

            // Privacy Information
            _buildPrivacyInformation(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue.shade600, size: 24),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyToggle(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
    Color accentColor,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Semantics(
        label: '$title. $subtitle. Currently ${value ? 'enabled' : 'disabled'}',
        child: SwitchListTile(
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          value: value,
          onChanged: onChanged,
          activeColor: accentColor,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
        ),
      ),
    );
  }

  Widget _buildDataRetentionSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Data Retention Period',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _dataRetentionPeriod,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: const [
                DropdownMenuItem(value: '1 year', child: Text('1 year')),
                DropdownMenuItem(value: '3 years', child: Text('3 years')),
                DropdownMenuItem(value: '5 years', child: Text('5 years')),
                DropdownMenuItem(value: '10 years', child: Text('10 years')),
                DropdownMenuItem(
                  value: 'indefinitely',
                  child: Text('Indefinitely'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _dataRetentionPeriod = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            SwitchListTile(
              title: const Text('Auto-delete inactive data'),
              subtitle: const Text('Remove data after retention period'),
              value: _autoDeleteInactiveData,
              onChanged: (value) =>
                  setState(() => _autoDeleteInactiveData = value),
              contentPadding: EdgeInsets.zero,
            ),

            SwitchListTile(
              title: const Text('Keep medical history indefinitely'),
              subtitle: const Text('Medical records are never auto-deleted'),
              value: _keepMedicalHistoryIndefinitely,
              onChanged: (value) =>
                  setState(() => _keepMedicalHistoryIndefinitely = value),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _savePrivacySettings,
            icon: const Icon(Icons.save),
            label: const Text('Save All Settings'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _resetToDefaults,
                icon: const Icon(Icons.restore),
                label: const Text('Reset to Defaults'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _exportPrivacySettings,
                icon: const Icon(Icons.download),
                label: const Text('Export Settings'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPrivacyInformation() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                const Text(
                  'Privacy Information',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Your privacy is important to us. These settings control how your data is used and shared. You can change these settings at any time.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _showPrivacyPolicy,
              child: const Text('Read our full Privacy Policy'),
            ),
          ],
        ),
      ),
    );
  }

  void _resetToDefaults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Privacy Settings'),
        content: const Text(
          'This will reset all privacy settings to their default values. Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _shareDataWithPartners = false;
                _allowResearchParticipation = false;
                _shareAnonymousStatistics = true;
                _enableLocationTracking = false;
                _allowMarketingCommunication = false;
                _profileVisibilityPublic = false;
                _showOnlineStatus = true;
                _allowDataAnalytics = true;
                _enableCookies = true;
                _shareWithInsurance = false;
                _dataRetentionPeriod = '5 years';
                _autoDeleteInactiveData = true;
                _keepMedicalHistoryIndefinitely = true;
              });
              _savePrivacySettings();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _exportPrivacySettings() {
    final settings = {
      'shareDataWithPartners': _shareDataWithPartners,
      'allowResearchParticipation': _allowResearchParticipation,
      'shareAnonymousStatistics': _shareAnonymousStatistics,
      'enableLocationTracking': _enableLocationTracking,
      'allowMarketingCommunication': _allowMarketingCommunication,
      'profileVisibilityPublic': _profileVisibilityPublic,
      'showOnlineStatus': _showOnlineStatus,
      'allowDataAnalytics': _allowDataAnalytics,
      'enableCookies': _enableCookies,
      'shareWithInsurance': _shareWithInsurance,
      'dataRetentionPeriod': _dataRetentionPeriod,
      'autoDeleteInactiveData': _autoDeleteInactiveData,
      'keepMedicalHistoryIndefinitely': _keepMedicalHistoryIndefinitely,
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Settings Export'),
        content: SingleChildScrollView(
          child: Text(
            settings.entries.map((e) => '${e.key}: ${e.value}').join('\n'),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Privacy settings exported successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'Our Privacy Policy explains how we collect, use, and protect your personal information.\n\n'
            'Key Points:\n'
            '• We only collect necessary medical information\n'
            '• Your data is encrypted and stored securely\n'
            '• You have control over data sharing preferences\n'
            '• Medical information is never shared without consent\n'
            '• You can request data deletion at any time\n\n'
            'For the complete policy, visit our website or contact support.',
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
}
