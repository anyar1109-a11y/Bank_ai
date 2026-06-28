// Web stub — Nominatim OpenStreetMap (tanpa custom header agar tidak trigger CORS preflight)
import 'dart:async';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<String> geocodingGetAddress(double lat, double lng) async {
  try {
    final addr = await _nominatimFetch(lat, lng);
    if (addr == null) return '$lat, $lng';
    return _buildAddress(addr, lat, lng);
  } catch (_) {
    return '$lat, $lng';
  }
}

Future<Map<String, String>> getAddressComponents(double lat, double lng) async {
  try {
    final addr = await _nominatimFetch(lat, lng);
    if (addr == null) return {};
    return _extractComponents(addr);
  } catch (_) {
    return {};
  }
}

/// Fetch Nominatim — TANPA custom request header supaya tidak ada CORS preflight.
/// Bahasa Indonesia dimasukkan lewat query param saja.
Future<Map<String, dynamic>?> _nominatimFetch(double lat, double lng) {
  // Gunakan 6 desimal saja agar URL lebih pendek
  final latS = lat.toStringAsFixed(6);
  final lngS = lng.toStringAsFixed(6);
  final url = 'https://nominatim.openstreetmap.org/reverse'
      '?lat=$latS&lon=$lngS'
      '&format=json'
      '&addressdetails=1'
      '&accept-language=id'        // param URL, bukan header → aman dari CORS
      '&zoom=18';

  final completer = Completer<Map<String, dynamic>?>();

  final xhr = html.HttpRequest();
  xhr.open('GET', url, async: true);
  // JANGAN setRequestHeader apapun di sini — biarkan browser kirim simple request

  xhr.onLoad.listen((_) {
    if (xhr.status == 200) {
      try {
        final data = jsonDecode(xhr.responseText ?? '{}') as Map<String, dynamic>;
        final addr = data['address'] as Map<String, dynamic>?;
        completer.complete(addr);
      } catch (_) {
        completer.complete(null);
      }
    } else {
      completer.complete(null);
    }
  });

  xhr.onError.listen((_) => completer.complete(null));
  xhr.onTimeout.listen((_) => completer.complete(null));

  xhr.send();

  // Timeout 10 detik
  return completer.future.timeout(
    const Duration(seconds: 10),
    onTimeout: () => null,
  );
}

/// Pemetaan field Nominatim → komponen alamat Indonesia
Map<String, String> _extractComponents(Map<String, dynamic> addr) {
  String? s(String key) {
    final v = addr[key]?.toString().trim();
    return (v != null && v.isNotEmpty) ? v : null;
  }

  final jalan     = s('road') ?? s('pedestrian') ?? s('path') ?? s('footway') ?? s('cycleway');
  final desa      = s('village') ?? s('hamlet') ?? s('suburb') ?? s('neighbourhood') ?? s('quarter');
  final kecamatan = s('city_district') ?? s('subdistrict') ?? s('district') ?? s('county');
  final kabupaten = s('city') ?? s('town') ?? s('municipality') ?? s('regency');
  final provinsi  = s('state') ?? s('province') ?? s('region');
  final negara    = s('country');

  final result = <String, String>{};
  if (jalan != null)     result['jalan'] = jalan;
  if (desa != null)      result['desa'] = desa;
  if (kecamatan != null) result['kecamatan'] = kecamatan;
  if (kabupaten != null) result['kabupaten'] = kabupaten;
  if (provinsi != null)  result['provinsi'] = provinsi;
  if (negara != null)    result['negara'] = negara;
  return result;
}

/// Bangun string alamat dari komponen, hilangkan duplikat
String _buildAddress(Map<String, dynamic> raw, double lat, double lng) {
  final c = _extractComponents(raw);
  if (c.isEmpty) return '$lat, $lng';

  final parts  = <String>[];
  final seen   = <String>{};

  void add(String? v, {String prefix = ''}) {
    if (v == null) return;
    final display = prefix.isEmpty ? v : '$prefix $v';
    if (seen.add(v.toLowerCase())) parts.add(display);
  }

  add(c['jalan'],     prefix: 'Jl.');
  add(c['desa'],      prefix: 'Kel.');
  // kecamatan hanya jika beda dari kabupaten
  if (c['kecamatan'] != null &&
      c['kecamatan']!.toLowerCase() != c['kabupaten']?.toLowerCase()) {
    add(c['kecamatan'], prefix: 'Kec.');
  }
  add(c['kabupaten']);
  // provinsi hanya jika beda dari kabupaten
  if (c['provinsi'] != null &&
      c['provinsi']!.toLowerCase() != c['kabupaten']?.toLowerCase()) {
    add(c['provinsi']);
  }
  add(c['negara']);

  return parts.isEmpty ? '$lat, $lng' : parts.join(', ');
}
