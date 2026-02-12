import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A0F1F), Color(0xFF222B52), Color(0xFF4F46E5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                const Text('RUNMATE', style: TextStyle(fontSize: 14, letterSpacing: 2.5))
                    .animate()
                    .fadeIn(duration: 600.ms),
                const SizedBox(height: 10),
                const Text(
                  'Track every run\nlike a pro.',
                  style: TextStyle(fontSize: 42, fontWeight: FontWeight.w800, height: 1.1),
                ).animate().slideY(begin: .3, duration: 700.ms),
                const SizedBox(height: 16),
                const Text('Realtime GPS, clean analytics, team mode and XP in one app.'),
                const Spacer(),
                ElevatedButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Login'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => context.go('/register'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(54)),
                  child: const Text('Create account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}