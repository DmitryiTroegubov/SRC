import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'services/activity_service.dart';

class RunTrackerScreen extends StatefulWidget {
  const RunTrackerScreen({super.key});

  @override
  State<RunTrackerScreen> createState() => _RunTrackerScreenState();
}

class _RunTrackerScreenState extends State<RunTrackerScreen> {
  final MapController _mapController = MapController();
  final Distance _distanceCalculator = const Distance();

  StreamSubscription<Position>? _positionSubscription;
  List<LatLng> _routePoints = [];
  LatLng? _currentLocation;
  DateTime? _startedAt;
  Duration _duration = Duration.zero;
  Timer? _durationTimer;
  double _distanceMeters = 0;
  bool _isTracking = false;
  bool _isLoading = true;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _durationTimer?.cancel();
    super.dispose();
  }

  Future<void> _initLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Location services are disabled.';
      });
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() {
        _isLoading = false;
        _statusMessage =
            'Location permission denied. Enable it to start tracking.';
      });
      return;
    }

    final currentPosition = await Geolocator.getCurrentPosition();

    setState(() {
      _currentLocation =
          LatLng(currentPosition.latitude, currentPosition.longitude);
      _isLoading = false;
      _statusMessage = null;
    });
  }

  Future<void> _startTracking() async {
    if (_currentLocation == null) {
      return;
    }

    setState(() {
      _isTracking = true;
      _routePoints = [_currentLocation!];
      _startedAt = DateTime.now();
      _duration = Duration.zero;
      _distanceMeters = 0;
      _statusMessage = null;
    });

    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _startedAt == null) {
        return;
      }
      setState(() {
        _duration = DateTime.now().difference(_startedAt!);
      });
    });

    const settings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 5,
    );

    _positionSubscription?.cancel();
    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: settings).listen(
      (position) {
        final newPoint = LatLng(position.latitude, position.longitude);

        setState(() {
          _currentLocation = newPoint;
          if (_routePoints.isNotEmpty) {
            final lastPoint = _routePoints.last;
            _distanceMeters += _distanceCalculator(lastPoint, newPoint);
          }
          _routePoints.add(newPoint);
        });

        _mapController.move(newPoint, _mapController.camera.zoom);
      },
      onError: (error) {
        setState(() {
          _statusMessage = 'Location stream error: $error';
        });
      },
    );
  }

  Future<void> _stopAndSaveTracking() async {
    final startedAt = _startedAt;
    if (startedAt == null || _routePoints.length < 2) {
      setState(() {
        _isTracking = false;
        _statusMessage = 'Need at least 2 GPS points to save an activity.';
      });
      await _positionSubscription?.cancel();
      _durationTimer?.cancel();
      return;
    }

    await _positionSubscription?.cancel();
    _durationTimer?.cancel();

    setState(() {
      _isTracking = false;
    });

    final client = Supabase.instance.client;
    final currentUser = client.auth.currentUser;

    if (currentUser == null) {
      setState(() {
        _statusMessage = 'No authenticated user found. Please log in first.';
      });
      return;
    }

    try {
      await saveActivityToSupabase(
        supabaseClient: client,
        userId: currentUser.id,
        startedAt: startedAt,
        endedAt: DateTime.now(),
        routePoints: _routePoints,
      );

      setState(() {
        _statusMessage = 'Run saved successfully!';
      });
    } catch (error) {
      setState(() {
        _statusMessage = 'Failed to save run: $error';
      });
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentLocation ?? const LatLng(0, 0),
                    initialZoom: 16,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.flutter_application_1',
                    ),
                    if (_routePoints.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _routePoints,
                            strokeWidth: 5,
                            color: Colors.blue,
                          ),
                        ],
                      ),
                    if (_currentLocation != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _currentLocation!,
                            width: 48,
                            height: 48,
                            child: const Icon(
                              Icons.my_location,
                              color: Colors.red,
                              size: 32,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                Positioned(
                  top: 48,
                  left: 16,
                  right: 16,
                  child: Card(
                    color: Colors.black.withValues(alpha: 0.7),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Distance: ${_distanceMeters.toStringAsFixed(1)} m',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Duration: ${_formatDuration(_duration)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (_statusMessage != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _statusMessage!,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading
            ? null
            : _isTracking
                ? _stopAndSaveTracking
                : _startTracking,
        icon: Icon(_isTracking ? Icons.stop : Icons.play_arrow),
        label: Text(_isTracking ? 'Stop/Finish' : 'Start Run'),
      ),
    );
  }
}