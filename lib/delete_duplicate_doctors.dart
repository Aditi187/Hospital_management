// Utility script to delete duplicate doctors (same name, same specialty) from Firestore
// Run this script once in your Flutter app (e.g., from a button or debug page)
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> deleteDuplicateDoctors() async {
  final doctorsRef = FirebaseFirestore.instance.collection('doctors');
  final snapshot = await doctorsRef.get();
  final seen = <String, String>{}; // key: name|specialty, value: docId
  for (final doc in snapshot.docs) {
    final data = doc.data();
    final name = data['name']?.toString().trim();
    final specialty = data['specialty']?.toString().trim();
    if (name == null || specialty == null) continue;
    final key = '$name|$specialty';
    if (seen.containsKey(key)) {
      // Duplicate found, delete this doc
      await doc.reference.delete();
      print('Deleted duplicate: $name ($specialty)');
    } else {
      seen[key] = doc.id;
    }
  }
  print('Duplicate doctors removed from Firestore.');
}
