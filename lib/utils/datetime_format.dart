String formatTimestamp(DateTime dt) {
  String two(int n) => n.toString().padLeft(2, '0');

  final tanggal = "${two(dt.day)}/${two(dt.month)}/${dt.year}";
  final waktu = "${two(dt.hour)}:${two(dt.minute)}:${two(dt.second)}";

  return "$tanggal $waktu";
}
