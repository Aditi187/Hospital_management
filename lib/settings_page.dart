import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Abstract base class for settings categories (Abstraction)
abstract class SettingsCategory {
  String get title;
  IconData get icon;
  Color get color;
  List<SettingsItem> get items;
}

// Settings item model (Encapsulation)
class SettingsItem {
  final String _title;
  final String _subtitle;
  final IconData _icon;
  final VoidCallback _onTap;
  final Widget? _trailing;

  const SettingsItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Widget? trailing,
  }) : _title = title,
       _subtitle = subtitle,
       _icon = icon,
       _onTap = onTap,
       _trailing = trailing;

  String get title => _title;
  String get subtitle => _subtitle;
  IconData get icon => _icon;
  VoidCallback get onTap => _onTap;
  Widget? get trailing => _trailing;
}

// Interface for settings actions (Polymorphism)
mixin SettingsActionMixin {
  void showConfirmationDialog(
    BuildContext context,
    String title,
    String message,
    VoidCallback onConfirm,
  );
  void updateSettings(BuildContext context, Map<String, dynamic> settings);
}

// Account Settings Category (Inheritance)
class AccountSettingsCategory extends SettingsCategory {
  @override
  String get title => 'Account Settings';

  @override
  IconData get icon => Icons.account_circle;

  @override
  Color get color => Colors.blue;

  @override
  List<SettingsItem> get items => [
    SettingsItem(
      title: 'Change Password',
      subtitle: 'Update your account password',
      icon: Icons.lock,
      onTap: () => _changePassword(),
    ),
    SettingsItem(
      title: 'Two-Factor Authentication',
      subtitle: 'Add extra security to your account',
      icon: Icons.security,
      onTap: () => _setupTwoFactor(),
      trailing: Switch(
        value: false,
        onChanged: (value) => _toggleTwoFactor(value),
      ),
    ),
    SettingsItem(
      title: 'Email Preferences',
      subtitle: 'Manage email notifications',
      icon: Icons.email,
      onTap: () => _emailPreferences(),
    ),
    SettingsItem(
      title: 'Delete Account',
      subtitle: 'Permanently delete your account',
      icon: Icons.delete_forever,
      onTap: () => _deleteAccount(),
    ),
  ];

  void _changePassword() {
    // Implementation for password change
  }

  void _setupTwoFactor() {
    // Implementation for 2FA setup
  }

  void _toggleTwoFactor(bool value) {
    // Implementation for 2FA toggle
  }

  void _emailPreferences() {
    // Implementation for email preferences
  }

  void _deleteAccount() {
    // Implementation for account deletion
  }
}

// Privacy Settings Category (Inheritance)
class PrivacySettingsCategory extends SettingsCategory {
  @override
  String get title => 'Privacy & Security';

  @override
  IconData get icon => Icons.privacy_tip;

  @override
  Color get color => Colors.red;

  @override
  List<SettingsItem> get items => [
    SettingsItem(
      title: 'Data Sharing',
      subtitle: 'Control how your data is shared',
      icon: Icons.share,
      onTap: () => _dataSharing(),
      trailing: Switch(
        value: true,
        onChanged: (value) => _toggleDataSharing(value),
      ),
    ),
    SettingsItem(
      title: 'Medical Data Privacy',
      subtitle: 'Manage medical information privacy',
      icon: Icons.medical_services,
      onTap: () => _medicalPrivacy(),
    ),
    SettingsItem(
      title: 'Location Services',
      subtitle: 'Control location access',
      icon: Icons.location_on,
      onTap: () => _locationServices(),
      trailing: Switch(
        value: false,
        onChanged: (value) => _toggleLocation(value),
      ),
    ),
    SettingsItem(
      title: 'Analytics & Usage',
      subtitle: 'Help improve the app',
      icon: Icons.analytics,
      onTap: () => _analyticsSettings(),
      trailing: Switch(
        value: true,
        onChanged: (value) => _toggleAnalytics(value),
      ),
    ),
  ];

  void _dataSharing() {}
  void _toggleDataSharing(bool value) {}
  void _medicalPrivacy() {}
  void _locationServices() {}
  void _toggleLocation(bool value) {}
  void _analyticsSettings() {}
  void _toggleAnalytics(bool value) {}
}

// Notification Settings Category (Inheritance)
class NotificationSettingsCategory extends SettingsCategory {
  @override
  String get title => 'Notifications';

  @override
  IconData get icon => Icons.notifications;

  @override
  Color get color => Colors.orange;

  @override
  List<SettingsItem> get items => [
    SettingsItem(
      title: 'Appointment Reminders',
      subtitle: 'Get notified about upcoming appointments',
      icon: Icons.calendar_today,
      onTap: () => _appointmentReminders(),
      trailing: Switch(
        value: true,
        onChanged: (value) => _toggleAppointmentReminders(value),
      ),
    ),
    SettingsItem(
      title: 'Medication Reminders',
      subtitle: 'Never miss your medications',
      icon: Icons.medication,
      onTap: () => _medicationReminders(),
      trailing: Switch(
        value: true,
        onChanged: (value) => _toggleMedicationReminders(value),
      ),
    ),
    SettingsItem(
      title: 'Health Tips',
      subtitle: 'Receive daily health tips',
      icon: Icons.tips_and_updates,
      onTap: () => _healthTips(),
      trailing: Switch(
        value: false,
        onChanged: (value) => _toggleHealthTips(value),
      ),
    ),
    SettingsItem(
      title: 'Emergency Alerts',
      subtitle: 'Critical health alerts',
      icon: Icons.emergency,
      onTap: () => _emergencyAlerts(),
      trailing: Switch(
        value: true,
        onChanged: (value) => _toggleEmergencyAlerts(value),
      ),
    ),
  ];

  void _appointmentReminders() {}
  void _toggleAppointmentReminders(bool value) {}
  void _medicationReminders() {}
  void _toggleMedicationReminders(bool value) {}
  void _healthTips() {}
  void _toggleHealthTips(bool value) {}
  void _emergencyAlerts() {}
  void _toggleEmergencyAlerts(bool value) {}
}

// App Preferences Category (Inheritance)
class AppPreferencesCategory extends SettingsCategory {
  @override
  String get title => 'App Preferences';

  @override
  IconData get icon => Icons.settings;

  @override
  Color get color => Colors.green;

  @override
  List<SettingsItem> get items => [
    SettingsItem(
      title: 'Theme',
      subtitle: 'Choose app appearance',
      icon: Icons.palette,
      onTap: () => _themeSettings(),
      trailing: const Text('Auto'),
    ),
    SettingsItem(
      title: 'Language',
      subtitle: 'Change app language',
      icon: Icons.language,
      onTap: () => _languageSettings(),
      trailing: const Text('English'),
    ),
    SettingsItem(
      title: 'Font Size',
      subtitle: 'Adjust text size',
      icon: Icons.format_size,
      onTap: () => _fontSettings(),
      trailing: const Text('Medium'),
    ),
    SettingsItem(
      title: 'Accessibility',
      subtitle: 'Accessibility options',
      icon: Icons.accessibility,
      onTap: () => _accessibilitySettings(),
    ),
  ];

  void _themeSettings() {}
  void _languageSettings() {}
  void _fontSettings() {}
  void _accessibilitySettings() {}
}

// Main Settings Page using Composition
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with TickerProviderStateMixin, SettingsActionMixin {
  late List<SettingsCategory> _categories;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeCategories();
    _initializeAnimations();
  }

  void _initializeCategories() {
    _categories = [
      AccountSettingsCategory(),
      PrivacySettingsCategory(),
      NotificationSettingsCategory(),
      AppPreferencesCategory(),
    ];
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.green.shade600,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () => _showSearchSettings(context),
            tooltip: 'Search Settings',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Settings Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade600, Colors.green.shade800],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  Icon(Icons.settings, size: 50, color: Colors.white),
                  const SizedBox(height: 12),
                  const Text(
                    'Customize Your Experience',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'Manage your preferences and privacy',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),

            // Settings Categories
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  return _buildSettingsCategory(category, index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCategory(SettingsCategory category, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Header
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(category.icon, color: category.color, size: 24),
                const SizedBox(width: 12),
                Text(
                  category.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: category.color,
                  ),
                ),
              ],
            ),
          ),

          // Category Items
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: category.items.asMap().entries.map((entry) {
                final itemIndex = entry.key;
                final item = entry.value;
                final isLast = itemIndex == category.items.length - 1;

                return Container(
                  decoration: BoxDecoration(
                    border: !isLast
                        ? Border(
                            bottom: BorderSide(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                          )
                        : null,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: category.color.withOpacity(0.1),
                      child: Icon(item.icon, color: category.color, size: 20),
                    ),
                    title: Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      item.subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    trailing:
                        item.trailing ??
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey.shade400,
                        ),
                    onTap: item.onTap,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _showSearchSettings(BuildContext context) {
    showSearch(context: context, delegate: SettingsSearchDelegate(_categories));
  }

  @override
  void showConfirmationDialog(
    BuildContext context,
    String title,
    String message,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  void updateSettings(
    BuildContext context,
    Map<String, dynamic> settings,
  ) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        await FirebaseFirestore.instance
            .collection('user_settings')
            .doc(userId)
            .set(settings, SetOptions(merge: true));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating settings: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Settings Search Delegate
class SettingsSearchDelegate extends SearchDelegate<String> {
  final List<SettingsCategory> categories;

  SettingsSearchDelegate(this.categories);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final results = <SettingsItem>[];

    for (final category in categories) {
      for (final item in category.items) {
        if (item.title.toLowerCase().contains(query.toLowerCase()) ||
            item.subtitle.toLowerCase().contains(query.toLowerCase())) {
          results.add(item);
        }
      }
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final item = results[index];
        return ListTile(
          leading: Icon(item.icon),
          title: Text(item.title),
          subtitle: Text(item.subtitle),
          onTap: () {
            close(context, item.title);
            item.onTap();
          },
        );
      },
    );
  }
}
