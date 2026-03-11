import 'package:flutter/material.dart';
import '../../models/data_models.dart';
import '../../services/api_service.dart';
import 'file_preview_page.dart';
import 'input_type_page.dart';
import 'results_page.dart';
import '../spatial_canvas_page.dart';

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
  List<Unit> _units = [];

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
      final units = await _apiService.getUnits(widget.subject.id);
      if (mounted) {
        setState(() {
          _lectures = lectures;
          _syllabi = syllabi;
          _units = units;
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
        backgroundColor: Theme.of(context).cardColor,
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

  /// Shows a bottom sheet with AI-powered unit suggestion and accept/reject actions.
  void _showAutoMapSheet(Map<String, dynamic> lecture) async {
    final lectureId = lecture['id'].toString();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return _AutoMapSheetContent(
              lectureId: lectureId,
              units: _units,
              apiService: _apiService,
              onMapped: () {
                Navigator.pop(ctx);
                _loadData();
              },
            );
          },
        );
      },
    );
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
                  color: Theme.of(context).cardColor,
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
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isLecture &&
                                  item['unit_id'] == null &&
                                  item['is_analyzed'] == true)
                                GestureDetector(
                                  onTap: () => _showAutoMapSheet(item),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.amber.withOpacity(0.4),
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.auto_fix_high,
                                          color: Colors.amber,
                                          size: 14,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Map',
                                          style: TextStyle(
                                            color: Colors.amber,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
            heroTag: "canvas_btn",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SpatialCanvasPage(
                    subject: widget.subject,
                    baseColor: widget.baseColor,
                  ),
                ),
              );
            },
            backgroundColor: Colors.deepPurple,
            icon: const Icon(Icons.dashboard_customize, color: Colors.white),
            label: const Text('Canvas', style: TextStyle(color: Colors.white)),
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

/// Bottom sheet content for AI-powered auto-mapping
class _AutoMapSheetContent extends StatefulWidget {
  final String lectureId;
  final List<Unit> units;
  final ApiService apiService;
  final VoidCallback onMapped;

  const _AutoMapSheetContent({
    required this.lectureId,
    required this.units,
    required this.apiService,
    required this.onMapped,
  });

  @override
  State<_AutoMapSheetContent> createState() => _AutoMapSheetContentState();
}

class _AutoMapSheetContentState extends State<_AutoMapSheetContent> {
  bool _loading = true;
  bool _applying = false;
  Map<String, dynamic>? _suggestion;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchSuggestion();
  }

  Future<void> _fetchSuggestion() async {
    try {
      final result = await widget.apiService.getAutoMapSuggestion(
        widget.lectureId,
      );
      if (mounted) {
        setState(() {
          _suggestion = result;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _acceptSuggestion() async {
    if (_suggestion == null || _suggestion!['unit_id'] == null) return;
    setState(() => _applying = true);
    try {
      await widget.apiService.applyAutoMap(
        widget.lectureId,
        _suggestion!['unit_id'],
      );
      widget.onMapped();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to apply: $e')));
      }
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  Future<void> _applyManual(String unitId) async {
    setState(() => _applying = true);
    try {
      await widget.apiService.applyAutoMap(widget.lectureId, unitId);
      widget.onMapped();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to apply: $e')));
      }
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Row(
            children: [
              Icon(Icons.auto_fix_high, color: Colors.amber, size: 22),
              SizedBox(width: 10),
              Text(
                'Smart Auto-Map',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'AI analyzes the lecture content and suggests which unit it belongs to.',
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
          ),
          const SizedBox(height: 20),

          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircularProgressIndicator(color: Colors.amber),
                    SizedBox(height: 12),
                    Text(
                      'Analyzing with AI...',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              ),
            )
          else if (_error != null)
            Center(
              child: Text(
                'Error: $_error',
                style: const TextStyle(color: Colors.redAccent),
              ),
            )
          else if (_suggestion == null || _suggestion!['unit_id'] == null)
            Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.help_outline,
                    color: Colors.white38,
                    size: 40,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'No matching unit found.',
                    style: TextStyle(color: Colors.white54, fontSize: 15),
                  ),
                  const SizedBox(height: 16),
                  _buildManualPicker(),
                ],
              ),
            )
          else ...[
            // Suggestion card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.lightbulb,
                        color: Colors.amber,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _suggestion!['unit_name'] ?? 'Unknown Unit',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _buildConfidenceBadge(
                        (_suggestion!['confidence'] as num).toDouble(),
                      ),
                    ],
                  ),
                  if (_suggestion!['reason'] != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _suggestion!['reason'],
                      style: TextStyle(color: Colors.grey[300], fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Dismiss',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _applying ? null : _acceptSuggestion,
                    icon: _applying
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check, size: 18),
                    label: Text(_applying ? 'Applying...' : 'Accept'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildManualPicker(),
          ],
        ],
      ),
    );
  }

  Widget _buildConfidenceBadge(double confidence) {
    final pct = (confidence * 100).toStringAsFixed(0);
    final color = confidence >= 0.8
        ? Colors.greenAccent
        : confidence >= 0.5
        ? Colors.amber
        : Colors.redAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$pct%',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildManualPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Or pick manually:',
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.units.map((unit) {
            return ActionChip(
              label: Text(
                unit.name,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              backgroundColor: Colors.white.withOpacity(0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              onPressed: _applying ? null : () => _applyManual(unit.id),
            );
          }).toList(),
        ),
      ],
    );
  }
}
