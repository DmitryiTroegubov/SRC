import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'run_controller.dart';

class RunHudScreen extends ConsumerWidget {
  const RunHudScreen({super.key});

  String _format(Duration duration) {
    final h = duration.inHours.toString().padLeft(2, '0');
    final m = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final s = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final run = ref.watch(runControllerProvider);
    final controller = ref.read(runControllerProvider.notifier);
    final pace = run.distance > 0 && run.duration.inSeconds > 0
        ? (run.duration.inSeconds / 60) / (run.distance / 1000)
        : 0.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Run HUD')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _MetricCard(title: 'Timer', value: _format(run.duration))),
                const SizedBox(width: 12),
                Expanded(child: _MetricCard(title: 'Distance', value: '${run.distance.toStringAsFixed(0)} m')),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _MetricCard(title: 'Pace', value: pace == 0 ? '--' : '${pace.toStringAsFixed(2)} min/km')),
                const SizedBox(width: 12),
                Expanded(child: _MetricCard(title: 'GPS', value: run.status ?? 'idle')),
              ],
            ),
            const Spacer(),
            if (!run.isRunning)
              ElevatedButton.icon(
                onPressed: controller.startRun,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start run'),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: run.isPaused ? controller.resumeRun : controller.pauseRun,
                      icon: Icon(run.isPaused ? Icons.play_arrow : Icons.pause),
                      label: Text(run.isPaused ? 'Resume' : 'Pause'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: controller.stopRun,
                      icon: const Icon(Icons.stop),
                      label: const Text('Stop & Save'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.white60)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}