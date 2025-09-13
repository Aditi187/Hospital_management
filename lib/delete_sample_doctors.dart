// Utility script to delete sample/example doctors from Firestore
// Run this script once in your Flutter app (e.g., from a button or debug page)
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> deleteSampleDoctors() async {
  final sampleNames = [
    'Dr. John Smith',
    'Dr. Alice Brown',
    'Dr. Priya Patel',
    'Dr. Rajesh Kumar',
    'Dr. Emily Chen',
    'Dr. Maria Garcia',
    'Dr. David Lee',
    'Dr. Sarah Wilson',
    'Dr. Ahmed Hassan',
    'Dr. Olivia Jones',
  ];
  final doctorsRef = FirebaseFirestore.instance.collection('doctors');
  for (final name in sampleNames) {
    final query = await doctorsRef.where('name', isEqualTo: name).get();
    for (final doc in query.docs) {
      await doc.reference.delete();
    }
  }
  print('Sample doctors deleted from Firestore.');
}
