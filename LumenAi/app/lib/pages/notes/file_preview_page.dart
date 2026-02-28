import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';


class FilePreviewPage extends StatefulWidget {
  final String lectureId;
  final String title;
  final String? driveFileId;
  final bool isAnalyzed;

  const FilePreviewPage({
    super.key,
    required this.lectureId,
    required this.title,
    this.driveFileId,
    this.isAnalyzed = false,
  });

  @override
  State<FilePreviewPage> createState() => _FilePreviewPageState();
}

class _FilePreviewPageState extends State<FilePreviewPage> {
  final ApiService _apiService = ApiService();
  bool _isAnalyzing = false;
  bool _analyzed = false;

  @override
  void initState() {
    super.initState();
    _analyzed = widget.isAnalyzed;
  }

  Future<void> _openInBrowser() async {
    if (widget.driveFileId == null) return;
    final url = Uri.parse(
      'https://drive.google.com/file/d/${widget.driveFileId}/view',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _makeItSmart() async {
    setState(() => _isAnalyzing = true);

    try {
      await _apiService.analyzeLecture(widget.lectureId);
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _analyzed = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '✅ Analysis complete! Summary, quiz & flashcards are ready.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Analysis failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getFileExtension() {
    final parts = widget.title.split('.');
    if (parts.length > 1) return parts.last.toUpperCase();
    return 'FILE';
  }

  IconData _getFileIcon() {
    final ext = _getFileExtension().toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'txt':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor() {
    final ext = _getFileExtension().toLowerCase();
    switch (ext) {
      case 'pdf':
        return Colors.red[400]!;
      case 'ppt':
      case 'pptx':
        return Colors.orange[400]!;
      case 'doc':
      case 'docx':
        return Colors.blue[400]!;
      case 'txt':
        return Colors.grey[400]!;
      default:
        return Colors.teal[400]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileColor = _getFileColor();

    return Scaffold(
      backgroundColor: const Color(0xFF0C1223),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2036),
        title: Text(
          widget.title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (_analyzed)
            IconButton(
              icon: const Icon(Icons.auto_awesome, color: Colors.amber),
              tooltip: 'View Smart Analysis',
              onPressed: () => Navigator.pop(context, true),
            ),
        ],
      ),
      body: _isAnalyzing
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      color: Colors.amber[600],
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    '🧠 Making it Smart...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Generating summary, quiz & flashcards',
                    style: TextStyle(color: Colors.grey[400], fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This may take a minute...',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // File icon card
                    Container(
                      width: 120,
                      height: 140,
                      decoration: BoxDecoration(
                        color: fileColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: fileColor.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_getFileIcon(), color: fileColor, size: 48),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: fileColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _getFileExtension(),
                              style: TextStyle(
                                color: fileColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // File title
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _analyzed
                            ? Colors.green.withOpacity(0.15)
                            : Colors.amber.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _analyzed ? '✅ Analyzed' : '📄 Raw File',
                        style: TextStyle(
                          color: _analyzed
                              ? Colors.green[300]
                              : Colors.amber[300],
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // View in Browser button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _openInBrowser,
                        icon: const Icon(Icons.open_in_browser, size: 22),
                        label: const Text(
                          'View File in Browser',
                          style: TextStyle(fontSize: 16),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.2),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Make it Smart / View Analysis button
                    if (!_analyzed)
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _makeItSmart,
                          icon: const Icon(Icons.auto_awesome, size: 22),
                          label: const Text(
                            'Make it Smart',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber[800],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    if (_analyzed)
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context, true),
                          icon: const Icon(Icons.auto_awesome, size: 22),
                          label: const Text(
                            'View Smart Analysis',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[700],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
