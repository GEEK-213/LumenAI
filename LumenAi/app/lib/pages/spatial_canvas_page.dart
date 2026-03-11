import 'dart:math';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/data_models.dart';

/// Infinite Spatial Canvas — pin mind map nodes and flashcards
/// from multiple lectures onto a shared, pannable/zoomable workspace.
class SpatialCanvasPage extends StatefulWidget {
  final Subject subject;
  final Color baseColor;

  const SpatialCanvasPage({
    super.key,
    required this.subject,
    required this.baseColor,
  });

  @override
  State<SpatialCanvasPage> createState() => _SpatialCanvasPageState();
}

class _SpatialCanvasPageState extends State<SpatialCanvasPage> {
  final ApiService _api = ApiService();
  final TransformationController _transformController =
      TransformationController();

  bool _loading = true;
  List<Map<String, dynamic>> _pins = [];
  List<Map<String, dynamic>> _lectures = [];
  bool _drawerOpen = false;
  String? _dragPinId; // Currently being dragged

  // Lecture content cache
  final Map<String, AnalysisResult> _analysisCache = {};

  // Canvas colors for different lectures
  static const _lectureColors = [
    Color(0xFF6C5CE7),
    Color(0xFF0984E3),
    Color(0xFF00B894),
    Color(0xFFFDAA5E),
    Color(0xFFE17055),
    Color(0xFF00CEC9),
    Color(0xFFE84393),
    Color(0xFF55A3F5),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final pins = await _api.getCanvasPins(widget.subject.id);
      final lectures = await _api.getSubjectLectures(widget.subject.id);
      // Filter to analyzed lectures only
      final analyzed = lectures.where((l) => l['is_analyzed'] == true).toList();
      if (mounted) {
        setState(() {
          _pins = pins;
          _lectures = analyzed;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Canvas load error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _colorForLecture(int index) {
    return _lectureColors[index % _lectureColors.length];
  }

  Color _colorFromHex(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return _lectureColors[0];
    }
  }

  Future<void> _addPin(
    Map<String, dynamic> lecture,
    String pinType,
    Map<String, dynamic> content,
    Color color,
  ) async {
    try {
      // Place near center with slight random offset
      final rng = Random();
      final pin = await _api.saveCanvasPin(
        subjectId: widget.subject.id,
        lectureId: lecture['id'].toString(),
        pinType: pinType,
        content: content,
        x: 300 + rng.nextDouble() * 200,
        y: 300 + rng.nextDouble() * 200,
        color: '#${color.value.toRadixString(16).substring(2)}',
      );
      setState(() => _pins.add(pin));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pin: $e')));
      }
    }
  }

  Future<void> _deletePin(String pinId) async {
    try {
      await _api.deleteCanvasPin(pinId);
      setState(() => _pins.removeWhere((p) => p['id'] == pinId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
      }
    }
  }

  Future<void> _updatePosition(String pinId, double x, double y) async {
    // Update locally first for instant feedback
    final idx = _pins.indexWhere((p) => p['id'] == pinId);
    if (idx >= 0) {
      setState(() {
        _pins[idx]['x'] = x;
        _pins[idx]['y'] = y;
      });
    }
    // Persist to Supabase
    try {
      await _api.updatePinPosition(pinId, x, y);
    } catch (e) {
      debugPrint('Failed to save position: $e');
    }
  }

  Future<AnalysisResult?> _getAnalysis(String lectureId) async {
    if (_analysisCache.containsKey(lectureId)) return _analysisCache[lectureId];
    try {
      final result = await _api.getAnalysisResult(lectureId);
      if (result != null) _analysisCache[lectureId] = result;
      return result;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050B18),
      body: SafeArea(
        child: Stack(
          children: [
            // Main canvas
            _loading
                ? const Center(child: CircularProgressIndicator())
                : _buildCanvas(),

            // Header
            _buildHeader(),

            // Content drawer
            if (_drawerOpen) _buildDrawer(),

            // Pin count badge
            if (!_loading)
              Positioned(
                bottom: 20,
                left: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2746),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Text(
                    '${_pins.length} pins',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => _drawerOpen = !_drawerOpen),
        backgroundColor: widget.baseColor,
        child: Icon(
          _drawerOpen ? Icons.close : Icons.add_circle_outline,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 4, 16, 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF050B18),
              const Color(0xFF050B18).withOpacity(0.0),
            ],
          ),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.white70),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.dashboard_customize,
              color: Colors.white70,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${widget.subject.name} Canvas',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh, color: Colors.white38, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCanvas() {
    return InteractiveViewer(
      transformationController: _transformController,
      boundaryMargin: const EdgeInsets.all(double.infinity),
      minScale: 0.1,
      maxScale: 4.0,
      child: SizedBox(
        width: 3000,
        height: 3000,
        child: Stack(
          children: [
            // Grid background
            CustomPaint(size: const Size(3000, 3000), painter: _GridPainter()),
            // Pinned items
            ..._pins.map((pin) => _buildPinWidget(pin)),
          ],
        ),
      ),
    );
  }

  Widget _buildPinWidget(Map<String, dynamic> pin) {
    final x = (pin['x'] as num).toDouble();
    final y = (pin['y'] as num).toDouble();
    final pinType = pin['pin_type'] as String;
    final content = pin['content'] as Map<String, dynamic>? ?? {};
    final color = _colorFromHex(pin['color'] ?? '#6C5CE7');
    final pinId = pin['id'].toString();

    return Positioned(
      left: x,
      top: y,
      child: GestureDetector(
        onPanStart: (_) => _dragPinId = pinId,
        onPanUpdate: (details) {
          if (_dragPinId == pinId) {
            final scale = _transformController.value.getMaxScaleOnAxis();
            setState(() {
              final idx = _pins.indexWhere((p) => p['id'] == pinId);
              if (idx >= 0) {
                _pins[idx]['x'] =
                    ((_pins[idx]['x'] as num).toDouble()) +
                    details.delta.dx / scale;
                _pins[idx]['y'] =
                    ((_pins[idx]['y'] as num).toDouble()) +
                    details.delta.dy / scale;
              }
            });
          }
        },
        onPanEnd: (_) {
          if (_dragPinId == pinId) {
            final idx = _pins.indexWhere((p) => p['id'] == pinId);
            if (idx >= 0) {
              _updatePosition(
                pinId,
                (_pins[idx]['x'] as num).toDouble(),
                (_pins[idx]['y'] as num).toDouble(),
              );
            }
            _dragPinId = null;
          }
        },
        onLongPress: () => _showPinActions(pin),
        child: pinType == 'flashcard'
            ? _buildFlashcardPin(content, color)
            : _buildMindMapPin(content, color),
      ),
    );
  }

  Widget _buildMindMapPin(Map<String, dynamic> content, Color color) {
    final label = content['label'] ?? 'Node';
    return Container(
      width: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bubble_chart, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFlashcardPin(Map<String, dynamic> content, Color color) {
    final front = content['front'] ?? 'Q';
    final back = content['back'] ?? 'A';
    return Container(
      width: 200,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2746),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.style, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                'Flashcard',
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white12, height: 16),
          Text(
            front,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            back,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showPinActions(Map<String, dynamic> pin) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: Colors.redAccent,
              ),
              title: const Text(
                'Remove from canvas',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _deletePin(pin['id'].toString());
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Positioned(
      right: 0,
      top: 50,
      bottom: 80,
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          color: const Color(0xFF0D1126),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            bottomLeft: Radius.circular(20),
          ),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drawer header
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Pin Content',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Tap items to pin them to the canvas',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ),
            const SizedBox(height: 12),
            const Divider(color: Colors.white10, height: 1),
            // Lecture list with content
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _lectures.length,
                itemBuilder: (_, i) => _buildLectureSection(_lectures[i], i),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLectureSection(Map<String, dynamic> lecture, int index) {
    final title = lecture['title']?.toString() ?? 'Untitled';
    final lectureId = lecture['id'].toString();
    final color = _colorForLecture(index);

    return ExpansionTile(
      leading: CircleAvatar(
        radius: 14,
        backgroundColor: color.withOpacity(0.2),
        child: Icon(Icons.auto_awesome, color: color, size: 14),
      ),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      iconColor: Colors.white38,
      collapsedIconColor: Colors.white24,
      children: [
        FutureBuilder<AnalysisResult?>(
          future: _getAnalysis(lectureId),
          builder: (_, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }
            final result = snapshot.data;
            if (result == null) {
              return const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'No analysis data',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mind map nodes
                if (result.mindMap != null &&
                    result.mindMap!.nodes.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 16, top: 4),
                    child: Text(
                      'Mind Map Nodes',
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    ),
                  ),
                  ...result.mindMap!.nodes.take(8).map((node) {
                    final label = node['label']?.toString() ?? '';
                    return ListTile(
                      dense: true,
                      leading: Icon(Icons.bubble_chart, color: color, size: 16),
                      title: Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => _addPin(lecture, 'mind_map_node', {
                        'label': label,
                      }, color),
                    );
                  }),
                ],
                // Flashcards
                if (result.flashcards.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 16, top: 8),
                    child: Text(
                      'Flashcards',
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    ),
                  ),
                  ...result.flashcards.take(6).map((fc) {
                    return ListTile(
                      dense: true,
                      leading: Icon(Icons.style, color: color, size: 16),
                      title: Text(
                        fc.front,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => _addPin(lecture, 'flashcard', {
                        'front': fc.front,
                        'back': fc.back,
                      }, color),
                    );
                  }),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Draws subtle grid lines on the canvas background
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1;

    const spacing = 50.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
