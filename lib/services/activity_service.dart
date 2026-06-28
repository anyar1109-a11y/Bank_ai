class TransactionRecord {
  final String type;      // 'transfer', 'qris', 'topup'
  final String title;
  final String? nominal;
  final String? target;   // rekening tujuan, merchant, provider
  final String? catatan;
  final DateTime time;
  final bool success;

  TransactionRecord({
    required this.type,
    required this.title,
    this.nominal,
    this.target,
    this.catatan,
    required this.time,
    this.success = true,
  });
}

class ActivityService {
  static List<String> activities = [];
  static List<TransactionRecord> transactions = [];

  static void addActivity(String activity) {
    activities.add(activity);
  }

  static void addTransaction(TransactionRecord record) {
    transactions.insert(0, record);
    addActivity('${record.title} - ${record.nominal ?? ''}');
  }

  static List<TransactionRecord> getByType(String type) {
    return transactions.where((t) => t.type == type).toList();
  }
}
