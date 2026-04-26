import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/data_models.dart';
import '../../services/gamification_service.dart';
import '../../theme/crimson_helpers.dart';
import 'subject_detail_page.dart';
import '../leaderboard_page.dart';
import '../store_page.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final _supabase = Supabase.instance.client;

  List<Subject> _subjects = [];
  bool _loading = true;
  Map<String, dynamic>? _profile;
  final _gamification = GamificationService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([_loadSubjects(), _loadProfile()]);
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _gamification.fetchProfile();
      if (mounted) setState(() => _profile = profile);
    } catch (e) {
      debugPrint('❌ Failed to load profile: $e');
    }
  }

  Future<void> _loadSubjects() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final res = await _supabase
          .from('subjects')
          .select('id, name, created_at')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _subjects = (res as List).map((e) => Subject.fromJson(e)).toList();
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ NotesPage load error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addSubject(String name) async {
    final user = _supabase.auth.currentUser;
    if (user == null || name.trim().isEmpty) return;
    try {
      final res = await _supabase
          .from('subjects')
          .insert({'name': name.trim(), 'user_id': user.id})
          .select()
          .single();
      if (mounted) {
        setState(() => _subjects.insert(0, Subject.fromJson(res)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add subject: $e')));
      }
    }
  }

  Future<void> _deleteSubject(String id) async {
    try {
      await _supabase.from('subjects').delete().eq('id', id);
      if (mounted) {
        setState(() => _subjects.removeWhere((s) => s.id == id));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
      }
    }
  }

  void _showAddDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CrimsonHelpers.isCrimson(context) ? 0 : 20)),
        title: const Text('Add Subject'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'e.g. Machine Learning',
            hintStyle: TextStyle(color: Colors.grey[500]),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[700]!),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).primaryColor),
            ),
          ),
          onSubmitted: (v) {
            Navigator.pop(context);
            _addSubject(v);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _addSubject(controller.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // Color palette for subject cards
  static const _colors = [
    Color(0xFF1E3A5F),
    Color(0xFF2D1B4E),
    Color(0xFF1B3A2D),
    Color(0xFF3A2010),
    Color(0xFF1A2A3A),
    Color(0xFF3A1A2A),
  ];

  static const _icons = [
    Icons.science,
    Icons.history_edu,
    Icons.functions,
    Icons.code,
    Icons.psychology,
    Icons.language,
    Icons.menu_book,
    Icons.biotech,
    Icons.calculate,
    Icons.architecture,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'My Subjects',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _loading = true);
              _loadData();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: _showAddDialog,
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildWalletCard(),
                  const SizedBox(height: 24),
                  Text(
                    "Your Subjects",
                    style: TextStyle(
                      color:
                          Theme.of(context).textTheme.titleLarge?.color ??
                          Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_subjects.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.folder_open,
                              color: Colors.grey[600],
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No subjects yet.\nTap + to add your first one!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey[500],
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...List.generate(_subjects.length, (index) {
                      final subject = _subjects[index];
                      final color = _colors[index % _colors.length];
                      final icon = _icons[index % _icons.length];

                      return Dismissible(
                        key: Key(subject.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          decoration: BoxDecoration(
                            color: Colors.red[900],
                            borderRadius: BorderRadius.circular(CrimsonHelpers.isCrimson(context) ? 0 : 20),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) => _deleteSubject(subject.id),
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SubjectDetailPage(
                                subject: subject,
                                baseColor: color,
                              ),
                            ),
                          ).then((_) => _loadData()),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: CrimsonHelpers.isCrimson(context) ? CrimsonHelpers.crimsonCard : color,
                              borderRadius: BorderRadius.circular(CrimsonHelpers.isCrimson(context) ? 0 : 20),
                              border: Border.all(
                                color: CrimsonHelpers.isCrimson(context) ? CrimsonHelpers.crimsonBorder : Colors.white.withOpacity(0.06),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  height: 48,
                                  width: 48,
                                  decoration: BoxDecoration(
                                    color: CrimsonHelpers.isCrimson(context) ? CrimsonHelpers.crimsonRed.withOpacity(0.2) : Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(CrimsonHelpers.isCrimson(context) ? 0 : 14),
                                  ),
                                  child: Icon(
                                    icon,
                                    color: Colors.white70,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    subject.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  color: Colors.white30,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }

  Widget _buildWalletCard() {
    final coins = _profile?['lumen_coins'] ?? 0;
    final xp = _profile?['xp'] ?? 0;
    final rank = _profile?['rank_title'] ?? 'Novice Scholar';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LeaderboardPage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: CrimsonHelpers.isCrimson(context)
                ? [const Color(0xFF2A0A0A), const Color(0xFF4A1010)]
                : [const Color(0xFF2A1B54), const Color(0xFF4A2B8A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(CrimsonHelpers.isCrimson(context) ? 0 : 24),
          boxShadow: [
            BoxShadow(
              color: (CrimsonHelpers.isCrimson(context) ? CrimsonHelpers.crimsonRed : Colors.purpleAccent).withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "LUMEN WALLET",
                      style: TextStyle(
                        color: CrimsonHelpers.isCrimson(context) ? CrimsonHelpers.crimsonRed : Colors.purpleAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Icon(Icons.stars, color: Colors.amber, size: 32),
                        const SizedBox(width: 8),
                        Text(
                          "$coins",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          "Coins",
                          style: TextStyle(color: Colors.amber, fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: (CrimsonHelpers.isCrimson(context) ? CrimsonHelpers.crimsonRed : Colors.purpleAccent).withOpacity(0.5),
                    ),
                  ),
                  child: Text(
                    rank,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: (xp % 100) / 100.0,
              backgroundColor: Colors.black26,
              valueColor: AlwaysStoppedAnimation<Color>(
                CrimsonHelpers.isCrimson(context) ? CrimsonHelpers.crimsonRed : Colors.purpleAccent,
              ),
              borderRadius: BorderRadius.circular(4),
              minHeight: 6,
            ),
            const SizedBox(height: 8),
            Text(
              "$xp XP Total · ${100 - (xp % 100)} XP to next rank",
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Tap to view Global Leaderboard",
                  style: TextStyle(
                    color: CrimsonHelpers.isCrimson(context) ? CrimsonHelpers.crimsonRed : Colors.purpleAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.leaderboard, color: CrimsonHelpers.isCrimson(context) ? CrimsonHelpers.crimsonRed : Colors.purpleAccent, size: 14),
              ],
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StorePage()),
                ).then((_) => _loadData()); // Refresh coins when coming back
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Visit Avatar Marketplace",
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.shopping_cart, color: Colors.amber, size: 14),
                ],
              ),
            ),
          ],
        ), // end Column
      ), // end Container
    ); // end GestureDetector
  }
}
