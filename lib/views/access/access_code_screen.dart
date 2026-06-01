import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../viewmodels/collections_view_model.dart';
import '../../widgets/primary_button.dart';
import 'private_map_screen.dart';

/// Ecran "Code" : saisir un code pour acceder au plan prive d'un influenceur.
class AccessCodeScreen extends StatefulWidget {
  const AccessCodeScreen({super.key});

  @override
  State<AccessCodeScreen> createState() => _AccessCodeScreenState();
}

class _AccessCodeScreenState extends State<AccessCodeScreen> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _access([String? code]) {
    final value = code ?? _controller.text;
    if (value.trim().isEmpty) {
      setState(() => _error = 'Entrez un code.');
      return;
    }
    final vm = context.read<CollectionsViewModel>();
    final collection = vm.importByCode(value);
    if (collection == null) {
      setState(() => _error = 'Code invalide ou expire.');
      return;
    }
    setState(() => _error = null);
    FocusScope.of(context).unfocus();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PrivateMapScreen(collection: collection),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final examples = context.watch<CollectionsViewModel>().influencerShowcase;

    return Scaffold(
      appBar: AppBar(title: const Text('Acceder via un code')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.vpn_key, color: Colors.white, size: 32),
                const SizedBox(height: 10),
                Text('Plan prive',
                    style:
                        AppTypography.title.copyWith(color: Colors.white)),
                const SizedBox(height: 4),
                Text(
                  'Entrez le code partage par un influenceur ou un ami pour '
                  'debloquer sa carte d\'adresses.',
                  style: AppTypography.body.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.go,
            onSubmitted: _access,
            decoration: InputDecoration(
              labelText: 'Code d\'acces',
              hintText: 'LEA-PARIS-2024',
              prefixIcon: const Icon(Icons.tag),
              border: const OutlineInputBorder(),
              errorText: _error,
            ),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: 'Acceder au plan',
            icon: Icons.lock_open,
            onPressed: () => _access(),
          ),
          const SizedBox(height: 28),
          Text('Essayer un exemple', style: AppTypography.subtitle),
          const SizedBox(height: 8),
          for (final c in examples)
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: c.style.primaryColor,
                  child: const Icon(Icons.star, color: Colors.white),
                ),
                title: Text(c.style.name),
                subtitle: Text('${c.authorHandle ?? ''}  ·  ${c.code}',
                    style: AppTypography.caption),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () => _access(c.code),
              ),
            ),
        ],
      ),
    );
  }
}
