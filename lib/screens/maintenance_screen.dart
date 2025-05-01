import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smart_society_app/utils/timeline_helper.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  String? userEmail;
  String? userFlat;
  String? userRole;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    userEmail = user.email;

    final memberQuery = await FirebaseFirestore.instance
        .collection('members')
        .where('email', isEqualTo: userEmail)
        .limit(1)
        .get();

    if (memberQuery.docs.isNotEmpty) {
      final data = memberQuery.docs.first.data();
      userFlat = data['flat'];
      userRole = data['role'];
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isAdmin = userRole == 'Secretary';
    final maintenanceRef = FirebaseFirestore.instance.collection('maintenance');
    final query = isAdmin
        ? maintenanceRef.orderBy('month', descending: true)
        : maintenanceRef
            .where('flat', isEqualTo: userFlat)
            .orderBy('month', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Maintenance'),
        backgroundColor: Colors.indigo,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading maintenance data'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final records = snapshot.data!.docs;

          if (records.isEmpty) {
            return Center(
              child: Text(
                isAdmin
                    ? 'No maintenance records yet.'
                    : 'No dues for your flat.',
              ),
            );
          }

          return ListView.builder(
            itemCount: records.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final data = records[index].data() as Map<String, dynamic>;
              final month = data['month'] ?? 'Unknown';
              final flat = data['flat'] ?? '---';
              final status = data['status'] ?? 'Unpaid';
              final amount = data['amount']?.toString() ?? '0';
              final isPaid = status.toLowerCase() == 'paid';

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 5,
                child: ListTile(
                  leading: Icon(
                    isPaid ? Icons.check_circle : Icons.error,
                    color: isPaid ? Colors.green : Colors.redAccent,
                    size: 32,
                  ),
                  title: Text('Month: $month'),
                  subtitle: Text('Flat: $flat\nAmount: ₹$amount'),
                  trailing: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isPaid ? Colors.green : Colors.redAccent,
                    ),
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: userRole == 'Secretary'
          ? FloatingActionButton(
              backgroundColor: Colors.indigo,
              child: const Icon(Icons.add),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const AddMaintenanceDialog(),
                );
              },
            )
          : null,
    );
  }
}

class AddMaintenanceDialog extends StatefulWidget {
  const AddMaintenanceDialog({super.key});

  @override
  State<AddMaintenanceDialog> createState() => _AddMaintenanceDialogState();
}

class _AddMaintenanceDialogState extends State<AddMaintenanceDialog> {
  final _monthController = TextEditingController();
  final _amountController = TextEditingController();
  final _flatController = TextEditingController();
  String _status = 'Unpaid';
  bool _isSaving = false;

  @override
  void dispose() {
    _monthController.dispose();
    _amountController.dispose();
    _flatController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final month = _monthController.text.trim();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    final flat = _flatController.text.trim();
    final status = _status;

    if (month.isEmpty || flat.isEmpty || amount <= 0) return;

    setState(() => _isSaving = true);

    await FirebaseFirestore.instance.collection('maintenance').add({
      'month': month,
      'amount': amount,
      'flat': flat,
      'status': status,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await logToTimeline(
      message: 'Maintenece submitted: $flat',
      source: 'maintenance',
    );

    setState(() => _isSaving = false);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Maintenance Record'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _monthController,
            decoration:
                const InputDecoration(labelText: 'Month (e.g. May 2025)'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Amount'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _flatController,
            decoration:
                const InputDecoration(labelText: 'Flat No (e.g. A-101)'),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _status,
            decoration: const InputDecoration(labelText: 'Status'),
            items: const [
              DropdownMenuItem(value: 'Paid', child: Text('Paid')),
              DropdownMenuItem(value: 'Unpaid', child: Text('Unpaid')),
            ],
            onChanged: (value) => setState(() => _status = value ?? 'Unpaid'),
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
            onPressed: _submit,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
            child: const Text('Add'),
          ),
        ],
      ],
    );
  }
}
