import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart';

/// Mengembalikan string alamat lengkap dari koordinat.
/// Format: "Nama Jalan, Desa/Kelurahan, Kota/Kecamatan, Kabupaten, Provinsi, Negara"
Future<String> geocodingGetAddress(double lat, double lng) async {
  try {
    final placemarks = await placemarkFromCoordinates(lat, lng);
    if (placemarks.isEmpty) return '$lat, $lng';

    final p = placemarks.first;
    debugPrint('[Geocoding] raw placemark: '
        'name=${p.name}, street=${p.street}, '
        'subLocality=${p.subLocality}, locality=${p.locality}, '
        'subAdministrativeArea=${p.subAdministrativeArea}, '
        'administrativeArea=${p.administrativeArea}, '
        'country=${p.country}');

    final components = _extractComponents(p);
    final result = _buildString(components, lat, lng);
    debugPrint('[Geocoding] result: $result');
    return result;
  } catch (e) {
    debugPrint('[Geocoding] Error: $e');
    return '$lat, $lng';
  }
}

/// Mengembalikan komponen alamat terstruktur sebagai Map.
Future<Map<String, String>> getAddressComponents(double lat, double lng) async {
  try {
    final placemarks = await placemarkFromCoordinates(lat, lng);
    if (placemarks.isEmpty) return {};
    return _extractComponents(placemarks.first);
  } catch (_) {
    return {};
  }
}

/// Ekstrak komponen dari Placemark dengan pemetaan yang benar untuk Indonesia.
///
/// Pemetaan package geocoding (Android/iOS) → komponen alamat:
/// ┌─────────────────────────┬──────────────────────────────────────┐
/// │ Placemark field         │ Komponen Indonesia                   │
/// ├─────────────────────────┼──────────────────────────────────────┤
/// │ street / thoroughfare   │ Nama jalan                           │
/// │ subLocality             │ Desa / Kelurahan                     │
/// │ locality                │ Kecamatan / Kota kecil               │
/// │ subAdministrativeArea   │ Kabupaten / Kota madya               │
/// │ administrativeArea      │ Provinsi ← BENAR untuk Indonesia     │
/// │ country                 │ Negara                               │
/// └─────────────────────────┴──────────────────────────────────────┘
Map<String, String> _extractComponents(Placemark p) {
  String? s(String? v) {
    final t = v?.trim();
    return (t != null && t.isNotEmpty && t != 'null') ? t : null;
  }

  final jalan = s(p.street) ?? s(p.thoroughfare);
  final desa = s(p.subLocality);
  final kecamatan = s(p.locality);
  final kabupaten = s(p.subAdministrativeArea);
  final provinsi = s(p.administrativeArea);
  final negara = s(p.country);

  final result = <String, String>{};
  if (jalan != null)      result['jalan'] = jalan;
  if (desa != null)       result['desa'] = desa;
  if (kecamatan != null)  result['kecamatan'] = kecamatan;
  if (kabupaten != null)  result['kabupaten'] = kabupaten;
  if (provinsi != null)   result['provinsi'] = provinsi;
  if (negara != null)     result['negara'] = negara;

  return result;
}

/// Bangun string alamat dari komponen, deduplikasi nilai yang sama.
String _buildString(Map<String, String> c, double lat, double lng) {
  if (c.isEmpty) return '$lat, $lng';

  final parts = <String>[];
  final seen = <String>{};

  void add(String? v) {
    if (v != null && seen.add(v)) parts.add(v);
  }

  add(c['jalan']);
  add(c['desa']);
  // Kecamatan hanya tambah jika berbeda dari kabupaten
  if (c['kecamatan'] != null && c['kecamatan'] != c['kabupaten']) {
    add(c['kecamatan']);
  }
  add(c['kabupaten']);
  // Provinsi hanya tambah jika berbeda dari kabupaten
  if (c['provinsi'] != null && c['provinsi'] != c['kabupaten']) {
    add(c['provinsi']);
  }
  add(c['negara']);

  return parts.isEmpty ? '$lat, $lng' : parts.join(', ');
}
