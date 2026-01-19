import 'package:app/components/card.dart';
import 'package:app/pages/recorder.dart';
import 'package:flutter/material.dart';
import 'profilePage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,

      // AppBar
      appBar: AppBar(
        toolbarHeight: 80,
        leadingWidth: 80,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Center(
            child: Stack(
              children: [
                // 1. Profile Image
                GestureDetector(
                  onTap: () {
                    // Navigate to your Home Page (DashboardShell)
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const Profilepage(),
                      ),
                    );
                  },
                  child: const CircleAvatar(
                    radius: 25,
                    backgroundImage: NetworkImage(
                      'https://i.pravatar.cc/150?u=a042581f4e29026704d',
                    ), // Profile Pic
                  ),
                ),

                // 2. Online Status Dot
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    height: 14,
                    width: 14,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.surface,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "DASHBOARD",
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                letterSpacing: 1.2,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              "Welcome back, Gauresh",
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceVariant.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {},
              ),
            ),
          ),
        ],
      ),

      // 2. The Body (Empty State)
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //search bar
              _buildSearchBar(),
              const SizedBox(height: 20),

              //stats bar
              _buildStatsRow(),
              const SizedBox(height: 24),

              //recenet lectures
              _buildRecentLecturesSection(),
            ],
          ),
        ),
      ),

      //floating action button
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FlashCardPage()),
          );
        },
        backgroundColor: const Color.fromARGB(255, 77, 158, 220),
        child: const Icon(Icons.mic),
      ),
      //botttom navigation
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'Projects',
          ),
          NavigationDestination(
            icon: Icon(Icons.note_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Notes',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_2_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
//WIDGETS

Widget _buildSearchBar() {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(30),
    ),
    child: const TextField(
      decoration: InputDecoration(
        hintText: "cyber security",
        prefixIcon: null,
        border: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      ),
    ),
  );
}

Widget _buildStatsRow() {
  return Row(
    children: [
      Expanded(
        child: _buildStatsCard(
          title: "Study Streak",
          count: "5",
          unit: "days",
          icon: Icons.local_fire_department,
          iconColor: Colors.blue,
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: _buildStatsCard(
          title: "Tasks Due",
          count: "3",
          unit: "pending",
          icon: Icons.assignment_turned_in,
          iconColor: Colors.purple,
        ),
      ),
    ],
  );
}

Widget _buildStatsCard({
  required String title,
  required String count,
  required String unit,
  required IconData icon,
  required Color iconColor,
}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF1A2036),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  count,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
              ],
            ),
          ],
        ),
        const Spacer(),
        Icon(icon, size: 40, color: iconColor),
      ],
    ),
  );
}

Widget _buildRecentLecturesSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "Recent Lectures",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 16),
      _buildLectureCard(
        icon: Icons.code,
        iconBgColor: Colors.purple[300]!,
        title: "Intro to python",
        time: "60 mins • Today",
        badgeText: "PROCESSED",
        badgeColor: Colors.green[700]!,
      ),
      _buildLectureCard(
        icon: Icons.code,
        iconBgColor: Colors.pink[300]!,
        title: " Data Structures in C",
        time: "1hr 40m • Oct 25",
        badgeText: "PREVIEW",
        badgeColor: const Color.fromARGB(255, 12, 80, 198),
      ),
    ],
  );
}

Widget _buildLectureCard({
  required IconData icon,
  required Color iconBgColor,
  required String title,
  required String time,
  String? badgeText,
  Color? badgeColor,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF1A2036),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: iconBgColor,
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                time,
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ],
          ),
        ),
        if (badgeText != null && badgeColor != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              badgeText,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        const SizedBox(width: 8),
        Icon(Icons.chevron_right, color: Colors.grey[400]),
      ],
    ),
  );
}
