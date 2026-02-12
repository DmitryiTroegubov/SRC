import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            options: const MapOptions(initialCenter: LatLng(55.751244, 37.618423), initialZoom: 14),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.flutter_application_1',
              ),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: const [
                      Chip(label: Text('Zone: Center')),
                      SizedBox(width: 8),
                      Chip(label: Text('Weather: +14°C')),
                    ],
                  ),
                  const Spacer(),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Quick Route', style: TextStyle(fontWeight: FontWeight.w700)),
                              SizedBox(height: 4),
                              Text('River loop • 5.2 km • easy pace'),
                            ],
                          ),
                          FloatingActionButton.extended(
                            onPressed: () => context.go('/run'),
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: const Text('Start'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}