import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'input_type_page.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _subjects = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
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
          _subjects = List<Map<String, dynamic>>.from(res);
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
        setState(() => _subjects.insert(0, res));
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
        setState(() => _subjects.removeWhere((s) => s['id'] == id));
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
        backgroundColor: const Color(0xFF1A2036),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.blueAccent),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
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
      backgroundColor: const Color(0xFF0C1223),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C1223),
        elevation: 0,
        title: const Text(
          'My Subjects',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _loading = true);
              _loadSubjects();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSubjects,
              child: _subjects.isEmpty
                  ? Center(
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
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _subjects.length,
                      itemBuilder: (_, index) {
                        final subject = _subjects[index];
                        final name = subject['name'] ?? 'Untitled';
                        final color = _colors[index % _colors.length];
                        final icon = _icons[index % _icons.length];
                        return Dismissible(
                          key: Key(subject['id']),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 24),
                            decoration: BoxDecoration(
                              color: Colors.red[900],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          onDismissed: (_) => _deleteSubject(subject['id']),
                          child: GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => InputTypePage(className: name),
                              ),
                            ).then((_) => _loadSubjects()),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.06),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    height: 48,
                                    width: 48,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(14),
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
                                      name,
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
                      },
                    ),
            ),
    );
  }
}
