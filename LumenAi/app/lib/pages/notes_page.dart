import 'package:flutter/material.dart';
import 'notes_view.dart';
import 'package:app/models/note.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  String selectedFilter = "All";
  String searchQuery = "";

  final List<Notes> _notes = [
  Notes(
    id: "1",
    title: "Intro to Neural Networks",
    preview: "Layers allow the model to learn hierarchical features...",
    subject: "Computer Science",
    tags: ["AI", "ML", "Exam"],
    updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
    isFavorite: true,
  ),
  Notes(
    id: "2",
    title: "European History Timeline",
    preview: "The Treaty of Versailles marked the end of World War I...",
    subject: "History",
    tags: ["History", "ML", "Exam"],
    updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    isFavorite: false,
  ),
];


  @override
  Widget build(BuildContext context) {
    return NotesView(
      notes: _notes,
      selectedFilter: selectedFilter,
      searchQuery: searchQuery,
      onFilterChange: (value) {
        setState(() => selectedFilter = value);
      },
      onSearchChange: (value) {
        setState(() => searchQuery = value);
      },
    );
  }
  
}
