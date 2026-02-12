import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_controller.dart';
import 'auth_service.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
   Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final authController = ref.read(authControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Choose profile')),
      body: Padding(
        padding: const EdgeInsets.all(20),
         child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Authorization is configured for two prepared database profiles.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            if (auth.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  auth.errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
              for (final profile in AuthService.preparedProfiles)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: FilledButton.tonalIcon(
                  onPressed: auth.isLoading
                      ? null
                      : () => authController.loginPreparedProfile(profile),
                  icon: const Icon(Icons.account_circle_outlined),
                  label: Text('${profile.label} (${profile.email})'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    alignment: Alignment.centerLeft,
                  ),
                    ),
                    ),
                    if (auth.isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Center(
                  child: SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ],),
      ),
    );
  }
}