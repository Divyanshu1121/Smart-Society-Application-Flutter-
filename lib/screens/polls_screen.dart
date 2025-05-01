import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smart_society_app/utils/timeline_helper.dart';

class PollsScreen extends StatelessWidget {
  const PollsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pollsRef =
        FirebaseFirestore.instance.collection('polls').orderBy('question');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Polls'),
        backgroundColor: Colors.deepOrange,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: pollsRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return const Center(child: Text('Error loading polls'));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final polls = snapshot.data!.docs;

          if (polls.isEmpty)
            return const Center(child: Text('No active polls'));

          return ListView.builder(
            itemCount: polls.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final doc = polls[index];
              final data = doc.data() as Map<String, dynamic>;
              final question = data['question'];
              final options = List<String>.from(data['options']);
              final votes = Map<String, dynamic>.from(data['votes']);
              final votedBy = List<String>.from(data['votedBy'] ?? []);

              final currentEmail =
                  FirebaseAuth.instance.currentUser?.email ?? '';
              final hasVoted = votedBy.contains(currentEmail);

              return Card(
                margin: const EdgeInsets.only(bottom: 20),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(question,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      ...options.map((option) {
                        final voteCount = votes[option] ?? 0;
                        return ListTile(
                          title: Text(option),
                          subtitle: hasVoted
                              ? Text('Votes: $voteCount',
                                  style: const TextStyle(color: Colors.grey))
                              : null,
                          leading: hasVoted
                              ? const Icon(Icons.check_circle_outline,
                                  color: Colors.grey)
                              : const Icon(Icons.radio_button_unchecked),
                          onTap: hasVoted
                              ? null
                              : () async {
                                  // Update vote
                                  await FirebaseFirestore.instance
                                      .runTransaction((tx) async {
                                    final updatedVotes =
                                        Map<String, dynamic>.from(votes);
                                    updatedVotes[option] =
                                        (updatedVotes[option] ?? 0) + 1;
                                    final updatedVotedBy =
                                        List<String>.from(votedBy)
                                          ..add(currentEmail);

                                    tx.update(doc.reference, {
                                      'votes': updatedVotes,
                                      'votedBy': updatedVotedBy,
                                    });
                                  });
                                },
                        );
                      }).toList(),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepOrange,
        child: const Icon(Icons.add),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const AddPollDialog(),
          );
        },
      ),
    );
  }
}

class AddPollDialog extends StatefulWidget {
  const AddPollDialog({super.key});

  @override
  State<AddPollDialog> createState() => _AddPollDialogState();
}

class _AddPollDialogState extends State<AddPollDialog> {
  final _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  bool _isSaving = false;

  @override
  void dispose() {
    _questionController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addOptionField() {
    setState(() {
      _optionControllers.add(TextEditingController());
    });
  }

  Future<void> _submitPoll() async {
    final question = _questionController.text.trim();
    final options = _optionControllers
        .map((c) => c.text.trim())
        .where((o) => o.isNotEmpty)
        .toList();

    if (question.isEmpty || options.length < 2) return;

    setState(() => _isSaving = true);

    final votes = {for (var option in options) option: 0};

    await FirebaseFirestore.instance.collection('polls').add({
      'question': question,
      'options': options,
      'votes': votes,
      'votedBy': [],
    });

    await logToTimeline(
      message: 'Polls Given: $question',
      source: 'polls',
    );

    setState(() => _isSaving = false);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Poll'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: _questionController,
              decoration: const InputDecoration(labelText: 'Question'),
            ),
            const SizedBox(height: 10),
            ..._optionControllers.map((controller) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText:
                          'Option ${_optionControllers.indexOf(controller) + 1}',
                    ),
                  ),
                )),
            TextButton.icon(
              onPressed: _addOptionField,
              icon: const Icon(Icons.add),
              label: const Text('Add Option'),
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
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _submitPoll,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
            child: const Text('Post Poll'),
          ),
        ],
      ],
    );
  }
}
