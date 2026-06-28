import '../models/verification_record.dart';

class VerificationHistoryService {
  static final List<VerificationRecord> history = [];

  static void addRecord(VerificationRecord record) {
    // data terbaru tampil di paling atas
    history.insert(0, record);
  }

  static VerificationRecord? get lastRecord {
    if (history.isEmpty) return null;
    return history.first;
  }

  static void clearHistory() {
    history.clear();
  }
}
