import 'dart:io';

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:flutter/foundation.dart'; // Wajib ditambahkan untuk menggunakan kIsWeb

import '../services/verification_history_service.dart';
import '../utils/datetime_format.dart';

class FaceHistoryScreen extends StatelessWidget {
  const FaceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final records = VerificationHistoryService.history;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Riwayat Verifikasi Wajah"),
      ),
      body: records.isEmpty
          ? const Center(
              child: Text(
                "Belum ada riwayat verifikasi wajah.",
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: records.length,
              itemBuilder: (context, index) {
                final record = records[index];

                // PERBAIKAN LOGIKA TAMPILAN GAMBAR CROSS-PLATFORM (WEB & HP)
                Widget imageWidget;

                if (kIsWeb) {
                  // Jika di browser, path gambar berupa Blob URL, tampilkan dengan Image.network
                  imageWidget = Image.network(
                    record.imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.broken_image),
                      );
                    },
                  );
                } else {
                  // Jika di HP asli (Android/iOS), gunakan pendeteksian file seperti biasa
                  final file = File(record.imagePath);
                  imageWidget = file.existsSync()
                      ? Image.file(
                          file,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.face),
                        );
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: 70,
                            height: 70,
                            child: imageWidget, // Menampilkan widget gambar yang sudah disesuaikan platformnya
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      record.type,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    record.success
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    color: record.success
                                        ? Colors.green
                                        : Colors.red,
                                    size: 18,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formatTimestamp(record.timestamp),
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                record.address,
                                style: const TextStyle(fontSize: 12),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                "Lat: ${record.latitude}  Long: ${record.longitude}",
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}