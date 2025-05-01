import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MembersScreen extends StatelessWidget {
  const MembersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final membersRef =
        FirebaseFirestore.instance.collection('members').orderBy('name');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Society Members'),
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: membersRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading members'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final members = snapshot.data!.docs;

          if (members.isEmpty) {
            return const Center(child: Text('No members found.'));
          }

          return ListView.builder(
            itemCount: members.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final data = members[index].data() as Map<String, dynamic>;
              final name = data['name'] ?? 'Unknown';
              final flat = data['flat'] ?? '---';
              final role = data['role'] ?? 'Resident';

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.teal.shade100,
                    child: Text(
                      name.isNotEmpty ? name[0] : '?',
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal),
                    ),
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Flat: $flat'),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: role == 'Secretary'
                          ? Colors.orange
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      role,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color:
                            role == 'Secretary' ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
