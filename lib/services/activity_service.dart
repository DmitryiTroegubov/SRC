import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _lineStringPattern = RegExp(r'^LINESTRING\(.*\)$');

String routePointsToWkt(List<LatLng> routePoints) {
  if (routePoints.length < 2) {
    throw ArgumentError('At least 2 points are required to create a LINESTRING.');
  }

  final coordinates = routePoints
      .map((point) => '${point.longitude} ${point.latitude}')
      .join(', ');

  return 'LINESTRING($coordinates)';
}

Future<void> saveActivityToSupabase({
  required SupabaseClient supabaseClient,
  required String userId,
  required DateTime startedAt,
  required DateTime endedAt,
  required List<LatLng> routePoints,
}) async {
  final wktPath = routePointsToWkt(routePoints);

  if (!_lineStringPattern.hasMatch(wktPath)) {
    throw const FormatException('Generated WKT is invalid.');
  }

  await supabaseClient.from('activities').insert({
    'user_id': userId,
    'started_at': startedAt.toUtc().toIso8601String(),
    'ended_at': endedAt.toUtc().toIso8601String(),
    'path': wktPath,
    'distance_meters': null,
  });
}