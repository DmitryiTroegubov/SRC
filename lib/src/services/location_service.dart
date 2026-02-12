import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  final _controller = StreamController<LatLng>.broadcast();
  final Distance _distance = const Distance();

  StreamSubscription<Position>? _subscription;
  LatLng? _lastAccepted;
  bool _paused = false;

  Stream<LatLng> get stream => _controller.stream;

  Future<void> startTracking() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) throw Exception('Location service disabled');

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      throw Exception('Location permission denied');
    }

    const settings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 3,
      timeLimit: Duration(seconds: 6),
    );

    await _subscription?.cancel();
    _subscription = Geolocator.getPositionStream(locationSettings: settings).listen(
      (position) {
        if (_paused) return;
        if (position.accuracy > 35) return;
        if (position.speed > 10) return;

        final point = LatLng(position.latitude, position.longitude);
        if (_lastAccepted != null) {
          final meters = _distance(_lastAccepted!, point);
          if (meters < 1.5) return;
        }

        _lastAccepted = point;
        _controller.add(point);
      },
      onError: _controller.addError,
    );
  }

  void pauseTracking() {
    _paused = true;
  }

  void resumeTracking() {
    _paused = false;
  }

  Future<void> stopTracking() async {
    await _subscription?.cancel();
    _subscription = null;
    _lastAccepted = null;
    _paused = false;
  }

  Future<void> dispose() async {
    await stopTracking();
    await _controller.close();
  }
}