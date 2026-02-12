import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/auth_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final controller = ref.read(authControllerProvider.notifier);
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(user?.userMetadata?['username']?.toString() ?? 'Runner'),
                subtitle: Text(user?.email ?? 'no-email'),
              ),
            ),
            const SizedBox(height: 12),
            const Card(
              child: ListTile(
                title: Text('Team'),
                subtitle: Text('Red'),
                trailing: Icon(Icons.flag_rounded),
              ),
            ),
            const Card(
              child: ListTile(
                title: Text('Total distance'),
                subtitle: Text('42.3 km'),
              ),
            ),
            const Card(
              child: ListTile(
                title: Text('XP'),
                subtitle: Text('870 XP'),
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: auth.isLoading ? null : controller.logout,
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}