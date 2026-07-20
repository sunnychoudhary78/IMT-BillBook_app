import 'package:flutter/material.dart';

class GlobalLoader extends StatelessWidget {
  final String message;
  const GlobalLoader({super.key, this.message = 'Please wait...'});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black45,
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(message),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GlobalSuccess extends StatelessWidget {
  final String message;
  const GlobalSuccess({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return _ToastBanner(
      icon: Icons.check_circle,
      color: Colors.green.shade700,
      message: message,
    );
  }
}

class GlobalError extends StatelessWidget {
  final String message;
  const GlobalError({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return _ToastBanner(
      icon: Icons.error,
      color: Colors.red.shade700,
      message: message,
    );
  }
}

class GlobalMessage extends StatelessWidget {
  final String message;
  const GlobalMessage({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return _ToastBanner(
      icon: Icons.info,
      color: Theme.of(context).colorScheme.primary,
      message: message,
    );
  }
}

class _ToastBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String message;

  const _ToastBanner({
    required this.icon,
    required this.color,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(12),
            color: color,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: Colors.white),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      message,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
