import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_society_app/utils/timeline_helper.dart';

class VisitorsScreen extends StatefulWidget {
  const VisitorsScreen({super.key});

  @override
  State<VisitorsScreen> createState() => _VisitorsScreenState();
}

class _VisitorsScreenState extends State<VisitorsScreen> {
  String selectedFlat = 'All';
  String selectedPurpose = 'All';

  final List<String> flatOptions = ['All', 'A-101', 'A-102', 'B-201', 'B-202'];
  final List<String> purposeOptions = [
    'All',
    'Delivery',
    'Guest',
    'Relative',
    'Other'
  ];

  @override
  Widget build(BuildContext context) {
    Query visitorsQuery = FirebaseFirestore.instance
        .collection('visitors')
        .orderBy('timestamp', descending: true);

    if (selectedFlat != 'All') {
      visitorsQuery = visitorsQuery.where('flat', isEqualTo: selectedFlat);
    }

    if (selectedPurpose != 'All') {
      visitorsQuery =
          visitorsQuery.where('purpose', isEqualTo: selectedPurpose);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Visitors Log'),
        backgroundColor: Colors.blueGrey,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedFlat,
                    decoration: const InputDecoration(labelText: 'Flat'),
                    onChanged: (value) =>
                        setState(() => selectedFlat = value ?? 'All'),
                    items: flatOptions
                        .map((flat) =>
                            DropdownMenuItem(value: flat, child: Text(flat)))
                        .toList(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedPurpose,
                    decoration: const InputDecoration(labelText: 'Purpose'),
                    onChanged: (value) =>
                        setState(() => selectedPurpose = value ?? 'All'),
                    items: purposeOptions
                        .map((purpose) => DropdownMenuItem(
                            value: purpose, child: Text(purpose)))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: visitorsQuery.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading visitors'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final visitors = snapshot.data!.docs;

                if (visitors.isEmpty) {
                  return const Center(
                      child: Text('No visitor entries match filters.'));
                }

                return ListView.builder(
                  itemCount: visitors.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final doc = visitors[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final name = data['name'] ?? 'Unknown';
                    final flat = data['flat'] ?? '-';
                    final purpose = data['purpose'] ?? 'N/A';
                    final entryTime = data['entryTime'] ?? '';
                    final exitTime = data['exitTime'] ?? null;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blueGrey.shade100,
                          child: const Icon(Icons.person),
                        ),
                        title: Text(name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Flat: $flat'),
                            Text('Purpose: $purpose'),
                            Text('Entry: $entryTime'),
                            Text(exitTime != null
                                ? 'Exit: $exitTime'
                                : 'Exit: -'),
                          ],
                        ),
                        trailing: exitTime == null
                            ? IconButton(
                                icon: const Icon(Icons.exit_to_app,
                                    color: Colors.red),
                                onPressed: () async {
                                  final now = DateTime.now();
                                  final exit = DateFormat('yyyy-MM-dd HH:mm')
                                      .format(now);
                                  await doc.reference
                                      .update({'exitTime': exit});
                                },
                              )
                            : const Icon(Icons.check, color: Colors.green),
                        isThreeLine: true,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueGrey,
        child: const Icon(Icons.add),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const AddVisitorDialog(),
          );
        },
      ),
    );
  }
}

class AddVisitorDialog extends StatefulWidget {
  const AddVisitorDialog({super.key});

  @override
  State<AddVisitorDialog> createState() => _AddVisitorDialogState();
}

class _AddVisitorDialogState extends State<AddVisitorDialog> {
  final _nameController = TextEditingController();
  final _flatController = TextEditingController();
  final _purposeController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _flatController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final flat = _flatController.text.trim();
    final purpose = _purposeController.text.trim();

    if (name.isEmpty || flat.isEmpty || purpose.isEmpty) return;

    final now = DateTime.now();
    final formattedTime = DateFormat('yyyy-MM-dd HH:mm').format(now);

    setState(() => _isSaving = true);

    await FirebaseFirestore.instance.collection('visitors').add({
      'name': name,
      'flat': flat,
      'purpose': purpose,
      'entryTime': formattedTime,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await logToTimeline(
      message: 'Visitors Came: $name',
      source: 'visitors',
    );

    setState(() => _isSaving = false);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Visitor Entry'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Visitor Name'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _flatController,
            decoration: const InputDecoration(labelText: 'Visiting Flat'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _purposeController,
            decoration: const InputDecoration(labelText: 'Purpose'),
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
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
            child: const Text('Log Visitor'),
          ),
        ],
      ],
    );
  }
}
