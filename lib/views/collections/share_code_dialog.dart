import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/user_collection.dart';
import '../../theme/app_typography.dart';

/// Dialog affichant le code de partage d'une collection.
class ShareCodeDialog extends StatelessWidget {
  const ShareCodeDialog({
    super.key,
    required this.collection,
    required this.code,
  });

  final UserCollection collection;
  final String code;

  static Future<void> show(
    BuildContext context, {
    required UserCollection collection,
    required String code,
  }) {
    return showDialog(
      context: context,
      builder: (_) => ShareCodeDialog(collection: collection, code: code),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = collection.style.primaryColor;
    return AlertDialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Partager la collection'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Communiquez ce code pour partager "${collection.style.name}".',
            style: AppTypography.caption,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Text(
              code,
              style: AppTypography.title.copyWith(color: color, letterSpacing: 1),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fermer'),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: color),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: code));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Code copie !')),
            );
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.copy, size: 18),
          label: const Text('Copier'),
        ),
      ],
    );
  }
}
