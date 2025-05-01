import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> logToTimeline({
  required String message,
  required String source,
}) async {
  final user = FirebaseAuth.instance.currentUser;
  final sender = user?.email ?? 'Unknown';

  await FirebaseFirestore.instance.collection('timeline').add({
    'sender': sender,
    'message': message,
    'source': source,
    'timestamp': FieldValue.serverTimestamp(),
  });
}
