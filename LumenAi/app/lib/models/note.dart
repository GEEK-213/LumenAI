class Notes {
  String id, title, subject, preview;
  List<String> tags;
  DateTime updatedAt;
  bool isFavorite;

  Notes({
    required this.id,
    required this.title,
    required this.subject,
    required this.tags,
    required this.preview,
    required this.updatedAt,
    this.isFavorite = false,
  });
}
