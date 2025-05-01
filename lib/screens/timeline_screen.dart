import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TimelineScreen extends StatelessWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final timelineRef = FirebaseFirestore.instance
        .collection('timeline')
        .orderBy('timestamp', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Society Timeline'),
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: timelineRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading timeline.'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final posts = snapshot.data!.docs;

          if (posts.isEmpty) {
            return const Center(child: Text('No timeline updates yet.'));
          }

          return ListView.builder(
            itemCount: posts.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final data = posts[index].data() as Map<String, dynamic>;
              final sender = data['sender'] ?? 'Unknown';
              final message = data['message'] ?? '';
              final source = data['source'] ?? 'System';
              final time = (data['timestamp'] as Timestamp?)?.toDate();
              final formattedTime = time != null
                  ? DateFormat('MMM d, h:mm a').format(time)
                  : 'Unknown time';

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal.shade100,
                    child: const Icon(Icons.info_outline, color: Colors.teal),
                  ),
                  title: Text(message),
                  subtitle: Text('From: $sender • $source\n$formattedTime'),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
