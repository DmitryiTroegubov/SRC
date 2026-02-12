import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/auth_controller.dart';

final historyProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(authControllerProvider).user;
  if (user == null) return [];
  final rows = await Supabase.instance.client
      .from('activities')
      .select('id, started_at, ended_at, distance_meters, created_at')
      .eq('user_id', user.id)
      .order('created_at', ascending: false)
      .limit(20);
  return List<Map<String, dynamic>>.from(rows);
});

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);
    final dateFormat = DateFormat('dd MMM, HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed: $e')),
        data: (items) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final item = items[i];
            final meters = ((item['distance_meters'] ?? 0) as num).toDouble();
            return Card(
              child: ListTile(
                title: Text('${meters.toStringAsFixed(0)} m'),
                subtitle: Text(
                  dateFormat.format(DateTime.parse(item['started_at'] as String).toLocal()),
                ),
                trailing: const Icon(Icons.chevron_right),
              ),
            );
          },
        ),
      ),
    );
  }
}