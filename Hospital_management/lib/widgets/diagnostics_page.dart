import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DiagnosticsPage extends StatefulWidget {
  const DiagnosticsPage({Key? key}) : super(key: key);

  @override
  State<DiagnosticsPage> createState() => _DiagnosticsPageState();
}

class _DiagnosticsPageState extends State<DiagnosticsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic> _userDoc = {};
  Map<String, dynamic> _debugDoc = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _userDoc = {};
        _debugDoc = {};
        _loading = false;
      });
      return;
    }

    try {
      final userSnap = await _firestore.collection('users').doc(user.uid).get();
      final debugSnap = await _firestore
          .collection('debug_uploads')
          .doc(user.uid)
          .get();
      setState(() {
        _userDoc = userSnap.exists ? (userSnap.data() ?? {}) : {};
        _debugDoc = debugSnap.exists ? (debugSnap.data() ?? {}) : {};
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Diagnostics (dev)')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'User document (users/{uid})',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _buildKeyValueList(_userDoc),
                    const SizedBox(height: 16),
                    const Text(
                      'Debug uploads (debug_uploads/{uid})',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _buildKeyValueList(_debugDoc),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                      onPressed: _load,
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildKeyValueList(Map<String, dynamic> map) {
    if (map.isEmpty) return const Text('No document found');
    final entries = map.entries.toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: entries.map((e) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 160,
                    child: Text(
                      '${e.key}:',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Expanded(child: SelectableText('${e.value}')),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
