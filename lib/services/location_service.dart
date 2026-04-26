import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationResult {
  final Position? position;
  final String? error;

  LocationResult.success(this.position) : error = null;
  LocationResult.failure(this.error) : position = null;
}

class LocationService {
  /// Checks and requests location permissions, then returns current position.
  /// Returns a [LocationResult] with either a position or an error message.
  Future<LocationResult> getCurrentPositionWithStatus() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationResult.failure(
          'Location services are turned off. Please enable GPS in your device settings.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return LocationResult.failure(
            'Location permission was denied. Please allow location access to use this feature.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return LocationResult.failure(
          'Location permission is permanently denied. Please enable it in your device settings.');
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return LocationResult.success(position);
    } catch (e) {
      return LocationResult.failure(
          'Could not get your location. Please check GPS and try again.');
    }
  }

  /// Legacy method — returns null on failure (kept for backward compatibility).
  Future<Position?> getCurrentPosition() async {
    final result = await getCurrentPositionWithStatus();
    return result.position;
  }

  /// Converts GPS coordinates to a human-readable address.
  Future<String> getAddressFromCoordinates(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = <String>[
          if (p.locality?.isNotEmpty == true) p.locality!,
          if (p.subAdministrativeArea?.isNotEmpty == true)
            p.subAdministrativeArea!,
          if (p.country?.isNotEmpty == true) p.country!,
        ];
        return parts.isNotEmpty ? parts.join(', ') : 'Unknown location';
      }
    } catch (_) {}
    return 'Unknown location';
  }

  /// Calculates distance in km between two GPS points.
  double distanceKm(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }
}
