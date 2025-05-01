import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smart_society_app/utils/timeline_helper.dart';

class NoticeScreen extends StatelessWidget {
  const NoticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final noticesRef = FirebaseFirestore.instance
        .collection('notices')
        .orderBy('timestamp', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notice Board'),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: noticesRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading notices'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final notices = snapshot.data!.docs;

          if (notices.isEmpty) {
            return const Center(child: Text('No notices available'));
          }

          return ListView.builder(
            itemCount: notices.length,
            itemBuilder: (context, index) {
              final data = notices[index].data() as Map<String, dynamic>;
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
                            'Posted: ${timestamp.toString().substring(0, 16)}',
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
            builder: (context) => const AddNoticeDialog(),
          );
        },
      ),
    );
  }
}

class AddNoticeDialog extends StatefulWidget {
  const AddNoticeDialog({super.key});

  @override
  State<AddNoticeDialog> createState() => _AddNoticeDialogState();
}

class _AddNoticeDialogState extends State<AddNoticeDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submitNotice() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty || description.isEmpty) return;

    setState(() => _isSaving = true);

    await FirebaseFirestore.instance.collection('notices').add({
      'title': title,
      'description': description,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await logToTimeline(
      message: 'Notice Given: $title',
      source: 'notices',
    );

    setState(() => _isSaving = false);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Notice'),
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
        if (_isSaving)
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
            onPressed: _submitNotice,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Post'),
          ),
        ],
      ],
    );
  }
}
