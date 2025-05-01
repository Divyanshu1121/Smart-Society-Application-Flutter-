import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_society_app/utils/timeline_helper.dart';

class ResourcesScreen extends StatelessWidget {
  const ResourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bookingsRef = FirebaseFirestore.instance
        .collection('resources')
        .orderBy('date', descending: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Building Resources'),
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: bookingsRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return const Center(child: Text('Error loading bookings'));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final bookings = snapshot.data!.docs;

          if (bookings.isEmpty) {
            return const Center(child: Text('No bookings yet.'));
          }

          return ListView.builder(
            itemCount: bookings.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final data = bookings[index].data() as Map<String, dynamic>;
              final resource = data['resource'] ?? 'Unknown';
              final flat = data['flat'] ?? 'Unknown';
              final date = data['date'] ?? '---';
              final slot = data['slot'] ?? '---';

              final icon = _getIconForResource(resource);

              return Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.teal.shade100,
                    child: Icon(icon, color: Colors.teal),
                  ),
                  title: Text(resource,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Flat: $flat\nDate: $date\nSlot: $slot'),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const AddResourceDialog(),
          );
        },
      ),
    );
  }

  IconData _getIconForResource(String resource) {
    switch (resource.toLowerCase()) {
      case 'gym':
        return Icons.fitness_center;
      case 'community hall':
        return Icons.house;
      case 'garden':
        return Icons.park;
      default:
        return Icons.device_hub;
    }
  }
}

class AddResourceDialog extends StatefulWidget {
  const AddResourceDialog({super.key});

  @override
  State<AddResourceDialog> createState() => _AddResourceDialogState();
}

class _AddResourceDialogState extends State<AddResourceDialog> {
  final _flatController = TextEditingController();
  final _dateController = TextEditingController();
  final _slotController = TextEditingController();
  String _selectedResource = 'Community Hall';
  bool _isSaving = false;

  final List<String> _resources = ['Community Hall', 'Gym', 'Garden'];
  final List<String> _slots = [
    '6AM–7AM',
    '7AM–8AM',
    '10AM–12PM',
    '4PM–6PM',
    '6PM–8PM',
  ];

  @override
  void dispose() {
    _flatController.dispose();
    _dateController.dispose();
    _slotController.dispose();
    super.dispose();
  }

  Future<void> _submitBooking() async {
    final flat = _flatController.text.trim();
    final date = _dateController.text.trim();
    final slot = _slotController.text.trim();

    if (flat.isEmpty || date.isEmpty || slot.isEmpty) return;

    setState(() => _isSaving = true);

    await FirebaseFirestore.instance.collection('resources').add({
      'resource': _selectedResource,
      'flat': flat,
      'date': date,
      'slot': slot,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await logToTimeline(
      message: 'Resources Booked: $flat',
      source: 'resources',
    );

    setState(() => _isSaving = false);
    Navigator.of(context).pop();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      final formatted = DateFormat('yyyy-MM-dd').format(picked);
      _dateController.text = formatted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Book Resource'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedResource,
              items: _resources.map((res) {
                return DropdownMenuItem(
                  value: res,
                  child: Text(res),
                );
              }).toList(),
              decoration: const InputDecoration(labelText: 'Resource'),
              onChanged: (val) =>
                  setState(() => _selectedResource = val ?? 'Community Hall'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _flatController,
              decoration: const InputDecoration(labelText: 'Flat Number'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _dateController,
              readOnly: true,
              onTap: _pickDate,
              decoration: const InputDecoration(labelText: 'Date'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _slots.first,
              decoration: const InputDecoration(labelText: 'Time Slot'),
              onChanged: (val) =>
                  setState(() => _slotController.text = val ?? ''),
              items: _slots.map((slot) {
                return DropdownMenuItem(value: slot, child: Text(slot));
              }).toList(),
            ),
          ],
        ),
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
            onPressed: _submitBooking,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            child: const Text('Book'),
          ),
        ],
      ],
    );
  }
}
