import 'package:app/models/note.dart';
import 'package:flutter/material.dart';
import 'package:app/components/notes_card.dart';
import 'notes_filter.dart';

class NotesView extends StatelessWidget {
  final List<Notes> notes;
  final String selectedFilter;
  final String searchQuery;
  final ValueChanged<String> onFilterChange;
  final ValueChanged<String> onSearchChange;

  const NotesView({
    super.key,
    required this.notes,
    required this.selectedFilter,
    required this.searchQuery,
    required this.onFilterChange,
    required this.onSearchChange,
  });

  List<Notes> get filteredNotes {
    return notes.where((note) {
      final matchesSearch = note.title.toLowerCase().contains(
        searchQuery.toLowerCase(),
      );

      final matchesFilter =
          selectedFilter == "All" ||
          (selectedFilter == "Favorites" && note.isFavorite);

      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // search
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: onSearchChange,
              decoration: const InputDecoration(hintText: "Search notes"),
            ),
          ),

          // filters
          NotesFilter(active: selectedFilter, onChange: onFilterChange),

          const SizedBox(height: 12),

          // list placeholder
          Expanded(
  child: filteredNotes.isEmpty
      ? const Center(child: Text("No notes found"))
      : ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: filteredNotes.length,
          itemBuilder: (_, index) {
            final note = filteredNotes[index];
            return NoteCard(note: note);
          },
        ),
),

        ],
      ),
    );
  }
}
