import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../viewmodels/collections_view_model.dart';
import '../../widgets/primary_button.dart';

/// Ecran Parrainage : partager son code, suivre ses recompenses, saisir un code.
class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  final _codeInput = TextEditingController();

  @override
  void dispose() {
    _codeInput.dispose();
    super.dispose();
  }

  void _redeem(CollectionsViewModel vm) {
    final result = vm.redeemReferralCode(_codeInput.text);
    final messenger = ScaffoldMessenger.of(context);
    switch (result) {
      case ReferralResult.success:
        _codeInput.clear();
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.celebration, color: AppColors.premium),
                SizedBox(width: 8),
                Text('Parrainage valide !'),
              ],
            ),
            content: Text(
              'Le parrain gagne +${CollectionsViewModel.referralBonusPlaces} '
              'lieux sur sa carte perso et les filtres Premium pendant '
              '${CollectionsViewModel.referralPremiumDuration.inDays} jours.\n\n'
              '(Demo : la recompense est appliquee a votre compte pour que '
              'vous puissiez la voir.)',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Super !'),
              ),
            ],
          ),
        );
      case ReferralResult.ownCode:
        messenger.showSnackBar(const SnackBar(
            content: Text('Vous ne pouvez pas utiliser votre propre code.')));
      case ReferralResult.invalid:
        messenger.showSnackBar(
            const SnackBar(content: Text('Code de parrainage invalide.')));
    }
  }

  void _share(String code) {
    final uri = Uri.parse(
      'mailto:?subject=${Uri.encodeComponent('Rejoins-moi sur ParisMap')}'
      '&body=${Uri.encodeComponent('Telecharge ParisMap Video Guide et entre mon code de parrainage dans les parametres : $code')}',
    );
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CollectionsViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Parrainage')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ---- Explication recompense ----
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.card_giftcard,
                    color: AppColors.premium, size: 32),
                const SizedBox(height: 10),
                Text('Parrainez vos amis',
                    style: AppTypography.title.copyWith(color: Colors.white)),
                const SizedBox(height: 6),
                Text(
                  'Pour chaque ami qui telecharge l\'app et entre votre code : '
                  '+${CollectionsViewModel.referralBonusPlaces} lieux sur votre '
                  'carte perso et les filtres Premium pendant '
                  '${CollectionsViewModel.referralPremiumDuration.inDays} jours.',
                  style: AppTypography.body.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ---- Mon code ----
          Text('Mon code de parrainage', style: AppTypography.subtitle),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    vm.referralCode,
                    style: AppTypography.title
                        .copyWith(color: AppColors.primary, letterSpacing: 1),
                  ),
                ),
                IconButton(
                  tooltip: 'Copier',
                  icon: const Icon(Icons.copy, color: AppColors.primary),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: vm.referralCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Code copie !')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          PrimaryButton(
            label: 'Partager mon code',
            icon: Icons.ios_share,
            onPressed: () => _share(vm.referralCode),
          ),
          const SizedBox(height: 24),

          // ---- Mes recompenses ----
          Text('Mes recompenses', style: AppTypography.subtitle),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.group,
                  value: '${vm.referralCount}',
                  label: 'Filleuls',
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  icon: Icons.add_location_alt,
                  value: '+${vm.bonusPlaces}',
                  label: 'Lieux bonus',
                  color: AppColors.hotel,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  icon: Icons.workspace_premium,
                  value: vm.isPremiumActive ? 'J-${vm.premiumDaysLeft}' : 'Non',
                  label: 'Premium',
                  color: AppColors.premium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ---- Saisir un code (filleul) ----
          Text('J\'ai un code de parrainage', style: AppTypography.subtitle),
          const SizedBox(height: 4),
          Text(
            'Entrez le code d\'un ami pour le recompenser.',
            style: AppTypography.caption,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _codeInput,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    hintText: 'PARIS-PARRAIN-1234',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _redeem(vm),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => _redeem(vm),
                child: const Text('Valider'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 6),
          Text(value, style: AppTypography.subtitle.copyWith(color: color)),
          const SizedBox(height: 2),
          Text(label, style: AppTypography.caption, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
