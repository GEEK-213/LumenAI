import 'package:flutter/material.dart';

class NotesFilter extends StatelessWidget {
  final String active;
  final ValueChanged<String> onChange;

  const NotesFilter({
    super.key,
    required this.active,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final filters = ["All", "Favorites", "AI Summaries"];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: filters.map((f) {
          final isActive = f == active;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChange(f),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? Colors.blue : Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  f,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight:
                        isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
