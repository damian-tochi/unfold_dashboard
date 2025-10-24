class JournalEntries {
  final DateTime time;
  final int mood;
  final String note;

  JournalEntries({required this.time, required this.mood, required this.note});

  factory JournalEntries.fromJson(Map<String, dynamic> json) {
    return JournalEntries(
      time: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      mood: (json['mood'] ?? 3).toInt(),
      note: (json['note'] ?? 'No note provided'),
    );
  }
}
