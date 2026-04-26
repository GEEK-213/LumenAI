import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Interactive visual mind map widget using a radial tree layout.
/// Nodes are rendered as colored bubbles with labels, connected by curved edges.
/// Supports pan and zoom via InteractiveViewer.
///
/// Handles node IDs as dynamic (int or String from AI) by normalizing to String.
class MindMapView extends StatefulWidget {
  final List<Map<String, dynamic>> nodes;
  final List<Map<String, dynamic>> edges;

  const MindMapView({super.key, required this.nodes, required this.edges});

  @override
  State<MindMapView> createState() => _MindMapViewState();
}

class _MindMapViewState extends State<MindMapView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  String? _selectedNodeId;
  final TransformationController _transformController =
      TransformationController();

  // Positions keyed by String IDs (normalized from int/String)
  final Map<String, Offset> _positions = {};

  // Color palette for nodes
  static const _nodeColors = [
    Color(0xFF6C5CE7), // purple
    Color(0xFF0984E3), // blue
    Color(0xFF00B894), // green
    Color(0xFFFDAA5E), // amber
    Color(0xFFE17055), // coral
    Color(0xFF00CEC9), // teal
    Color(0xFFE84393), // pink
    Color(0xFF55A3F5), // sky
  ];

  /// Normalize any ID to String for safe comparison
  static String _toId(dynamic val) => val?.toString() ?? '';

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);

    _computeLayout();

    // Automatically center view on the 2000x2000 generation origin
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _centerOnNode(const Offset(2000, 2000), defaultScale: 0.8);
      }
    });

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _transformController.dispose();
    super.dispose();
  }

  /// Get connected node labels for a given node ID
  List<String> _getConnectedLabels(String nodeId) {
    final connected = <String>[];
    for (var edge in widget.edges) {
      final from = _toId(edge['from']);
      final to = _toId(edge['to']);
      if (from == nodeId || to == nodeId) {
        final otherId = from == nodeId ? to : from;
        final otherNode = widget.nodes.firstWhere(
          (n) => _toId(n['id']) == otherId,
          orElse: () => {'label': '?'},
        );
        connected.add(otherNode['label']?.toString() ?? '?');
      }
    }
    return connected;
  }

  /// Show detail bottom sheet for a node
  void _showNodeDetail(String label, Color color, int index) {
    final nodeId = _toId(widget.nodes[index]['id']);
    final connected = _getConnectedLabels(nodeId);

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (connected.isNotEmpty) ...[
              const Text(
                "Connected Topics:",
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: connected
                    .map(
                      (c) => Chip(
                        label: Text(
                          c,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        backgroundColor: color.withOpacity(0.2),
                        side: BorderSide(color: color.withOpacity(0.4)),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Show color legend
  void _showLegend() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Topic Legend",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: widget.nodes.asMap().entries.map((entry) {
                      final color = _getNodeColor(entry.key);
                      final label = entry.value['label']?.toString() ?? '?';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: color,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                label,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  /// Double-tap to center view on a node
  void _centerOnNode(Offset pos, {double defaultScale = 1.0}) {
    final screenSize = MediaQuery.of(context).size;
    final dx = screenSize.width / 2 - pos.dx * defaultScale;
    final dy = screenSize.height / 2 - pos.dy * defaultScale;
    _transformController.value = Matrix4.identity()
      ..translate(dx, dy)
      ..scale(defaultScale);
  }

  void _showNodeDefinition(Map<String, dynamic> node, Color color) {
    final label = node['label']?.toString() ?? '?';
    // Use definition from AI payload if available, else placeholder
    final description =
        node['definition']?.toString() ??
        node['description']?.toString() ??
        'Detailed definition for "$label" will appear here.';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2746),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.hub, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          description,
          style: const TextStyle(
            color: Colors.white70,
            height: 1.5,
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Close',
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  void _computeLayout() {
    final nodes = widget.nodes;
    final edges = widget.edges;
    if (nodes.isEmpty) return;

    final toSet = edges.map((e) => _toId(e['to'])).toSet();

    // Find all independent roots
    final List<String> roots = [];
    for (var n in nodes) {
      final nId = _toId(n['id']);
      if (!toSet.contains(nId)) {
        roots.add(nId);
      }
    }
    if (roots.isEmpty) {
      roots.add(_toId(nodes.first['id']));
    }

    final Map<String, List<String>> children = {};
    for (var e in edges) {
      final from = _toId(e['from']);
      final to = _toId(e['to']);
      children.putIfAbsent(from, () => []);
      children[from]!.add(to);
    }

    const double baseY = 2000; // Use a more sensible center instead of deep 400
    // Spread roots horizontally if there are multiple unconnected trees
    final double rootSpreadX =
        500.0; // Scaled down to prevent flying off screen
    final double startX = 2000.0 - ((roots.length - 1) * rootSpreadX) / 2;

    for (int i = 0; i < roots.length; i++) {
      final rId = roots[i];
      final cx = startX + (i * rootSpreadX);
      _positions[rId] = Offset(cx, baseY);
      // Sweeping 360 degrees, but starting with much safer radius
      _layoutChildren(rId, children, cx, baseY, 0, 2 * math.pi, 160, 1);
    }

    // Fallback for floating nodes that weren't caught
    int floatingIndex = 0;
    for (var n in nodes) {
      final nId = _toId(n['id']);
      if (!_positions.containsKey(nId)) {
        _positions[nId] = Offset(startX + (floatingIndex * 120), baseY + 200);
        floatingIndex++;
      }
    }
  }

  void _layoutChildren(
    String nodeId,
    Map<String, List<String>> children,
    double cx,
    double cy,
    double startAngle,
    double sweep,
    double radius,
    int depth,
  ) {
    final kids = children[nodeId] ?? [];
    if (kids.isEmpty) return;

    // Distribute children evenly across the sweep angle
    final angleStep = sweep / kids.length;

    for (int i = 0; i < kids.length; i++) {
      // Calculate angle offset to prevent harsh stacking
      final angle = startAngle + angleStep * i + (angleStep / 2);
      final x = cx + radius * math.cos(angle);
      final y = cy + radius * math.sin(angle);
      _positions[kids[i]] = Offset(x, y);

      // Pass down 80% radius reduction and limit sweep to prevent overlapping on deep layers
      _layoutChildren(
        kids[i],
        children,
        x,
        y,
        angle - (sweep / 2.5), // Tighter fan out for sub-children
        sweep / 1.5,
        radius * 0.85,
        depth + 1,
      );
    }
  }

  Color _getNodeColor(int index) {
    return _nodeColors[index % _nodeColors.length];
  }

  @override
  Widget build(BuildContext context) {
    if (widget.nodes.isEmpty) {
      return const Center(
        child: Text(
          'No mind map data.',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return Stack(
      children: [
        AnimatedBuilder(
          animation: _fadeAnim,
          builder: (context, child) {
            return InteractiveViewer(
              transformationController: _transformController,
              constrained:
                  false, // CRITICAL: Allows child to be larger than screen
              boundaryMargin: const EdgeInsets.all(1000),
              minScale: 0.1,
              maxScale: 4.0,
              child: SizedBox(
                width: 4000,
                height: 4000,
                child: Stack(
                  children: [
                    CustomPaint(
                      size: const Size(4000, 4000),
                      painter: _EdgePainter(
                        nodes: widget.nodes,
                        edges: widget.edges,
                        positions: _positions,
                        opacity: _fadeAnim.value,
                        linkColor: Theme.of(context).primaryColor,
                      ),
                    ),
                    ...widget.nodes.asMap().entries.map((entry) {
                      final i = entry.key;
                      final node = entry.value;
                      final id = _toId(node['id']);
                      final label = node['label']?.toString() ?? '?';
                      final pos = _positions[id];
                      if (pos == null) return const SizedBox.shrink();

                      final isSelected = _selectedNodeId == id;
                      final color = _getNodeColor(i);
                      final isRoot = i == 0;
                      final nodeRadius = isRoot ? 52.0 : 42.0;
                      final maxChars = isRoot ? 20 : 16;
                      final displayLabel = label;

                      return Positioned(
                        left: pos.dx - nodeRadius,
                        top: pos.dy - nodeRadius,
                        child: Opacity(
                          opacity: _fadeAnim.value,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedNodeId = isSelected ? null : id;
                              });
                              _showNodeDetail(label, color, i);
                            },
                            onDoubleTap: () {
                              _centerOnNode(pos, defaultScale: 2.5);
                              _showNodeDefinition(node, color);
                            },
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  width: isSelected
                                      ? nodeRadius * 2.3
                                      : nodeRadius * 2,
                                  height: isSelected
                                      ? nodeRadius * 2.3
                                      : nodeRadius * 2,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        color.withValues(alpha: 0.95),
                                        color.withValues(alpha: 0.55),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: color.withValues(
                                          alpha: isSelected ? 0.7 : 0.3,
                                        ),
                                        blurRadius: isSelected ? 24 : 12,
                                        spreadRadius: isSelected ? 5 : 2,
                                      ),
                                    ],
                                    border: isSelected
                                        ? Border.all(
                                            color: Colors.white,
                                            width: 2.5,
                                          )
                                        : null,
                                  ),
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Text(
                                        displayLabel,
                                        textAlign: TextAlign.center,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: isRoot ? 12 : 10,
                                          fontWeight: FontWeight.bold,
                                          height: 1.2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Container(
                                    margin: const EdgeInsets.only(top: 6),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    constraints: const BoxConstraints(
                                      maxWidth: 220,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).cardColor,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: color.withValues(alpha: 0.6),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: color.withValues(alpha: 0.2),
                                          blurRadius: 12,
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      label,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
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
          },
        ),
        Positioned(
          right: 16,
          bottom: 96,
          child: FloatingActionButton.small(
            heroTag: 'mindmap_legend',
            onPressed: _showLegend,
            backgroundColor: const Color(0xFF2A3A5C),
            child: const Icon(
              Icons.info_outline,
              color: Colors.white70,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}

class _EdgePainter extends CustomPainter {
  final List<Map<String, dynamic>> nodes;
  final List<Map<String, dynamic>> edges;
  final Map<String, Offset> positions;
  final double opacity;
  final Color linkColor;

  _EdgePainter({
    required this.nodes,
    required this.edges,
    required this.positions,
    required this.opacity,
    required this.linkColor,
  });

  static String _toId(dynamic val) => val?.toString() ?? '';

  @override
  void paint(Canvas canvas, Size size) {
    for (var edge in edges) {
      final from = positions[_toId(edge['from'])];
      final to = positions[_toId(edge['to'])];
      if (from == null || to == null) continue;

      final paint = Paint()
        ..color = linkColor.withValues(alpha: 0.45 * opacity)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke;

      final mid = Offset((from.dx + to.dx) / 2, (from.dy + to.dy) / 2);
      final ctrl = Offset(mid.dx + 25, mid.dy - 25);

      final path = Path()
        ..moveTo(from.dx, from.dy)
        ..quadraticBezierTo(ctrl.dx, ctrl.dy, to.dx, to.dy);

      canvas.drawPath(path, paint);
      _drawArrow(canvas, ctrl, to, paint);
    }
  }

  void _drawArrow(Canvas canvas, Offset from, Offset to, Paint paint) {
    final arrowPaint = Paint()
      ..color = paint.color
      ..strokeWidth = 2
      ..style = PaintingStyle.fill;

    final angle = math.atan2(to.dy - from.dy, to.dx - from.dx);
    const arrowLen = 10.0;
    const arrowAngle = 0.5;

    final p1 = Offset(
      to.dx - arrowLen * math.cos(angle - arrowAngle),
      to.dy - arrowLen * math.sin(angle - arrowAngle),
    );
    final p2 = Offset(
      to.dx - arrowLen * math.cos(angle + arrowAngle),
      to.dy - arrowLen * math.sin(angle + arrowAngle),
    );

    canvas.drawPath(
      Path()
        ..moveTo(to.dx, to.dy)
        ..lineTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..close(),
      arrowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _EdgePainter old) =>
      old.opacity != opacity || old.edges != edges;
}
