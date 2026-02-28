import 'package:flutter/material.dart';
import '../../models/data_models.dart';
import '../../services/api_service.dart';
import 'file_preview_page.dart';
import 'input_type_page.dart';
import 'results_page.dart';

class SubjectDetailPage extends StatefulWidget {
  final Subject subject;
  final Color baseColor;

  const SubjectDetailPage({
    super.key,
    required this.subject,
    required this.baseColor,
  });

  @override
  State<SubjectDetailPage> createState() => _SubjectDetailPageState();
}

class _SubjectDetailPageState extends State<SubjectDetailPage>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;

  bool _loading = true;
  List<Map<String, dynamic>> _lectures = [];
  List<Map<String, dynamic>> _syllabi = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final lectures = await _apiService.getSubjectLectures(widget.subject.id);
      final syllabi = await _apiService.getSubjectSyllabi(widget.subject.id);
      if (mounted) {
        setState(() {
          _lectures = lectures;
          _syllabi = syllabi;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ SubjectDetailPage load error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _syncClassroom() async {
    setState(() => _loading = true);
    try {
      final user = _apiService.supabase.auth.currentUser;
      if (user != null) {
        await _apiService.syncClassroomSubject(widget.subject.id, user.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Classroom sync complete!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to sync: $e')));
      }
    } finally {
      await _loadData();
    }
  }

  void _openFilePreview(Map<String, dynamic> lecture) async {
    final driveFileId = lecture['drive_file_id'];
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FilePreviewPage(
          lectureId: lecture['id'].toString(),
          title: lecture['title']?.toString() ?? 'Untitled',
          driveFileId: driveFileId?.toString(),
          isAnalyzed: lecture['is_analyzed'] == true,
        ),
      ),
    );
    // If the file was analyzed inside the preview page, reload and open results
    if (result == true && mounted) {
      await _loadData();
      final updatedLectures = await _apiService.getSubjectLectures(
        widget.subject.id,
      );
      final updated = updatedLectures.firstWhere(
        (l) => l['id'].toString() == lecture['id'].toString(),
        orElse: () => lecture,
      );
      _openLecture(updated);
    } else {
      await _loadData();
    }
  }

  Future<void> _deleteItem(String id, bool isLecture) async {
    try {
      if (isLecture) {
        await _apiService.deleteLecture(id);
        setState(() => _lectures.removeWhere((l) => l['id'] == id));
      } else {
        await _apiService.deleteSyllabus(id);
        setState(() => _syllabi.removeWhere((s) => s['id'] == id));
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${isLecture ? "Lecture" : "Syllabus"} deleted'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
      }
    }
  }

  void _showRenameDialog(String id, String currentTitle, bool isLecture) {
    final controller = TextEditingController(text: currentTitle);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A2036),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Rename ${isLecture ? "Lecture" : "Syllabus"}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'New Title',
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
            _renameItem(id, v, isLecture);
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
              _renameItem(id, controller.text, isLecture);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _renameItem(String id, String newTitle, bool isLecture) async {
    if (newTitle.trim().isEmpty) return;
    try {
      if (isLecture) {
        await _apiService.renameLecture(id, newTitle.trim());
      } else {
        await _apiService.renameSyllabus(id, newTitle.trim());
      }
      await _loadData(); // Re-fetch to update the UI
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to rename: $e')));
      }
    }
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
      // First get full analysis with FC and Quiz
      final fullResult = await _apiService.getAnalysisResult(lecture['id']);
      if (fullResult == null) throw Exception("Could not fetch full result.");

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AnalysisResultScreen(result: fullResult),
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

  String _formatDate(String isoString) {
    if (isoString.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return "${dt.day}/${dt.month}/${dt.year}";
    } catch (e) {
      return '';
    }
  }

  Widget _buildList(List<Map<String, dynamic>> items, bool isLecture) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isLecture ? Icons.mic_none : Icons.picture_as_pdf,
              color: Colors.grey[600],
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'No ${isLecture ? "lectures" : "syllabi"} yet.\nTap the + button to add material.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], height: 1.6),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final id = item['id'].toString();
          final title = item['title']?.toString() ?? 'Untitled';
          final date = _formatDate(item['created_at'].toString());

          return Dismissible(
            key: Key(id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.red[900],
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (_) => _deleteItem(id, isLecture),
            child: GestureDetector(
              onTap: isLecture
                  ? () {
                      // Only go to FilePreviewPage if it's from Classroom (has drive_file_id)
                      // AND hasn't been analyzed yet
                      final hasdriveId = item['drive_file_id'] != null;
                      final isAnalyzed = item['is_analyzed'] == true;

                      if (isAnalyzed || !hasdriveId) {
                        _openLecture(item);
                      } else {
                        _openFilePreview(item);
                      }
                    }
                  : null,
              onLongPress: () => _showRenameDialog(id, title, isLecture),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2036),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: widget.baseColor.withOpacity(0.2),
                      child: Icon(
                        isLecture
                            ? (item['is_analyzed'] == true
                                  ? Icons.auto_awesome
                                  : Icons.description)
                            : Icons.article,
                        color: isLecture
                            ? (item['is_analyzed'] == true
                                  ? widget.baseColor
                                  : Colors.grey[400])
                            : widget.baseColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            date,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.grey[400], size: 20),
                      onPressed: () => _showRenameDialog(id, title, isLecture),
                    ),
                    if (isLecture &&
                        (item['is_analyzed'] == true ||
                            item['drive_file_id'] == null))
                      const Icon(Icons.chevron_right, color: Colors.white30),
                    if (isLecture &&
                        item['is_analyzed'] != true &&
                        item['drive_file_id'] != null)
                      Icon(
                        Icons.visibility,
                        color: Colors.amber[600],
                        size: 22,
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C1223),
      appBar: AppBar(
        title: Text(widget.subject.name),
        backgroundColor: widget.baseColor,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: "Lectures"),
            Tab(text: "Syllabi"),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: "sync_btn",
            onPressed: _syncClassroom,
            backgroundColor: Colors.amber[800],
            icon: const Icon(Icons.cloud_sync, color: Colors.white),
            label: const Text(
              'Pull from Classroom',
              style: TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: "add_btn",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => InputTypePage(className: widget.subject.name),
                ),
              ).then((_) => _loadData()); // Reload when coming back
            },
            backgroundColor: widget.baseColor,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Add Material',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildList(_lectures, true),
                _buildList(_syllabi, false),
              ],
            ),
    );
  }
}
