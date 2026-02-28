import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Displays code snippets extracted from technical lectures.
/// Each snippet is shown in a styled card with syntax-aware styling,
/// language badge, and one-tap copy functionality.
class CodeSandboxTab extends StatelessWidget {
  final List<Map<String, dynamic>> codeSnippets;

  const CodeSandboxTab({super.key, required this.codeSnippets});

  Color _getLanguageColor(String lang) {
    switch (lang.toLowerCase()) {
      case 'python':
        return const Color(0xFF3572A5);
      case 'java':
        return const Color(0xFFB07219);
      case 'javascript':
      case 'js':
        return const Color(0xFFF1E05A);
      case 'c':
      case 'c++':
      case 'cpp':
        return const Color(0xFF555555);
      case 'html':
        return const Color(0xFFE34C26);
      case 'css':
        return const Color(0xFF563D7C);
      case 'sql':
        return const Color(0xFFE38C00);
      case 'dart':
        return const Color(0xFF00B4AB);
      default:
        return const Color(0xFF6C5CE7);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (codeSnippets.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.code_off, size: 48, color: Colors.white24),
            SizedBox(height: 12),
            Text(
              'No code snippets found.',
              style: TextStyle(color: Colors.white38),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: codeSnippets.length,
      itemBuilder: (context, index) {
        final snippet = codeSnippets[index];
        final title = snippet['title']?.toString() ?? 'Code Snippet';
        final language = snippet['language']?.toString() ?? 'text';
        final code = snippet['code_content']?.toString() ?? '';
        final langColor = _getLanguageColor(language);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2036),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: langColor.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: langColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.code, size: 18, color: langColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: langColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        language.toUpperCase(),
                        style: TextStyle(
                          color: langColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: code));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('📋 Copied "$title" to clipboard'),
                            backgroundColor: langColor,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.copy,
                          size: 16,
                          color: Colors.white54,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Code block
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SelectableText(
                    code,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      color: Color(0xFFABB2BF),
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
