import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../viewmodels/collections_view_model.dart';
import '../../widgets/primary_button.dart';
import '../collections/share_code_dialog.dart';
import '../place_detail/place_detail_screen.dart';
import '../places/place_card_widget.dart';
import 'mini_map_view.dart';
import 'place_picker_sheet.dart';

/// Espace Influenceur / Createur : adresses illimitees, style personnalise,
/// publication d'un code pour la communaute.
class CreatorSpaceScreen extends StatelessWidget {
  const CreatorSpaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CollectionsViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Espace Influenceur')),
      body: vm.isCreatorUnlocked
          ? const _CreatorEditor()
          : const _CreatorUpsell(),
    );
  }
}

/// Vue de vente avant deblocage du plan Createur.
class _CreatorUpsell extends StatelessWidget {
  const _CreatorUpsell();

  @override
  Widget build(BuildContext context) {
    final vm = context.read<CollectionsViewModel>();
    const benefits = [
      ('Adresses illimitees', Icons.all_inclusive),
      ('Tous les filtres avances', Icons.tune),
      ('Style perso (couleur, design)', Icons.palette),
      ('Code de partage pour ta communaute', Icons.qr_code_2),
      ('Badge verifie', Icons.verified),
    ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.workspace_premium,
                  color: AppColors.premium, size: 36),
              const SizedBox(height: 10),
              Text('Deviens Createur',
                  style: AppTypography.title.copyWith(color: Colors.white)),
              const SizedBox(height: 6),
              Text(
                'Repertorie toutes tes adresses (sans limite), filtre-les '
                'finement et partage ta carte stylee avec ta communaute.',
                style: AppTypography.body.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        for (final b in benefits)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(b.$2, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(child: Text(b.$1, style: AppTypography.body)),
                const Icon(Icons.check, color: Colors.green, size: 18),
              ],
            ),
          ),
        const SizedBox(height: 20),
        // >>> POINT DE BRANCHEMENT PAYWALL <<<
        // Remplacer par un vrai achat ; appeler vm.unlockCreator() au succes.
        PrimaryButton(
          label: 'Activer le plan Createur (demo)',
          icon: Icons.lock_open,
          color: AppColors.premium,
          onPressed: () {
            vm.unlockCreator();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Plan Createur active.')),
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          'Demo : aucun paiement reel. Le bouton debloque simplement les '
          'fonctionnalites Createur.',
          textAlign: TextAlign.center,
          style: AppTypography.caption,
        ),
      ],
    );
  }
}

/// Editeur de la carte du createur (style + lieux + publication).
class _CreatorEditor extends StatefulWidget {
  const _CreatorEditor();

  @override
  State<_CreatorEditor> createState() => _CreatorEditorState();
}

class _CreatorEditorState extends State<_CreatorEditor> {
  late final TextEditingController _name;
  late final TextEditingController _handle;
  late final TextEditingController _desc;

  static const List<Color> _palette = [
    Color(0xFF6C5CE7),
    Color(0xFFE84393),
    Color(0xFF0984E3),
    Color(0xFF00B894),
    Color(0xFFE17055),
    Color(0xFFB71C1C),
    Color(0xFFFDA7DF),
    Color(0xFF2D3436),
  ];
  static const List<String> _iconStyles = ['minimal', 'bold', 'outline'];

  @override
  void initState() {
    super.initState();
    final m = context.read<CollectionsViewModel>().myMap;
    _name = TextEditingController(text: m.style.name);
    _handle = TextEditingController(text: m.authorHandle ?? '');
    _desc = TextEditingController(text: m.style.description ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _handle.dispose();
    _desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CollectionsViewModel>();
    final map = vm.myMap;
    final color = map.style.primaryColor;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ---- Apercu en direct ----
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.7)]),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white24,
                child: Text(
                  map.style.name.isNotEmpty ? map.style.name[0] : 'M',
                  style: AppTypography.title.copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            map.style.name.isEmpty ? 'Ma carte' : map.style.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.subtitle
                                .copyWith(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.verified,
                            color: Colors.white, size: 16),
                      ],
                    ),
                    Text(
                      map.authorHandle?.isNotEmpty == true
                          ? map.authorHandle!
                          : '@mon.handle',
                      style: AppTypography.caption
                          .copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Text('${map.places.length}',
                  style: AppTypography.title.copyWith(color: Colors.white)),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Text('Personnaliser le style', style: AppTypography.subtitle),
        const SizedBox(height: 10),
        TextField(
          controller: _name,
          decoration: const InputDecoration(
            labelText: 'Nom de la carte',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: (v) => vm.updateMyMapStyle(name: v),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _handle,
          decoration: const InputDecoration(
            labelText: 'Handle (@...)',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: (v) => vm.updateMyMapStyle(handle: v),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _desc,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: (v) => vm.updateMyMapStyle(description: v),
        ),
        const SizedBox(height: 16),

        Text('Couleur', style: AppTypography.caption),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final c in _palette)
              GestureDetector(
                onTap: () => vm.updateMyMapStyle(color: c),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.toARGB32() == c.toARGB32()
                          ? Colors.black
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: color.toARGB32() == c.toARGB32()
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : null,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        Text('Design des icones', style: AppTypography.caption),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final s in _iconStyles)
              ChoiceChip(
                label: Text(s),
                selected: map.style.iconStyle == s,
                selectedColor: color,
                labelStyle: AppTypography.tag.copyWith(
                  color: map.style.iconStyle == s
                      ? Colors.white
                      : AppColors.textPrimary,
                ),
                onSelected: (_) => vm.updateMyMapStyle(iconStyle: s),
              ),
          ],
        ),
        const SizedBox(height: 24),

        // ---- Lieux (illimites) ----
        Row(
          children: [
            Text('Mes adresses (${map.places.length})',
                style: AppTypography.subtitle),
            const Spacer(),
            TextButton.icon(
              onPressed: () => PlacePickerSheet.show(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Ajouter'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        MiniMapView(places: map.places, color: color),
        const SizedBox(height: 12),
        for (final p in map.places)
          Dismissible(
            key: ValueKey(p.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: Colors.red.shade400,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (_) => vm.removeFromMyMap(p),
            child: PlaceCardWidget(
              place: p,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PlaceDetailScreen(place: p),
                ),
              ),
            ),
          ),
        const SizedBox(height: 16),

        PrimaryButton(
          label: 'Publier & generer le code',
          icon: Icons.ios_share,
          color: color,
          onPressed: map.places.isEmpty
              ? null
              : () {
                  final code = vm.publishMyMap();
                  ShareCodeDialog.show(context,
                      collection: vm.myMap, code: code);
                },
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
