import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // User settings state
  Map<String, dynamic> userSettings = {
    'twoFactorAuth': false,
    'dataSharing': true,
    'locationServices': false,
    'analytics': true,
    'appointmentReminders': true,
    'medicationReminders': true,
    'healthTips': false,
    'emergencyAlerts': true,
    'theme': 'auto',
    'language': 'english',
    'fontSize': 'medium',
  };

  @override
  void initState() {
    super.initState();
    _loadUserSettings();
  }

  Future<void> _loadUserSettings() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final doc = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('settings')
            .doc('preferences')
            .get();

        if (doc.exists) {
          setState(() {
            userSettings.addAll(doc.data() ?? {});
          });
        }
      } catch (e) {
        print('Error loading settings: $e');
      }
    }
  }

  Future<void> _saveUserSettings() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('settings')
            .doc('preferences')
            .set(userSettings, SetOptions(merge: true));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving settings: $e')));
      }
    }
  }

  void _updateSetting(String key, dynamic value) {
    setState(() {
      userSettings[key] = value;
    });
    _saveUserSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildAccountSettings(),
          const SizedBox(height: 20),
          _buildPrivacySecuritySettings(),
          const SizedBox(height: 20),
          _buildNotificationSettings(),
          const SizedBox(height: 20),
          _buildAppPreferences(),
        ],
      ),
    );
  }

  Widget _buildAccountSettings() {
    return _buildSection(
      'Account Settings',
      Icons.account_circle,
      Colors.blue,
      [
        _buildSettingItem(
          'Change Password',
          'Update your account password',
          Icons.lock,
          onTap: _showChangePasswordDialog,
        ),
        _buildSettingItem(
          'Two-Factor Authentication',
          'Add extra security to your account',
          Icons.security,
          trailing: Switch(
            value: userSettings['twoFactorAuth'] ?? false,
            onChanged: (value) => _updateSetting('twoFactorAuth', value),
          ),
        ),
        _buildSettingItem(
          'Email Preferences',
          'Manage email notifications',
          Icons.email,
          onTap: _showEmailPreferencesDialog,
        ),
        _buildSettingItem(
          'Delete Account',
          'Permanently delete your account',
          Icons.delete_forever,
          onTap: _showDeleteAccountDialog,
        ),
      ],
    );
  }

  Widget _buildPrivacySecuritySettings() {
    return _buildSection('Privacy & Security', Icons.privacy_tip, Colors.red, [
      _buildSettingItem(
        'Data Sharing',
        'Control how your data is shared',
        Icons.share,
        trailing: Switch(
          value: userSettings['dataSharing'] ?? true,
          onChanged: (value) => _updateSetting('dataSharing', value),
        ),
      ),
      _buildSettingItem(
        'Medical Data Privacy',
        'Manage medical information privacy',
        Icons.medical_services,
        onTap: _showMedicalPrivacyDialog,
      ),
      _buildSettingItem(
        'Location Services',
        'Control location access',
        Icons.location_on,
        trailing: Switch(
          value: userSettings['locationServices'] ?? false,
          onChanged: (value) => _updateSetting('locationServices', value),
        ),
      ),
      _buildSettingItem(
        'Analytics & Usage',
        'Help improve the app',
        Icons.analytics,
        trailing: Switch(
          value: userSettings['analytics'] ?? true,
          onChanged: (value) => _updateSetting('analytics', value),
        ),
      ),
    ]);
  }

  Widget _buildNotificationSettings() {
    return _buildSection('Notifications', Icons.notifications, Colors.orange, [
      _buildSettingItem(
        'Appointment Reminders',
        'Get notified about upcoming appointments',
        Icons.calendar_today,
        trailing: Switch(
          value: userSettings['appointmentReminders'] ?? true,
          onChanged: (value) => _updateSetting('appointmentReminders', value),
        ),
      ),
      _buildSettingItem(
        'Medication Reminders',
        'Never miss your medications',
        Icons.medication,
        trailing: Switch(
          value: userSettings['medicationReminders'] ?? true,
          onChanged: (value) => _updateSetting('medicationReminders', value),
        ),
      ),
      _buildSettingItem(
        'Health Tips',
        'Receive daily health tips',
        Icons.tips_and_updates,
        trailing: Switch(
          value: userSettings['healthTips'] ?? false,
          onChanged: (value) => _updateSetting('healthTips', value),
        ),
      ),
      _buildSettingItem(
        'Emergency Alerts',
        'Critical health alerts',
        Icons.emergency,
        trailing: Switch(
          value: userSettings['emergencyAlerts'] ?? true,
          onChanged: (value) => _updateSetting('emergencyAlerts', value),
        ),
      ),
    ]);
  }

  Widget _buildAppPreferences() {
    return _buildSection('App Preferences', Icons.settings, Colors.green, [
      _buildSettingItem(
        'Theme',
        'Choose app appearance',
        Icons.palette,
        trailing: Text(
          userSettings['theme']?.toString().capitalize() ?? 'Auto',
          style: TextStyle(color: Colors.grey[600]),
        ),
        onTap: _showThemeSelectionDialog,
      ),
      _buildSettingItem(
        'Language',
        'Change app language',
        Icons.language,
        trailing: Text(
          userSettings['language']?.toString().capitalize() ?? 'English',
          style: TextStyle(color: Colors.grey[600]),
        ),
        onTap: _showLanguageSelectionDialog,
      ),
      _buildSettingItem(
        'Font Size',
        'Adjust text size',
        Icons.format_size,
        trailing: Text(
          userSettings['fontSize']?.toString().capitalize() ?? 'Medium',
          style: TextStyle(color: Colors.grey[600]),
        ),
        onTap: _showFontSizeDialog,
      ),
      _buildSettingItem(
        'Accessibility',
        'Accessibility options',
        Icons.accessibility,
        onTap: _showAccessibilityDialog,
      ),
    ]);
  }

  Widget _buildSection(
    String title,
    IconData icon,
    Color color,
    List<Widget> items,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          ...items,
        ],
      ),
    );
  }

  Widget _buildSettingItem(
    String title,
    String subtitle,
    IconData icon, {
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: trailing,
      onTap: onTap,
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text('Change Password'),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter your current password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter a new password';
                  }
                  if (value!.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (value) {
                  if (value != newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
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
              if (formKey.currentState!.validate()) {
                try {
                  final user = _auth.currentUser;
                  if (user != null) {
                    final credential = EmailAuthProvider.credential(
                      email: user.email!,
                      password: currentPasswordController.text,
                    );
                    await user.reauthenticateWithCredential(credential);
                    await user.updatePassword(newPasswordController.text);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password updated successfully'),
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showEmailPreferencesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Email Preferences'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Configure your email notification preferences:'),
            SizedBox(height: 16),
            Text('• Appointment confirmations'),
            Text('• Medication reminders'),
            Text('• Health tips and updates'),
            Text('• Security alerts'),
          ],
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

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Account'),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final user = _auth.currentUser;
                if (user != null) {
                  await _firestore.collection('users').doc(user.uid).delete();
                  await user.delete();
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${e.toString()}')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showMedicalPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Medical Data Privacy'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your medical data is protected by:'),
            SizedBox(height: 12),
            Text('• End-to-end encryption'),
            Text('• HIPAA compliance'),
            Text('• Secure data transmission'),
            Text('• Limited access controls'),
            SizedBox(height: 12),
            Text('You can control who has access to your medical information.'),
          ],
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

  void _showThemeSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Auto (System)'),
              value: 'auto',
              groupValue: userSettings['theme'],
              onChanged: (value) {
                _updateSetting('theme', value);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Light'),
              value: 'light',
              groupValue: userSettings['theme'],
              onChanged: (value) {
                _updateSetting('theme', value);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Dark'),
              value: 'dark',
              groupValue: userSettings['theme'],
              onChanged: (value) {
                _updateSetting('theme', value);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('English'),
              value: 'english',
              groupValue: userSettings['language'],
              onChanged: (value) {
                _updateSetting('language', value);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Spanish'),
              value: 'spanish',
              groupValue: userSettings['language'],
              onChanged: (value) {
                _updateSetting('language', value);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('French'),
              value: 'french',
              groupValue: userSettings['language'],
              onChanged: (value) {
                _updateSetting('language', value);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFontSizeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Font Size'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Small'),
              value: 'small',
              groupValue: userSettings['fontSize'],
              onChanged: (value) {
                _updateSetting('fontSize', value);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Medium'),
              value: 'medium',
              groupValue: userSettings['fontSize'],
              onChanged: (value) {
                _updateSetting('fontSize', value);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Large'),
              value: 'large',
              groupValue: userSettings['fontSize'],
              onChanged: (value) {
                _updateSetting('fontSize', value);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAccessibilityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accessibility Options'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Available accessibility features:'),
            SizedBox(height: 12),
            Text('• High contrast mode'),
            Text('• Large text support'),
            Text('• Voice commands'),
            Text('• Screen reader support'),
            SizedBox(height: 12),
            Text(
              'These features help make the app more accessible for users with disabilities.',
            ),
          ],
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

extension StringCapitalization on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}
