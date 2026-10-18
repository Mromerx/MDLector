import 'package:flutter/material.dart';

/// Common header for the app dialogs (settings, etc.).
///
/// Shows the icon inside a tinted capsule next to the title. This is the only
/// place that defines the header look, so every dialog is identical.
class DialogHeader extends StatelessWidget {
  const DialogHeader({super.key, required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: scheme.secondaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: scheme.onSecondaryContainer),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(title)),
      ],
    );
  }
}
