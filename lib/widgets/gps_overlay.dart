import 'package:flutter/material.dart';

class GpsInfoOverlay extends StatelessWidget {
  final String latitude;
  final String longitude;
  final String address;
  final String timestamp;
  final bool gpsActive;
  final bool faceDetected;

  const GpsInfoOverlay({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.timestamp,
    required this.gpsActive,
    required this.faceDetected,
  });

  @override
  Widget build(BuildContext context) {
    // Pecah alamat berdasarkan koma untuk ditampilkan per baris terstruktur
    final addressParts = address.isNotEmpty
        ? address.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList()
        : <String>[];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Baris 1: Status GPS + Koordinat ──────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: gpsActive
                      ? Colors.green.withValues(alpha: 0.25)
                      : Colors.red.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: gpsActive ? Colors.greenAccent : Colors.redAccent,
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      gpsActive ? Icons.gps_fixed : Icons.gps_off,
                      color: gpsActive ? Colors.greenAccent : Colors.redAccent,
                      size: 11,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      gpsActive ? 'GPS LIVE' : 'GPS OFF',
                      style: TextStyle(
                        color: gpsActive ? Colors.greenAccent : Colors.redAccent,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  latitude.isNotEmpty
                      ? 'Lat: $latitude   Lon: $longitude'
                      : 'Koordinat tidak tersedia',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          // ── Baris Alamat terstruktur ──────────────────────────────────────
          if (addressParts.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ikon + label
                  const Row(
                    children: [
                      Icon(Icons.location_on_rounded,
                          color: Colors.amberAccent, size: 12),
                      SizedBox(width: 4),
                      Text(
                        'LOKASI',
                        style: TextStyle(
                          color: Colors.amberAccent,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Setiap bagian alamat di baris sendiri
                  ...addressParts.map((part) => Padding(
                        padding: const EdgeInsets.only(bottom: 1),
                        child: Text(
                          part,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            height: 1.4,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      )),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 4),
            const Text(
              'Alamat: Mengambil lokasi...',
              style: TextStyle(color: Colors.white70, fontSize: 10),
            ),
          ],

          // ── Baris bawah: Waktu + Status Wajah ────────────────────────────
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.access_time_rounded,
                  color: Colors.white70, size: 11),
              const SizedBox(width: 4),
              Text(
                timestamp,
                style: const TextStyle(color: Colors.white70, fontSize: 10),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: faceDetected
                      ? Colors.green.withValues(alpha: 0.25)
                      : Colors.red.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color:
                        faceDetected ? Colors.greenAccent : Colors.redAccent,
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      faceDetected
                          ? Icons.face_retouching_natural
                          : Icons.face_retouching_off,
                      color: faceDetected
                          ? Colors.greenAccent
                          : Colors.redAccent,
                      size: 11,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      faceDetected ? 'Wajah Terdeteksi' : 'Tidak Terdeteksi',
                      style: TextStyle(
                        color: faceDetected
                            ? Colors.greenAccent
                            : Colors.redAccent,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
