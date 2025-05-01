import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smart_society_app/utils/timeline_helper.dart';

class BalanceSheetScreen extends StatelessWidget {
  const BalanceSheetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseFirestore.instance
        .collection('balanceSheet')
        .orderBy('timestamp', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Balance Sheet'),
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: ref.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading data.'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          double total = 0;
          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final amount = data['amount'] ?? 0;
            final type = data['type'] ?? 'Expense';
            total += type == 'Income' ? amount : -amount;
          }

          return Column(
            children: [
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Balance:',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('₹${total.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: total >= 0 ? Colors.green : Colors.red,
                        )),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: docs.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final title = data['title'] ?? 'Untitled';
                    final amount = data['amount'] ?? 0;
                    final type = data['type'] ?? 'Expense';
                    final date = data['date'] ?? '-';

                    final isIncome = type == 'Income';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Icon(
                          isIncome ? Icons.trending_up : Icons.trending_down,
                          color: isIncome ? Colors.green : Colors.red,
                        ),
                        title: Text(title),
                        subtitle: Text('Date: $date'),
                        trailing: Text(
                          (isIncome ? '+ ₹' : '- ₹') + amount.toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isIncome ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const AddBalanceEntryDialog(),
          );
        },
      ),
    );
  }
}

class AddBalanceEntryDialog extends StatefulWidget {
  const AddBalanceEntryDialog({super.key});

  @override
  State<AddBalanceEntryDialog> createState() => _AddBalanceEntryDialogState();
}

class _AddBalanceEntryDialogState extends State<AddBalanceEntryDialog> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();
  String _type = 'Income';
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        _dateController.text =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    final date = _dateController.text.trim();

    if (title.isEmpty || amount <= 0 || date.isEmpty) return;

    setState(() => _isSaving = true);

    await FirebaseFirestore.instance.collection('balanceSheet').add({
      'title': title,
      'amount': amount,
      'type': _type,
      'date': date,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await logToTimeline(
      message: 'Balance Sheet submitted: $title',
      source: 'balanceSheet',
    );

    setState(() => _isSaving = false);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Entry'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount (₹)'),
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
              value: _type,
              decoration: const InputDecoration(labelText: 'Type'),
              items: const [
                DropdownMenuItem(value: 'Income', child: Text('Income')),
                DropdownMenuItem(value: 'Expense', child: Text('Expense')),
              ],
              onChanged: (val) => setState(() => _type = val ?? 'Income'),
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
            onPressed: _submit,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
            child: const Text('Add'),
          ),
        ],
      ],
    );
  }
}
