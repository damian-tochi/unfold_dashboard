

import '../data/data_loader.dart';
import '../models/journal_entries.dart';

class JournalService {
  Future<List<JournalEntries>> fetchJournals() async {
    final data = await DataLoader.loadJsonList('assets/data/journals.json');
    return data.map(JournalEntries.fromJson).toList();
  }
}
