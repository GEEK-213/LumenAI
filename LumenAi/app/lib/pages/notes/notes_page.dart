import 'package:flutter/material.dart';

class NotesPage extends StatelessWidget {
  final List<String> classes;
  final Function(String className) onClassTap;

  const NotesPage({
    super.key,
    required this.classes,
    required this.onClassTap,
  });

  @override
  Widget build(BuildContext context) {
    if (classes.isEmpty) {
      return const Center(
        child: Text(
          "No classes yet.\nTap + to add one.",
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      itemCount: classes.length,
      itemBuilder: (_, index) {
        final className = classes[index];
        return ListTile(
          title: Text(className),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => onClassTap(className),
        );
      },
    );
  }
}

  // return NotesView(
  //   notes: _notes,
  //   selectedFilter: selectedFilter,
  //   searchQuery: searchQuery,
  //   onFilterChange: (value) {
  //     setState(() => selectedFilter = value);
  //   },
  //   onSearchChange: (value) {
  //     setState(() => searchQuery = value);
  //   },
  // );