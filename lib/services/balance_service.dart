class BalanceService {
  static double _balance = 25000000;

  static double get balance => _balance;

  static String get formattedBalance {
    final parts = _balance.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return 'Rp $parts';
  }

  static bool debit(double amount) {
    if (amount <= 0 || amount > _balance) return false;
    _balance -= amount;
    return true;
  }

  static void credit(double amount) {
    if (amount > 0) _balance += amount;
  }

  static double parseNominal(String raw) {
    final cleaned = raw.replaceAll('.', '').replaceAll(',', '').trim();
    return double.tryParse(cleaned) ?? 0;
  }
}
