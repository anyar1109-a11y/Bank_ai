class VerificationRecord {
  final String id;

  final String type; // contoh: "Verifikasi Wajah Awal", "Liveness - Berkedip"

  final String imagePath; // path foto hasil rekaman wajah tersimpan di device

  final String latitude;

  final String longitude;

  final String address;

  final DateTime timestamp;

  final bool success;

  VerificationRecord({
    required this.id,
    required this.type,
    required this.imagePath,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.timestamp,
    this.success = true,
  });
}
