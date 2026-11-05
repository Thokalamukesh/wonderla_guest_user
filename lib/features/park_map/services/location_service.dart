import 'package:geolocator/geolocator.dart';

class LocationResult {
  const LocationResult({this.position, this.message});

  final Position? position;
  final String? message;
}

class LocationService {
  Future<LocationResult> currentPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationResult(
          message: 'Turn on location services to find your position.',
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        return const LocationResult(message: 'Location permission was denied.');
      }
      if (permission == LocationPermission.deniedForever) {
        return const LocationResult(
          message: 'Allow location access in your device settings.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return LocationResult(position: position);
    } catch (_) {
      return const LocationResult(
        message: 'Could not get your location. Check GPS and try again.',
      );
    }
  }

  Stream<Position> watchPosition() => Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    ),
  );
}
