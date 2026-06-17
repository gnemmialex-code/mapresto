import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../viewmodels/collections_view_model.dart';
import '../around/around_me_screen.dart';
import '../access/access_code_screen.dart';
import '../access/private_map_screen.dart';
import '../perfect/perfect_form_screen.dart';
import '../profile/profile_screen.dart';
import '../referral/referral_screen.dart';
import '../suggest/suggest_place_screen.dart';
import '../suggestion/suggestion_form_screen.dart';
import 'create_my_map_screen.dart';
import 'creator_space_screen.dart';

/// Hub "Mon Espace" : organise en sections (profil, decouvrir, mes cartes,
/// vitrine influenceurs, communaute).
class MapsHubScreen extends StatelessWidget {
  const MapsHubScreen({super.key});

  void _go(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CollectionsViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Mon Espace')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // ---- En-tete profil ----
          _ProfileHeader(
            creator: vm.isCreatorUnlocked,
            onTap: () => _go(context, const ProfileScreen()),
          ),
          const SizedBox(height: 16),

          // ---- Hero : Je crée ma carte ----
          _MyMapHeroCard(
            count: vm.myMapCount,
            limit: vm.mapLimit,
            unlocked: vm.isCreatorUnlocked,
            onTap: () => _go(context, const CreateMyMapScreen()),
          ),

          // ---- Decouvrir ----
          const _SectionHeader('Decouvrir', icon: Icons.explore_outlined),
          _FeatureGrid(items: [
            _Feature(
              color: AppColors.accent,
              icon: Icons.auto_awesome,
              title: 'Carte sur-mesure',
              caption: 'Selon vos gouts',
              onTap: () => _go(context, const SuggestionFormScreen()),
            ),
            _Feature(
              color: AppColors.hotel,
              icon: Icons.route,
              title: 'Adresse parfaite',
              caption: 'Itineraire midi/soir',
              onTap: () => _go(context, const PerfectFormScreen()),
            ),
            _Feature(
              color: AppColors.restaurant,
              icon: Icons.my_location,
              title: 'Autour de moi',
              caption: '100 m a 15 km',
              onTap: () => _go(context, const AroundMeScreen()),
            ),
            _Feature(
              color: AppColors.primary,
              icon: Icons.vpn_key,
              title: 'Plan prive',
              caption: 'Acceder via un code',
              onTap: () => _go(context, const AccessCodeScreen()),
            ),
          ]),

          // ---- Mes cartes ----
          const _SectionHeader('Mes cartes', icon: Icons.map_outlined),
          _HubCard(
            color: AppColors.premium,
            icon: Icons.workspace_premium,
            title: 'Espace Influenceur',
            subtitle: vm.isCreatorUnlocked
                ? 'Actif - adresses illimitees, style perso, partage.'
                : 'Adresses illimitees, filtres avances, style & code.',
            badge: vm.isCreatorUnlocked ? 'ACTIF' : 'PRO',
            onTap: () => _go(context, const CreatorSpaceScreen()),
          ),

          // ---- Vitrine influenceurs ----
          const _SectionHeader('Cartes d\'influenceurs',
              icon: Icons.verified_outlined),
          SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: vm.influencerShowcase.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final c = vm.influencerShowcase[i];
                return _ShowcaseCard(
                  onTap: () =>
                      _go(context, PrivateMapScreen(collection: c)),
                  color: c.style.primaryColor,
                  name: c.style.name,
                  handle: c.authorHandle ?? '',
                  count: c.places.length,
                );
              },
            ),
          ),

          // ---- Communaute ----
          const _SectionHeader('Communaute', icon: Icons.groups_outlined),
          _FeatureGrid(items: [
            _Feature(
              color: AppColors.accent,
              icon: Icons.card_giftcard,
              title: 'Parrainage',
              caption: vm.referralCount > 0
                  ? '${vm.referralCount} filleul(s)'
                  : '+5 lieux / filleul',
              onTap: () => _go(context, const ReferralScreen()),
            ),
            _Feature(
              color: AppColors.restaurant,
              icon: Icons.add_business_outlined,
              title: 'Suggerer un lieu',
              caption: 'Manquant sur la carte',
              onTap: () => _go(context, const SuggestPlaceScreen()),
            ),
          ]),
        ],
      ),
    );
  }
}

/// Hero card "Je crée ma carte" — affiché en premiere position dans le hub.
class _MyMapHeroCard extends StatelessWidget {
  const _MyMapHeroCard({
    required this.count,
    required this.limit,
    required this.unlocked,
    required this.onTap,
  });

  final int count;
  final int limit;
  final bool unlocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const cardColor = Color(0xFF5B4FE9);
    final ratio = unlocked ? 1.0 : (count / limit).clamp(0.0, 1.0);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF5B4FE9), Color(0xFF8B7FFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x405B4FE9),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.add_location_alt,
                        color: Colors.white, size: 26),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Je crée ma carte',
                        style: AppTypography.title
                            .copyWith(color: Colors.white, fontSize: 18),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        unlocked ? '$count lieux' : '$count / $limit',
                        style: AppTypography.caption.copyWith(
                            color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        unlocked
                            ? 'Adresses illimitees · style perso · partage'
                            : 'Sauvegardez vos adresses favorites et partagez votre carte',
                        style: AppTypography.caption
                            .copyWith(color: Colors.white70),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Ouvrir',
                        style: AppTypography.caption.copyWith(
                          color: cardColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// En-tete avec le statut du compte.
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.creator, required this.onTap});
  final bool creator;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.person, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bonjour Alex',
                          style: AppTypography.title
                              .copyWith(color: Colors.white)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            creator
                                ? Icons.workspace_premium
                                : Icons.lock_open,
                            size: 14,
                            color: AppColors.premium,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            creator ? 'Plan Createur' : 'Compte gratuit',
                            style: AppTypography.caption
                                .copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white70),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Titre de section avec icone et separateur.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title, {required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(child: Divider(height: 1)),
        ],
      ),
    );
  }
}

/// Donnees d'une tuile de fonctionnalite.
class _Feature {
  final Color color;
  final IconData icon;
  final String title;
  final String caption;
  final VoidCallback onTap;
  const _Feature({
    required this.color,
    required this.icon,
    required this.title,
    required this.caption,
    required this.onTap,
  });
}

/// Grille de tuiles (2 par ligne).
class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid({required this.items});
  final List<_Feature> items;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += 2) {
      final left = items[i];
      final right = i + 1 < items.length ? items[i + 1] : null;
      rows.add(Row(
        children: [
          Expanded(child: _FeatureTile(left)),
          const SizedBox(width: 12),
          Expanded(
            child: right != null ? _FeatureTile(right) : const SizedBox(),
          ),
        ],
      ));
      if (i + 2 < items.length) rows.add(const SizedBox(height: 12));
    }
    return Column(children: rows);
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile(this.data);
  final _Feature data;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 122,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(data.icon, color: data.color, size: 22),
              ),
              const Spacer(),
              Text(data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.subtitle),
              const SizedBox(height: 2),
              Text(data.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption),
            ],
          ),
        ),
      ),
    );
  }
}

/// Grande carte pour la section "Mes cartes".
class _HubCard extends StatelessWidget {
  const _HubCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(title, style: AppTypography.subtitle),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              badge!,
                              style: AppTypography.tag
                                  .copyWith(color: Colors.white, fontSize: 9),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: AppTypography.caption),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShowcaseCard extends StatelessWidget {
  const _ShowcaseCard({
    required this.onTap,
    required this.color,
    required this.name,
    required this.handle,
    required this.count,
  });

  final VoidCallback onTap;
  final Color color;
  final String name;
  final String handle;
  final int count;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient:
              LinearGradient(colors: [color, color.withValues(alpha: 0.7)]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Icon(Icons.verified, color: Colors.white),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        AppTypography.subtitle.copyWith(color: Colors.white)),
                Text(handle,
                    style:
                        AppTypography.caption.copyWith(color: Colors.white70)),
                const SizedBox(height: 4),
                Text('$count adresses · code',
                    style: AppTypography.tag.copyWith(color: Colors.white)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
