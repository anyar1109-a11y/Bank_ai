import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

import 'location_service_geocoding.dart'
    if (dart.library.html) 'location_service_geocoding_stub.dart';

class LocationService {
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('GPS tidak aktif');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Izin lokasi ditolak permanen');
    }
    return await Geolocator.getCurrentPosition();
  }

  Stream<Position> getPositionStream() {
    final LocationSettings settings;
    if (kIsWeb) {
      settings = WebSettings(accuracy: LocationAccuracy.high, distanceFilter: 1);
    } else {
      settings = const LocationSettings(
          accuracy: LocationAccuracy.high, distanceFilter: 1);
    }
    return Geolocator.getPositionStream(locationSettings: settings);
  }

  Future<bool> isGpsActive() async =>
      await Geolocator.isLocationServiceEnabled();

  Stream<ServiceStatus> getGpsServiceStream() {
    if (kIsWeb) return const Stream<ServiceStatus>.empty();
    return Geolocator.getServiceStatusStream();
  }

  /// Reverse geocoding — bekerja di Web (Nominatim) maupun Mobile (geocoding package).
  /// TIDAK ada lagi shortcut `if (kIsWeb) return "$lat, $lng"`.
  Future<String> getAddressFromCoordinates(double lat, double lng) async {
    return await geocodingGetAddress(lat, lng);
  }
}
