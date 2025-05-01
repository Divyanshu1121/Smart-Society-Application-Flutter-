import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ComplaintsScreen extends StatelessWidget {
  const ComplaintsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final complaintsRef = FirebaseFirestore.instance
        .collection('complaints')
        .orderBy('timestamp', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaints'),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: complaintsRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading complaints'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final complaints = snapshot.data!.docs;

          if (complaints.isEmpty) {
            return const Center(child: Text('No complaints submitted yet'));
          }

          return ListView.builder(
            itemCount: complaints.length,
            itemBuilder: (context, index) {
              final data = complaints[index].data() as Map<String, dynamic>;
              final title = data['title'] ?? 'No Title';
              final description = data['description'] ?? 'No Description';
              final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text(title,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(description),
                      if (timestamp != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            'Submitted: ${timestamp.toString().substring(0, 16)}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const AddComplaintDialog(),
          );
        },
      ),
    );
  }
}

class AddComplaintDialog extends StatefulWidget {
  const AddComplaintDialog({super.key});

  @override
  State<AddComplaintDialog> createState() => _AddComplaintDialogState();
}

class _AddComplaintDialogState extends State<AddComplaintDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submitComplaint() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty || description.isEmpty) return;

    setState(() => _isSubmitting = true);

    await FirebaseFirestore.instance.collection('complaints').add({
      'title': title,
      'description': description,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance.collection('timeline').add({
      'sender': FirebaseAuth.instance.currentUser?.email ?? 'Unknown',
      'message': 'Complaint submitted: $title',
      'source': 'Complaints',
      'timestamp': FieldValue.serverTimestamp(),
    });

    setState(() => _isSubmitting = false);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Submit Complaint'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(labelText: 'Description'),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        if (_isSubmitting)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: CircularProgressIndicator(),
          )
        else ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _submitComplaint,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Submit'),
          ),
        ],
      ],
    );
  }
}
