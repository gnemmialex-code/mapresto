import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/collection_style.dart';
import '../../models/user_collection.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../viewmodels/collections_view_model.dart';
import '../../widgets/primary_button.dart';
import '../profile/profile_screen.dart';
import 'collection_detail_screen.dart';

/// Liste des collections de l'utilisateur + import par code + creation.
class CollectionsScreen extends StatelessWidget {
  const CollectionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CollectionsViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Collections'),
        actions: [
          IconButton(
            tooltip: 'Profil',
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---- Import par code ----
          const _ImportCodeCard(),
          const SizedBox(height: 20),

          Row(
            children: [
              Text('Mes collections', style: AppTypography.subtitle),
              const Spacer(),
              Text('${vm.collections.length}', style: AppTypography.caption),
            ],
          ),
          const SizedBox(height: 8),
          for (final c in vm.collections)
            _CollectionTile(collection: c),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Creer une nouvelle collection',
            icon: Icons.add,
            onPressed: () => _showCreateDialog(context, vm),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context, CollectionsViewModel vm) {
    final controller = TextEditingController();
    CollectionStyle selected = vm.availableStyles.first;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: const Text('Nouvelle collection'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Nom du proprietaire',
                  hintText: 'ex: Alex',
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Style', style: AppTypography.caption),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in vm.availableStyles)
                    ChoiceChip(
                      label: Text(s.name),
                      selected: selected.id == s.id,
                      selectedColor: s.primaryColor,
                      labelStyle: AppTypography.tag.copyWith(
                        color: selected.id == s.id
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                      onSelected: (_) => setState(() => selected = s),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () {
                vm.createCollection(
                  name: controller.text.trim().isEmpty
                      ? 'Moi'
                      : controller.text.trim(),
                  style: selected,
                );
                Navigator.of(context).pop();
              },
              child: const Text('Creer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CollectionTile extends StatelessWidget {
  const _CollectionTile({required this.collection});
  final UserCollection collection;

  @override
  Widget build(BuildContext context) {
    final color = collection.style.primaryColor;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: const Icon(Icons.collections_bookmark, color: Colors.white),
        ),
        title: Text(collection.style.name, style: AppTypography.subtitle),
        subtitle: Text(
          '${collection.places.length} lieux'
          '${collection.code.isNotEmpty ? ' · ${collection.code}' : ''}',
          style: AppTypography.caption,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CollectionDetailScreen(collection: collection),
          ),
        ),
      ),
    );
  }
}

class _ImportCodeCard extends StatefulWidget {
  const _ImportCodeCard();

  @override
  State<_ImportCodeCard> createState() => _ImportCodeCardState();
}

class _ImportCodeCardState extends State<_ImportCodeCard> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _import() {
    final vm = context.read<CollectionsViewModel>();
    final imported = vm.importByCode(_controller.text);
    if (imported == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code invalide.')),
      );
      return;
    }
    _controller.clear();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CollectionDetailScreen(collection: imported),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Entrer un code de partage', style: AppTypography.subtitle),
            const SizedBox(height: 4),
            Text(
              'Chargez la collection d\'un autre utilisateur.',
              style: AppTypography.caption,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      hintText: 'PARIS-CHIC-1234',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _import(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _import,
                  child: const Text('Charger'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
