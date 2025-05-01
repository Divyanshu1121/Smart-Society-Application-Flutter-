import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'notice_screen.dart';
import 'events_screen.dart';
import 'complaints_screen.dart';
import 'members_screen.dart';
import 'maintenance_screen.dart';
import 'visitors_screen.dart';
import 'resources_screen.dart';
import 'balance_screen.dart';
import 'polls_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? 'User';

    final features = [
      {
        'title': 'Members',
        'icon': Icons.group,
        'screen': const MembersScreen()
      },
      {
        'title': 'Notice Board',
        'icon': Icons.announcement,
        'screen': const NoticeScreen()
      },
      {
        'title': 'Maintenance',
        'icon': Icons.home_repair_service,
        'screen': const MaintenanceScreen()
      },
      {'title': 'Events', 'icon': Icons.event, 'screen': const EventsScreen()},
      {
        'title': 'Visitors',
        'icon': Icons.person_add,
        'screen': const VisitorsScreen()
      },
      {
        'title': 'Building Resources',
        'icon': Icons.apartment,
        'screen': const ResourcesScreen()
      },
      {
        'title': 'Complaints',
        'icon': Icons.report_problem,
        'screen': const ComplaintsScreen()
      },
      {
        'title': 'Balance Sheet',
        'icon': Icons.receipt_long,
        'screen': const BalanceSheetScreen()
      },
      {'title': 'Polls', 'icon': Icons.poll, 'screen': const PollsScreen()},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Society'),
        backgroundColor: Colors.green.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logged out successfully')),
              );
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.green.shade100,
            child: Text(
              'Welcome, $userEmail 👋',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GridView.builder(
                itemCount: features.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: 0.85,
                ),
                itemBuilder: (context, index) {
                  final feature = features[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => feature['screen'] as Widget),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.15),
                            blurRadius: 6,
                            offset: const Offset(2, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.green.shade200,
                            child: Icon(
                              feature['icon'] as IconData,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            feature['title'] as String,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
