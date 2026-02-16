import 'package:app/components/card.dart';

import 'package:flutter/material.dart';
import '../profile/profilePage.dart';

//  class to hold Lecture Data
class LectureData {
  final String title;
  final String subject; // filtering
  final String time;
  final IconData icon;
  final Color iconBgColor;
  final String? badgeText;
  final Color? badgeColor;

  LectureData({
    required this.title,
    required this.subject,
    required this.time,
    required this.icon,
    required this.iconBgColor,
    this.badgeText,
    this.badgeColor,
  });
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

//WIDGETS
class _HomePageState extends State<HomePage> {
  //  variable to track the currently selected subject
  String _selectedSubject = "All";

  // 4. Define your data list here
  final List<LectureData> _allLectures = [
    LectureData(
      title: "Intro to Molecular Biology",
      subject: "Biology",
      time: "45 mins • Today",
      icon: Icons.science,
      iconBgColor: Colors.purple[300]!,
      badgeText: "PROCESSED",
      badgeColor: Colors.green[700]!,
    ),
    LectureData(
      title: "European History: 1800s",
      subject: "History",
      time: "1hr 10m • Yesterday",
      icon: Icons.history_edu,
      iconBgColor: Colors.orange[300]!,
      badgeText: "REVIEW",
      badgeColor: Colors.blue[700]!,
    ),
    LectureData(
      title: "Linear Algebra 101",
      subject: "Calculus", // Grouping Math under Calculus for this example
      time: "55 mins • Oct 24",
      icon: Icons.functions,
      iconBgColor: Colors.teal[300]!,
    ),
    LectureData(
      title: "Python Data Structures",
      subject: "Computer Science",
      time: "1hr 20m • Oct 22",
      icon: Icons.code,
      iconBgColor: Colors.pink[300]!,
    ),
  ];

  //  Helper function to get the list to display based on selection
  List<LectureData> get _filteredLectures {
    if (_selectedSubject == "All") {
      return _allLectures;
    }
    return _allLectures
        .where((lecture) => lecture.subject == _selectedSubject)
        .toList();
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

      //  The Body
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

              // Subjects Section
              _buildSubjectsSection(),
              const SizedBox(height: 24),

              //recenet lectures
              _buildRecentLecturesSection(),
            ],
          ),
        ),
      ),

      //floating action button
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     Navigator.push(
      //       context,
      //       MaterialPageRoute(builder: (context) => const FlashCardPage()),
      //     );
      //   },
      //   backgroundColor: const Color.fromARGB(255, 77, 158, 220),
      //   child: const Icon(Icons.mic),
      // ),
      //botttom navigation
      // bottomNavigationBar: NavigationBar(
      //   selectedIndex: _selectedIndex,
      //   onDestinationSelected: _onItemTapped,
      //   destinations: const [
      //     NavigationDestination(
      //       icon: Icon(Icons.home_outlined),
      //       selectedIcon: Icon(Icons.home),
      //       label: 'Home',
      //     ),
      //     NavigationDestination(
      //       icon: Icon(Icons.folder_outlined),
      //       selectedIcon: Icon(Icons.folder),
      //       label: 'Projects',
      //     ),
      //     NavigationDestination(
      //       icon: Icon(Icons.note_outlined),
      //       selectedIcon: Icon(Icons.analytics),
      //       label: 'Notes',
      //     ),
      //     NavigationDestination(
      //       icon: Icon(Icons.person_2_outlined),
      //       selectedIcon: Icon(Icons.analytics),
      //       label: 'Profile',
      //     ),
      //   ],
      // ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 29, 28, 28),
        borderRadius: BorderRadius.circular(30),
      ),
      child: const TextField(
        decoration: InputDecoration(
          hintText: "cyber security...",
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

  Widget _buildSubjectsSection() {
    // List of subjects to display as chips
    final subjects = ["All", "Biology", "History", "Calculus"];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Subjects",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(onPressed: () {}, child: const Text("View all")),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            // Generate chips dynamically
            children: subjects.map((subject) {
              return Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: _buildSubjectChip(
                  subject,
                  isActive:
                      _selectedSubject ==
                      subject, // Check if this matches selected
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectChip(String label, {bool isActive = false}) {
    return GestureDetector(
      // Add tap handler to update state
      onTap: () {
        setState(() {
          _selectedSubject = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF1E88E5) : const Color(0xFF1A2036),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey[400],
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildRecentLecturesSection() {
    // Get the filtered list
    final lecturesToDisplay = _filteredLectures;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Recent Lectures",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // If list is empty, show a message
        if (lecturesToDisplay.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              "No lectures found for this subject.",
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          // Map the data model to the Widget
          ...lecturesToDisplay.map(
            (data) => _buildLectureCard(
              icon: data.icon,
              iconBgColor: data.iconBgColor,
              title: data.title,
              time: data.time,
              badgeText: data.badgeText,
              badgeColor: data.badgeColor,
            ),
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
}
