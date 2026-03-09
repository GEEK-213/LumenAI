import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomePageCyberpunk extends StatelessWidget {
  final String userName;
  final String? avatarUrl;
  final int studyStreak;
  final int tasksDue;
  final List<String> subjects;
  final String selectedSubject;
  final Function(String) onSubjectSelected;
  final List<Map<String, dynamic>> filteredLectures;
  final bool isLoading;
  final VoidCallback onRefresh;
  final Function(String) onLectureTap; // ID of lecture to open
  final VoidCallback onChatPressed;
  final VoidCallback onProfilePressed;

  const HomePageCyberpunk({
    super.key,
    required this.userName,
    this.avatarUrl,
    required this.studyStreak,
    required this.tasksDue,
    required this.subjects,
    required this.selectedSubject,
    required this.onSubjectSelected,
    required this.filteredLectures,
    required this.isLoading,
    required this.onRefresh,
    required this.onLectureTap,
    required this.onChatPressed,
    required this.onProfilePressed,
  });

  @override
  Widget build(BuildContext context) {
    // Pure black background for the Cyberpunk look
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          SafeArea(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFF003C)),
                  )
                : RefreshIndicator(
                    color: const Color(0xFFFF003C),
                    backgroundColor: Colors.black,
                    onRefresh: () async => onRefresh(),
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(child: _buildHeader()),
                        SliverToBoxAdapter(child: const SizedBox(height: 24)),
                        SliverToBoxAdapter(child: _buildSearchBar()),
                        SliverToBoxAdapter(child: const SizedBox(height: 24)),
                        SliverToBoxAdapter(child: _buildGridStats()),
                        SliverToBoxAdapter(child: const SizedBox(height: 32)),
                        SliverToBoxAdapter(child: _buildSubjects()),
                        SliverToBoxAdapter(child: const SizedBox(height: 24)),
                        SliverToBoxAdapter(child: _buildRecentHeader()),
                        SliverToBoxAdapter(child: const SizedBox(height: 16)),
                        SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            if (index == filteredLectures.length) {
                              return const SizedBox(
                                height: 100,
                              ); // padding for FAB
                            }
                            return _buildLectureItem(filteredLectures[index]);
                          }, childCount: filteredLectures.length + 1),
                        ),
                      ],
                    ),
                  ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: FloatingActionButton(
                onPressed: onChatPressed,
                backgroundColor: const Color(0xFFFF003C),
                shape: const BeveledRectangleBorder(),
                child: const Icon(Icons.mic, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cyber Logo / Profile
          GestureDetector(
            onTap: onProfilePressed,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFFF003C), width: 3),
              ),
              child: Center(
                child: avatarUrl == null
                    ? Icon(
                        Icons.person_outline,
                        color: const Color(0xFFFF003C),
                        size: 32,
                      )
                    : Image.network(avatarUrl!, fit: BoxFit.cover),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "SYSTEM//DASHBOARD",
                  style: GoogleFonts.shareTechMono(
                    color: Colors.white54,
                    fontSize: 12,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  "WELCOME BACK,\n${userName.toUpperCase()}",
                  style: GoogleFonts.teko(
                    color: Colors.white,
                    fontSize: 32,
                    height: 1.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onChatPressed,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Center(
                child: Icon(Icons.smart_toy_outlined, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white54, width: 1.5),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            const Icon(Icons.search, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "SEARCH DATA STREAM...",
                style: GoogleFonts.shareTechMono(
                  color: Colors.white54,
                  fontSize: 14,
                ),
              ),
            ),
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: Colors.white54, width: 1.5),
                ),
              ),
              child: const Icon(
                Icons.picture_in_picture_alt_outlined,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white54, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "STREAK_VAL",
                    style: GoogleFonts.shareTechMono(
                      color: const Color(0xFFFF003C),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "$studyStreak",
                        style: GoogleFonts.teko(
                          color: Colors.white,
                          fontSize: 40,
                          height: 1.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          "DAYS",
                          style: GoogleFonts.shareTechMono(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 2,
                    color: const Color(0xFFFF003C),
                    width: 60,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white54, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "TASKS_PENDING",
                    style: GoogleFonts.shareTechMono(
                      color: const Color(0xFFFF003C),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "$tasksDue",
                        style: GoogleFonts.teko(
                          color: Colors.white,
                          fontSize: 40,
                          height: 1.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          "UNITS",
                          style: GoogleFonts.shareTechMono(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Stack(
                    children: [
                      Container(
                        height: 2,
                        color: Colors.white24,
                        width: double.infinity,
                      ),
                      Container(height: 2, color: Colors.white, width: 40),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjects() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "SUBJECTS",
                style: GoogleFonts.teko(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                "EXPLORE_ALL",
                style: GoogleFonts.shareTechMono(
                  color: Colors.white,
                  fontSize: 12,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              final subject = subjects[index];
              final isActive = subject == selectedSubject;
              return GestureDetector(
                onTap: () => onSubjectSelected(subject),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFFFF003C) : Colors.black,
                    border: Border.all(
                      color: isActive ? const Color(0xFFFF003C) : Colors.white,
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    subject.toUpperCase(),
                    style: GoogleFonts.shareTechMono(
                      color: isActive ? Colors.white : Colors.white,
                      fontSize: 14,
                      fontWeight: isActive
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        "RECENT LECTURES",
        style: GoogleFonts.teko(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildLectureItem(Map<String, dynamic> lecture) {
    // Generate some stable fake duration based on ID for the tech look
    final idLength = lecture['id'].toString().length;
    final mins = 35 + (idLength % 25);

    // Tech tag
    final bool isReview = (idLength % 3 == 0);
    final String statusTag = isReview ? "[REVIEW_REQ]" : "[PROCESSED]";
    final Color tagColor = isReview ? const Color(0xFFFF003C) : Colors.white;
    final Color tagBg = isReview ? const Color(0xFFFF003C) : Colors.transparent;

    return GestureDetector(
      onTap: () => onLectureTap(lecture['id'].toString()),
      child: Container(
        margin: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white54, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              color: Colors.white,
              child: Center(
                child: Icon(
                  _getTechIcon(lecture['id'].toString()),
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          (lecture['title'] ?? 'UNKNOWN DATA STREAM')
                              .toString()
                              .toUpperCase(),
                          style: GoogleFonts.shareTechMono(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: tagBg,
                          border: Border.all(color: tagColor),
                        ),
                        child: Text(
                          statusTag,
                          style: GoogleFonts.shareTechMono(
                            color: isReview ? Colors.white : Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        color: Colors.white54,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${mins}_MINS",
                        style: GoogleFonts.shareTechMono(
                          color: Colors.white54,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "[LOGGED]", // Just a tech sounding string instead of actual date
                        style: GoogleFonts.shareTechMono(
                          color: Colors.white54,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            const Icon(Icons.arrow_forward, color: Colors.white),
          ],
        ),
      ),
    );
  }

  IconData _getTechIcon(String id) {
    final icons = [
      Icons.memory,
      Icons.terminal,
      Icons.developer_board,
      Icons.data_object,
      Icons.dns,
      Icons.api,
    ];
    return icons[id.hashCode % icons.length];
  }
}
