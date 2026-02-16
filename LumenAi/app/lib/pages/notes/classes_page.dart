import 'package:flutter/material.dart';
import '../../models/add_notes.dart';
import 'input_type_page.dart';

class ClassesPage extends StatefulWidget {
  const ClassesPage({super.key});

  @override
  State<ClassesPage> createState() => _ClassesPageState();
}

class _ClassesPageState extends State<ClassesPage> {
  final List<AddNotes> classes = [];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: classes.length,
      itemBuilder: (_, index) {
        final cls = classes[index];
        return ListTile(
          title: Text(cls.name),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => InputTypePage(className: cls.name)),
            );
          },
        );
      },
    );
  }
}
