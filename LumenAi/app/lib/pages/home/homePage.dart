import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/data_models.dart';
import '../notes/results_page.dart';
import '../profile/profilePage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _supabase = Supabase.instance.client;

  // User info
  String _userName = '';
  String? _avatarUrl;

  // Data
  List<Map<String, dynamic>> _lectures = [];
  List<String> _subjects = [];
  String _selectedSubject = 'All';

  // Stats
  int _studyStreak = 0;
  int _tasksDue = 0;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    final userId = user.id;

    try {
      // Run all queries in parallel
      final results = await Future.wait([
        _supabase
            .from('profiles')
            .select('full_name, avatar_url')
            .eq('id', userId)
            .maybeSingle(),
        _supabase
            .from('lectures')
            .select('id, title, summary, created_at, raw_analysis')
            .eq('user_id', userId)
            .order('created_at', ascending: false)
            .limit(20),
        _supabase
            .from('subjects')
            .select('name')
            .eq('user_id', userId)
            .limit(10),
        _supabase.from('extracted_tasks').select('id').limit(50),
      ]);

      final profile = results[0] as Map<String, dynamic>?;
      final lectures = results[1] as List<dynamic>;
      final subjects = results[2] as List<dynamic>;
      final tasks = results[3] as List<dynamic>;

      // Compute study streak from lectures.created_at
      final streak = _computeStreak(lectures);
      // Tasks due = total extracted tasks from lectures
      final pending = tasks.length;

      if (mounted) {
        setState(() {
          _userName =
              profile?['full_name'] ??
              user.userMetadata?['full_name'] ??
              user.email?.split('@').first ??
              'Student';
          _avatarUrl = profile?['avatar_url'];
          _lectures = List<Map<String, dynamic>>.from(lectures);
          _subjects = ['All', ...subjects.map((s) => s['name'].toString())];
          _studyStreak = streak;
          _tasksDue = pending;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ HomePage load error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  int _computeStreak(List<dynamic> lectures) {
    if (lectures.isEmpty) return 0;
    // Get unique days with at least one lecture, sorted descending
    final days =
        lectures
            .map((l) => DateTime.parse(l['created_at']).toLocal())
            .map((d) => DateTime(d.year, d.month, d.day))
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    int streak = 0;
    DateTime expected = todayDate;

    for (final day in days) {
      if (day == expected ||
          day == expected.subtract(const Duration(days: 1))) {
        streak++;
        expected = day.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  List<Map<String, dynamic>> get _filteredLectures {
    if (_selectedSubject == 'All') return _lectures;
    return _lectures.where((l) {
      final raw = l['raw_analysis'] as Map?;
      final topics = raw?['topics'] as List? ?? [];
      return topics.any(
        (t) =>
            t.toString().toLowerCase().contains(_selectedSubject.toLowerCase()),
      );
    }).toList();
  }

  // Pick a consistent color per lecture
  Color _lectureColor(String id) {
    final colors = [
      Colors.purple[300]!,
      Colors.blue[400]!,
      Colors.teal[400]!,
      Colors.orange[400]!,
      Colors.pink[400]!,
      Colors.indigo[400]!,
    ];
    final idx = min(
      id.codeUnits.fold(0, (a, b) => a + b) % colors.length,
      colors.length - 1,
    );
    return colors[idx];
  }

  IconData _lectureIcon(Map<String, dynamic> lecture) {
    final raw = lecture['raw_analysis'] as Map?;
    final topics = (raw?['topics'] as List?)?.join(' ').toLowerCase() ?? '';
    if (topics.contains('math') ||
        topics.contains('calculus') ||
        topics.contains('algebra')) {
      return Icons.functions;
    } else if (topics.contains('biology') || topics.contains('science')) {
      return Icons.science;
    } else if (topics.contains('history')) {
      return Icons.history_edu;
    } else if (topics.contains('code') ||
        topics.contains('program') ||
        topics.contains('python')) {
      return Icons.code;
    }
    return Icons.menu_book;
  }

  String _timeAgo(String isoDate) {
    final date = DateTime.parse(isoDate).toLocal();
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${(diff.inDays / 7).floor()} weeks ago';
  }

  Future<void> _openLecture(Map<String, dynamic> lecture) async {
    final raw = lecture['raw_analysis'];
    if (raw == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No analysis data available for this lecture.'),
        ),
      );
      return;
    }
    try {
      final result = AnalysisResult.fromJson(
        raw is Map<String, dynamic> ? raw : Map<String, dynamic>.from(raw),
      );
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AnalysisResultScreen(result: result),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load analysis: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        toolbarHeight: 80,
        leadingWidth: 80,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Center(
            child: Stack(
              children: [
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const Profilepage()),
                  ),
                  child: CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.blueAccent.withOpacity(0.3),
                    backgroundImage:
                        _avatarUrl != null && _avatarUrl!.isNotEmpty
                        ? NetworkImage(_avatarUrl!)
                        : null,
                    child: _avatarUrl == null || _avatarUrl!.isEmpty
                        ? Text(
                            _userName.isNotEmpty
                                ? _userName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                ),
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
              'DASHBOARD',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                letterSpacing: 1.2,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              _loading
                  ? 'Welcome back!'
                  : 'Welcome back, ${_userName.split(' ').first}',
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
                icon: const Icon(Icons.refresh_outlined),
                onPressed: () {
                  setState(() => _loading = true);
                  _loadData();
                },
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SafeArea(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSearchBar(),
                      const SizedBox(height: 20),
                      _buildStatsRow(),
                      const SizedBox(height: 24),
                      _buildSubjectsSection(),
                      const SizedBox(height: 24),
                      _buildRecentLecturesSection(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A2036),
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search lectures...',
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
        ),
        onChanged: (query) {
          // Local filter on title
          setState(() {});
        },
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatsCard(
            title: 'Study Streak',
            count: '$_studyStreak',
            unit: 'days',
            icon: Icons.local_fire_department,
            iconColor: Colors.orange,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatsCard(
            title: 'Tasks Due',
            count: '$_tasksDue',
            unit: 'pending',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Subjects',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(onPressed: () {}, child: const Text('View all')),
          ],
        ),
        const SizedBox(height: 12),
        _subjects.isEmpty
            ? Text(
                'No subjects yet.',
                style: TextStyle(color: Colors.grey[500]),
              )
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _subjects.map((subject) {
                    final isActive = _selectedSubject == subject;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedSubject = subject),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? const Color(0xFF1E88E5)
                                : const Color(0xFF1A2036),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            subject,
                            style: TextStyle(
                              color: isActive ? Colors.white : Colors.grey[400],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
      ],
    );
  }

  Widget _buildRecentLecturesSection() {
    final toDisplay = _filteredLectures;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Lectures',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '${_lectures.length} total',
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (toDisplay.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(
                    Icons.school_outlined,
                    color: Colors.grey[600],
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _lectures.isEmpty
                        ? 'No lectures yet.\nUpload your first lecture from the Notes tab!'
                        : 'No lectures match this subject.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[500], height: 1.5),
                  ),
                ],
              ),
            ),
          )
        else
          ...toDisplay.map((lecture) => _buildLectureCard(lecture)),
      ],
    );
  }

  Widget _buildLectureCard(Map<String, dynamic> lecture) {
    final id = lecture['id']?.toString() ?? '';
    final title = lecture['title'] ?? 'Untitled Lecture';
    final createdAt = lecture['created_at'] ?? DateTime.now().toIso8601String();
    final color = _lectureColor(id);
    final icon = _lectureIcon(lecture);
    final timeAgo = _timeAgo(createdAt);
    final hasAnalysis = lecture['raw_analysis'] != null;

    return GestureDetector(
      onTap: () => _openLecture(lecture),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2036),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.04)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withOpacity(0.25),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeAgo,
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ],
              ),
            ),
            if (hasAnalysis)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'PROCESSED',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
