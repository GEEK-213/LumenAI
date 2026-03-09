import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomePageSketch extends StatelessWidget {
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
  final Function(String) onLectureTap;
  final VoidCallback onChatPressed;
  final VoidCallback onProfilePressed;

  const HomePageSketch({
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
    // Light grayish textured background
    return Container(
      color: const Color(0xFFE8E9F3),
      child: Stack(
        children: [
          SafeArea(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.black),
                  )
                : RefreshIndicator(
                    color: Colors.black,
                    backgroundColor: Colors.white,
                    onRefresh: () async => onRefresh(),
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(child: const SizedBox(height: 16)),
                        SliverToBoxAdapter(child: _buildHeader()),
                        SliverToBoxAdapter(child: const SizedBox(height: 24)),
                        SliverToBoxAdapter(child: _buildSearchBar()),
                        SliverToBoxAdapter(child: const SizedBox(height: 24)),
                        SliverToBoxAdapter(child: _buildStats()),
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
                              return const SizedBox(height: 100);
                            }
                            return _buildLectureItem(
                              filteredLectures[index],
                              index,
                            );
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
              margin: const EdgeInsets.only(
                right: 4,
                bottom: 4,
              ), // offset for shadow
              decoration: _sketchDeco(
                color: const Color(0xFFF5B7B1),
                radius: 16,
              ),
              child: FloatingActionButton(
                onPressed: onChatPressed,
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: const Icon(
                  Icons.smart_toy_outlined,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper for the hand-drawn shadow effect
  BoxDecoration _sketchDeco({required Color color, double radius = 12}) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.black, width: 2),
      boxShadow: const [
        BoxShadow(
          color: Colors.black,
          offset: Offset(4, 4), // The offset solid shadow
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Avatar box
          GestureDetector(
            onTap: onProfilePressed,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: _sketchDeco(
                color: const Color(0xFFD4E6F1),
                radius: 8,
              ),
              child: avatarUrl == null
                  ? const Icon(
                      Icons.person_outline,
                      size: 36,
                      color: Colors.black87,
                    )
                  : Image.network(
                      avatarUrl!,
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "DASHBOARD",
                  style: GoogleFonts.comicNeue(
                    color: Colors.black54,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  "Welcome back, ${userName.split(' ').first}!",
                  style: GoogleFonts.comicNeue(
                    color: Colors.black87,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onChatPressed,
            child: Container(
              width: 44,
              height: 44,
              decoration: _sketchDeco(
                color: const Color(0xFFE8DAEF),
                radius: 12,
              ),
              child: const Center(
                child: Icon(Icons.smart_toy_outlined, color: Colors.black87),
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
      // Rotate very slightly for hand-drawn feel
      child: Transform.rotate(
        angle: -0.01,
        child: Container(
          height: 60,
          decoration: _sketchDeco(color: Colors.white, radius: 16),
          child: Row(
            children: [
              const SizedBox(width: 16),
              const Icon(Icons.search, color: Colors.black54),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Search lectures, notes, or tags...",
                  style: GoogleFonts.comicNeue(
                    color: Colors.black54,
                    fontSize: 16,
                  ),
                ),
              ),
              const Icon(Icons.edit_outlined, color: Colors.black54),
              const SizedBox(width: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Transform.rotate(
              angle: 0.02,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: _sketchDeco(
                  color: const Color(0xFFD5F5E3),
                  radius: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Study Streak",
                          style: GoogleFonts.comicNeue(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Icon(
                          Icons.local_fire_department_outlined,
                          color: Colors.black54,
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "$studyStreak",
                          style: GoogleFonts.comicNeue(
                            color: Colors.black,
                            fontSize: 32,
                            height: 1.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            "days",
                            style: GoogleFonts.comicNeue(
                              color: Colors.black87,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Transform.rotate(
              angle: -0.02,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: _sketchDeco(
                  color: const Color(0xFFD6EAF8),
                  radius: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Tasks Due",
                          style: GoogleFonts.comicNeue(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Icon(
                          Icons.check_box_outlined,
                          color: Colors.black54,
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "$tasksDue",
                          style: GoogleFonts.comicNeue(
                            color: Colors.black,
                            fontSize: 32,
                            height: 1.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            "pending",
                            style: GoogleFonts.comicNeue(
                              color: Colors.black87,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjects() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Subjects",
                style: GoogleFonts.comicNeue(
                  color: Colors.black87,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "View all",
                    style: GoogleFonts.comicNeue(
                      color: const Color(0xFFE74C3C),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Squiggly line imitation
                  Container(
                    width: 50,
                    height: 2,
                    margin: const EdgeInsets.only(top: 2),
                    color: const Color(0xFFE74C3C),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 46,
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
                  margin: const EdgeInsets.only(
                    right: 16,
                    bottom: 4,
                  ), // bottom margin for shadow
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: _sketchDeco(
                    color: isActive ? const Color(0xFFFADBD8) : Colors.white,
                    radius: 8,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    subject,
                    style: GoogleFonts.comicNeue(
                      color: isActive ? Colors.black : Colors.black87,
                      fontSize: 16,
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
        "Recent Lectures",
        style: GoogleFonts.comicNeue(
          color: Colors.black87,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLectureItem(Map<String, dynamic> lecture, int index) {
    // Determine color block based on index
    final colors = [
      const Color(0xFFD6EAF8), // Light blue
      const Color(0xFFFADBD8), // Pink
      const Color(0xFFD5F5E3), // Mint
      const Color(0xFFFCF3CF), // Yellow
    ];
    final blockColor = colors[index % colors.length];

    // Rotate alternating items slightly differently
    final angle = index % 2 == 0 ? 0.015 : -0.01;

    // Just fake duration for styling
    final mins = 45 + (lecture['id'].toString().length % 30);
    // Fake date
    final String dateStr = index == 0
        ? "Today"
        : (index == 1 ? "Yesterday" : "Oct 24");

    final bool isReview =
        index == 1; // force Review tag on second item to match mockup
    final String statusTag = isReview ? "REVIEW" : "PROCESSED";
    final Color tagColor = isReview
        ? const Color(0xFFD6EAF8)
        : const Color(0xFFD5F5E3);

    return GestureDetector(
      onTap: () => onLectureTap(lecture['id'].toString()),
      child: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
        child: Transform.rotate(
          angle: angle,
          child: Container(
            decoration: _sketchDeco(color: Colors.white, radius: 12),
            child: Row(
              children: [
                // Colored left block
                Container(
                  margin: const EdgeInsets.all(16),
                  width: 50,
                  height: 50,
                  decoration: _sketchDeco(color: blockColor, radius: 8),
                  child: _getSketchIcon(lecture['id'].toString()),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                (lecture['title'] ?? 'Lecture Note').toString(),
                                style: GoogleFonts.comicNeue(
                                  color: Colors.black,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(right: 16),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: _sketchDeco(
                                color: tagColor,
                                radius: 4,
                              ),
                              child: Text(
                                statusTag,
                                style: GoogleFonts.comicNeue(
                                  color: Colors.black,
                                  fontSize: 12,
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
                              Icons.schedule_outlined,
                              color: Colors.black54,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "$mins mins",
                              style: GoogleFonts.comicNeue(
                                color: Colors.black54,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: Colors.black26,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              dateStr, // Just a tech sounding string instead of actual date
                              style: GoogleFonts.comicNeue(
                                color: Colors.black54,
                                fontSize: 13,
                              ),
                            ),
                            const Spacer(),
                            if (index ==
                                2) // Match the record mic button on the 3rd one from the mockup
                              Container(
                                margin: const EdgeInsets.only(right: 16),
                                padding: const EdgeInsets.all(12),
                                decoration: _sketchDeco(
                                  color: const Color(0xFFF5B7B1),
                                  radius: 8,
                                ),
                                child: const Icon(
                                  Icons.mic_none,
                                  color: Colors.black,
                                ),
                              )
                            else
                              const Padding(
                                padding: EdgeInsets.only(right: 16),
                                child: Icon(
                                  Icons.arrow_forward_outlined,
                                  color: Colors.black54,
                                  size: 20,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _getSketchIcon(String id) {
    final icons = [
      Icons.science_outlined,
      Icons.history_edu_outlined,
      Icons.functions_outlined,
      Icons.biotech_outlined,
    ];
    return Icon(icons[id.hashCode % icons.length], color: Colors.black54);
  }
}
