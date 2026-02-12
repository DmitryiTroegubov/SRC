import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/activity_service.dart';
import '../../auth/auth_controller.dart';
import '../../services/location_service.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  final service = LocationService();
  ref.onDispose(service.dispose);
  return service;
});

class RunState {
  const RunState({
    this.points = const <LatLng>[],
    this.current,
    this.startedAt,
    this.duration = Duration.zero,
    this.distance = 0,
    this.isRunning = false,
    this.isPaused = false,
    this.status,
  });

  final List<LatLng> points;
  final LatLng? current;
  final DateTime? startedAt;
  final Duration duration;
  final double distance;
  final bool isRunning;
  final bool isPaused;
  final String? status;

  RunState copyWith({
    List<LatLng>? points,
    LatLng? current,
    DateTime? startedAt,
    Duration? duration,
    double? distance,
    bool? isRunning,
    bool? isPaused,
    String? status,
  }) {
    return RunState(
      points: points ?? this.points,
      current: current ?? this.current,
      startedAt: startedAt ?? this.startedAt,
      duration: duration ?? this.duration,
      distance: distance ?? this.distance,
      isRunning: isRunning ?? this.isRunning,
      isPaused: isPaused ?? this.isPaused,
      status: status,
    );
  }
}

class RunController extends StateNotifier<RunState> {
  RunController(this._ref) : super(const RunState());

  final Ref _ref;
  final _distance = const Distance();
  StreamSubscription<LatLng>? _subscription;
  Timer? _timer;
  DateTime _lastUiTick = DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> startRun() async {
    final locationService = _ref.read(locationServiceProvider);
    state = const RunState(isRunning: true, status: 'GPS: connecting...');

    await locationService.startTracking();
    _timer?.cancel();
    final started = DateTime.now();
    state = state.copyWith(startedAt: started, status: 'GPS: active');

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.startedAt == null || state.isPaused) return;
      state = state.copyWith(duration: DateTime.now().difference(state.startedAt!));
    });

    await _subscription?.cancel();
    _subscription = locationService.stream.listen((point) {
      final now = DateTime.now();
      final points = [...state.points, point];
      var distance = state.distance;
      if (state.points.isNotEmpty) {
        distance += _distance(state.points.last, point);
      }

      if (now.difference(_lastUiTick).inMilliseconds < 350) {
        state = state.copyWith(points: points, current: point, distance: distance, status: 'GPS: active');
        return;
      }
      _lastUiTick = now;
      state = state.copyWith(points: points, current: point, distance: distance, status: 'GPS: active');
    }, onError: (e) {
      state = state.copyWith(status: 'GPS error: $e');
    });
  }

  void pauseRun() {
    _ref.read(locationServiceProvider).pauseTracking();
    state = state.copyWith(isPaused: true, status: 'GPS: paused');
  }

  void resumeRun() {
    _ref.read(locationServiceProvider).resumeTracking();
    state = state.copyWith(isPaused: false, status: 'GPS: active');
  }

  Future<void> stopRun() async {
    _timer?.cancel();
    await _subscription?.cancel();
    await _ref.read(locationServiceProvider).stopTracking();

    if (state.points.length < 2 || state.startedAt == null) {
      state = state.copyWith(isRunning: false, status: 'Недостаточно GPS точек для сохранения');
      return;
    }

    final user = _ref.read(authControllerProvider).user;
    if (user == null) {
      state = state.copyWith(isRunning: false, status: 'Пользователь не авторизован');
      return;
    }

    try {
      await saveActivityToSupabase(
        supabaseClient: Supabase.instance.client,
        userId: user.id,
        startedAt: state.startedAt!,
        endedAt: DateTime.now(),
        routePoints: state.points,
      );
      state = state.copyWith(isRunning: false, isPaused: false, status: 'Пробежка сохранена ✅');
    } catch (e) {
      state = state.copyWith(isRunning: false, isPaused: false, status: 'Ошибка сохранения: $e');
    }
  }
}

final runControllerProvider = StateNotifierProvider<RunController, RunState>((ref) {
  return RunController(ref);
});