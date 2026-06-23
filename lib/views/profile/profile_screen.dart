import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/proximity_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../utils/haptics.dart';
import '../../viewmodels/collections_view_model.dart';
import '../../viewmodels/theme_controller.dart';
import '../../widgets/concierge_card.dart';
import '../referral/referral_screen.dart';

/// Ecran profil simple : identite, statut freemium, raccourcis.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final collections = context.watch<CollectionsViewModel>().collections;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.person, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 12),
                Text('Alex', style: AppTypography.title),
                Text('gnemmialex@gmail.com', style: AppTypography.caption),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text('Apparence', style: AppTypography.subtitle),
          const SizedBox(height: 8),
          const _ThemeSelector(),
          const SizedBox(height: 16),

          Text('Notifications', style: AppTypography.subtitle),
          const SizedBox(height: 8),
          const _ProximityToggleCard(),
          const SizedBox(height: 16),

          Text('Parametres', style: AppTypography.subtitle),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.support_agent, color: Color(0xFF25D366)),
              title: const Text('Conciergerie'),
              subtitle: const Text(
                  'Réservation, renseignements, recommandations (WhatsApp)'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showConciergeSheet(context),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.card_giftcard, color: AppColors.accent),
              title: const Text('Parrainage'),
              subtitle: const Text('Code + recompenses (+5 lieux / 5 j Premium)'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ReferralScreen()),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Statistiques', style: AppTypography.subtitle),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.collections_bookmark,
                  color: AppColors.primary),
              title: const Text('Mes collections'),
              trailing: Text('${collections.length}',
                  style: AppTypography.subtitle),
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte de reglage des alertes de proximite.
class _ProximityToggleCard extends StatelessWidget {
  const _ProximityToggleCard();

  @override
  Widget build(BuildContext context) {
    final proximity = context.watch<ProximityService>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.notifications_active,
                  color: AppColors.primary),
              title: const Text('Alertes à proximité'),
              subtitle: Text(
                'Recevez une notification quand vous passez près d\'un lieu '
                'enregistré dans Paris.',
                style: AppTypography.caption,
              ),
              value: proximity.enabled,
              onChanged: proximity.busy
                  ? null
                  : (v) async {
                      Haptics.selection();
                      final ok = await proximity.setEnabled(v);
                      if (!context.mounted) return;
                      if (v && !ok) {
                        Haptics.warning();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Autorisez la localisation et les notifications '
                                'pour activer les alertes.'),
                          ),
                        );
                      }
                    },
            ),
            const Divider(height: 16),
            Row(
              children: [
                Icon(Icons.info_outline,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Nécessite l\'accès à votre position en continu. '
                    'Désactivable à tout moment ici.',
                    style: AppTypography.caption
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Selecteur de theme : Auto (selon l'heure) / Clair / Sombre.
class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector();

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<ThemeController>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(ctrl.isDark ? Icons.dark_mode : Icons.light_mode,
                    color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ctrl.mode == AppThemeMode.auto
                        ? 'Auto : sombre de 20h a 6h (actuellement ${ctrl.isDark ? 'sombre' : 'clair'})'
                        : 'Theme ${ctrl.isDark ? 'sombre' : 'clair'}',
                    style: AppTypography.caption,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SegmentedButton<AppThemeMode>(
              segments: const [
                ButtonSegment(
                  value: AppThemeMode.auto,
                  label: Text('Auto'),
                  icon: Icon(Icons.schedule),
                ),
                ButtonSegment(
                  value: AppThemeMode.light,
                  label: Text('Clair'),
                  icon: Icon(Icons.light_mode),
                ),
                ButtonSegment(
                  value: AppThemeMode.dark,
                  label: Text('Sombre'),
                  icon: Icon(Icons.dark_mode),
                ),
              ],
              selected: {ctrl.mode},
              onSelectionChanged: (s) =>
                  context.read<ThemeController>().setMode(s.first),
            ),
            const Divider(height: 20),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: Icon(
                ctrl.mapIsDark ? Icons.map : Icons.map_outlined,
                color: AppColors.primary,
              ),
              title: const Text('Assombrir aussi la carte'),
              subtitle: Text(
                ctrl.mapFollowsDark
                    ? 'Toute l\'app + la carte passent en sombre la nuit.'
                    : 'Toute l\'app en sombre, mais la carte reste claire.',
                style: AppTypography.caption,
              ),
              value: ctrl.mapFollowsDark,
              onChanged: (v) =>
                  context.read<ThemeController>().setMapFollowsDark(v),
            ),
          ],
        ),
      ),
    );
  }
}
