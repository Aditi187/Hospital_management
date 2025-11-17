import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/admin_service.dart';
import '../login_page.dart';
import 'package:intl/intl.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _stats;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoadingStats = true);
    final stats = await AdminService.getAdminStats();
    setState(() {
      _stats = stats;
      _isLoadingStats = false;
    });
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
            tooltip: 'Refresh Statistics',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.pending_actions), text: 'Pending Doctors'),
            Tab(icon: Icon(Icons.medical_services), text: 'All Doctors'),
            Tab(icon: Icon(Icons.people), text: 'All Patients'),
            Tab(icon: Icon(Icons.announcement), text: 'Announcements'),
            Tab(icon: Icon(Icons.notifications), text: 'Alerts'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildPendingDoctorsTab(),
          _buildAllDoctorsTab(),
          _buildAllPatientsTab(),
          _buildAnnouncementsTab(),
          _buildAlertsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    if (_isLoadingStats) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_stats == null) {
      return const Center(child: Text('Failed to load statistics'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hospital Statistics',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard(
                'Total Doctors',
                (_stats!['totalDoctors'] ?? 0).toString(),
                Icons.medical_services,
                Colors.blue,
              ),
              _buildStatCard(
                'Approved Doctors',
                (_stats!['approvedDoctors'] ?? 0).toString(),
                Icons.check_circle,
                Colors.green,
              ),
              _buildStatCard(
                'Pending Approvals',
                (_stats!['pendingDoctors'] ?? 0).toString(),
                Icons.pending,
                Colors.orange,
              ),
              _buildStatCard(
                'Total Patients',
                (_stats!['totalPatients'] ?? 0).toString(),
                Icons.people,
                Colors.purple,
              ),
              _buildStatCard(
                'Total Appointments',
                (_stats!['totalAppointments'] ?? 0).toString(),
                Icons.calendar_today,
                Colors.teal,
              ),
              _buildStatCard(
                'Blocked Users',
                _stats!['blockedUsers'].toString(),
                Icons.block,
                Colors.red,
              ),
            ],
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
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingDoctorsTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: AdminService.getPendingDoctors(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final pendingDoctors = snapshot.data ?? [];

        if (pendingDoctors.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 80, color: Colors.green),
                SizedBox(height: 16),
                Text(
                  'No pending doctor approvals',
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: pendingDoctors.length,
          itemBuilder: (context, index) {
            final doctor = pendingDoctors[index];
            return _buildPendingDoctorCard(doctor);
          },
        );
      },
    );
  }

  Widget _buildPendingDoctorCard(Map<String, dynamic> doctor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange[100],
          child: const Icon(Icons.pending, color: Colors.orange),
        ),
        title: Text(
          doctor['name']?.toString() ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(doctor['specialty']?.toString() ?? 'No specialty'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Email', doctor['email']?.toString() ?? 'N/A'),
                _buildInfoRow(
                  'Personal ID',
                  doctor['personalId']?.toString() ?? 'N/A',
                ),
                _buildInfoRow('Phone', doctor['phone']?.toString() ?? 'N/A'),
                _buildInfoRow(
                  'Submitted At',
                  doctor['createdAt'] != null
                      ? DateFormat(
                          'MMM dd, yyyy',
                        ).format((doctor['createdAt'] as Timestamp).toDate())
                      : 'N/A',
                ),
                if (doctor['certificateUrl'] != null) ...[
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Open certificate in browser
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Certificate URL: ${doctor['certificateUrl']}',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.file_present),
                    label: const Text('View Certificate'),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _approveDoctor(doctor),
                        icon: const Icon(Icons.check),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _rejectDoctor(doctor),
                        icon: const Icon(Icons.close),
                        label: const Text('Reject'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllDoctorsTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: AdminService.getAllDoctors(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final doctors = snapshot.data ?? [];

        if (doctors.isEmpty) {
          return const Center(child: Text('No doctors found'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: doctors.length,
          itemBuilder: (context, index) {
            final doctor = doctors[index];
            return _buildUserCard(doctor, 'doctor');
          },
        );
      },
    );
  }

  Widget _buildAllPatientsTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: AdminService.getAllPatients(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final patients = snapshot.data ?? [];

        if (patients.isEmpty) {
          return const Center(child: Text('No patients found'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: patients.length,
          itemBuilder: (context, index) {
            final patient = patients[index];
            return _buildUserCard(patient, 'patient');
          },
        );
      },
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user, String userType) {
    final isBlocked = user['isBlocked'] == true;
    final approvalStatus = user['approvalStatus']?.toString() ?? 'unknown';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isBlocked
              ? Colors.red[100]
              : userType == 'doctor'
              ? Colors.blue[100]
              : Colors.purple[100],
          child: Icon(
            isBlocked
                ? Icons.block
                : userType == 'doctor'
                ? Icons.medical_services
                : Icons.person,
            color: isBlocked
                ? Colors.red
                : userType == 'doctor'
                ? Colors.blue
                : Colors.purple,
          ),
        ),
        title: Text(
          user['name']?.toString() ?? 'Unknown',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: isBlocked ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user['email']?.toString() ?? 'No email'),
            if (userType == 'doctor')
              Text(
                'Status: ${approvalStatus.toUpperCase()}',
                style: TextStyle(
                  color: approvalStatus == 'approved'
                      ? Colors.green
                      : approvalStatus == 'pending'
                      ? Colors.orange
                      : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'block') {
              _toggleBlockUser(user, true);
            } else if (value == 'unblock') {
              _toggleBlockUser(user, false);
            } else if (value == 'delete') {
              _deleteUser(user);
            }
          },
          itemBuilder: (context) => [
            if (!isBlocked)
              const PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    Icon(Icons.block, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Block User'),
                  ],
                ),
              ),
            if (isBlocked)
              const PopupMenuItem(
                value: 'unblock',
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Unblock User'),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete User'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _showSendAnnouncementDialog,
            icon: const Icon(Icons.announcement),
            label: const Text('Send Announcement to All Patients'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: AdminService.getAllAnnouncements(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final announcements = snapshot.data ?? [];

              if (announcements.isEmpty) {
                return const Center(child: Text('No announcements yet'));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: announcements.length,
                itemBuilder: (context, index) {
                  final announcement = announcements[index];
                  return _buildAnnouncementCard(announcement);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAlertsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _showSendAlertDialog,
            icon: const Icon(Icons.notification_important),
            label: const Text('Send Alert to All Doctors'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: AdminService.getAllAnnouncements(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final alerts = snapshot.data ?? [];
              final doctorAlerts = alerts
                  .where((a) => a['targetRole'] == 'doctor')
                  .toList();

              if (doctorAlerts.isEmpty) {
                return const Center(child: Text('No alerts yet'));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: doctorAlerts.length,
                itemBuilder: (context, index) {
                  final alert = doctorAlerts[index];
                  return _buildAnnouncementCard(alert);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAnnouncementCard(Map<String, dynamic> announcement) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: announcement['targetRole'] == 'doctor'
              ? Colors.orange[100]
              : Colors.purple[100],
          child: Icon(
            announcement['targetRole'] == 'doctor'
                ? Icons.notification_important
                : Icons.announcement,
            color: announcement['targetRole'] == 'doctor'
                ? Colors.orange
                : Colors.purple,
          ),
        ),
        title: Text(
          announcement['title']?.toString() ?? 'No title',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(announcement['message']?.toString() ?? 'No message'),
            if (announcement['createdAt'] != null)
              Text(
                DateFormat(
                  'MMM dd, yyyy hh:mm a',
                ).format((announcement['createdAt'] as Timestamp).toDate()),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
          ],
        ),
        isThreeLine: true,
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
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _approveDoctor(Map<String, dynamic> doctor) async {
    final controller = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Doctor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Approve Dr. ${doctor['name']}?'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Approval Reason (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await AdminService.approveDoctorAccount(
        doctor['id'],
        controller.text.isEmpty ? 'Approved by admin' : controller.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Doctor approved successfully'
                  : 'Failed to approve doctor',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );

        if (success) {
          _loadStats();
          setState(() {});
        }
      }
    }
  }

  Future<void> _rejectDoctor(Map<String, dynamic> doctor) async {
    final controller = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Doctor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Reject Dr. ${doctor['name']}?'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason *',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide a rejection reason'),
                  ),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await AdminService.rejectDoctorAccount(
        doctor['id'],
        controller.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Doctor rejected successfully'
                  : 'Failed to reject doctor',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );

        if (success) {
          _loadStats();
          setState(() {});
        }
      }
    }
  }

  Future<void> _toggleBlockUser(Map<String, dynamic> user, bool block) async {
    final controller = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(block ? 'Block User' : 'Unblock User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(block ? 'Block ${user['name']}?' : 'Unblock ${user['name']}?'),
            if (block) ...[
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Block Reason *',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (block && controller.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide a block reason'),
                  ),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: block ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(block ? 'Block' : 'Unblock'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await AdminService.toggleUserBlock(
        user['id'],
        block,
        controller.text.isEmpty ? 'Blocked by admin' : controller.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? block
                        ? 'User blocked successfully'
                        : 'User unblocked successfully'
                  : 'Failed to update user status',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );

        if (success) {
          _loadStats();
          setState(() {});
        }
      }
    }
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'Are you sure you want to delete ${user['name']}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await AdminService.deleteUser(user['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'User deleted successfully' : 'Failed to delete user',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );

        if (success) {
          _loadStats();
          setState(() {});
        }
      }
    }
  }

  Future<void> _showSendAnnouncementDialog() async {
    final titleController = TextEditingController();
    final messageController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Announcement to All Patients'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                decoration: const InputDecoration(
                  labelText: 'Message *',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 8),
              const Text(
                'Examples: "Hospital closed on Sunday", "New COVID rules", etc.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isEmpty ||
                  messageController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Send'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await AdminService.sendAnnouncementToPatients(
        titleController.text,
        messageController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Announcement sent to all patients'
                  : 'Failed to send announcement',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );

        if (success) {
          setState(() {});
        }
      }
    }
  }

  Future<void> _showSendAlertDialog() async {
    final titleController = TextEditingController();
    final messageController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Alert to All Doctors'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                decoration: const InputDecoration(
                  labelText: 'Message *',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 8),
              const Text(
                'Examples: "Emergency meeting at 5 PM", "Update patient records", etc.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isEmpty ||
                  messageController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Send'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await AdminService.sendAlertToDoctors(
        titleController.text,
        messageController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Alert sent to all doctors' : 'Failed to send alert',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );

        if (success) {
          setState(() {});
        }
      }
    }
  }
}
