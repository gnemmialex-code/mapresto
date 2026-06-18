import 'package:flutter/material.dart';

import '../models/place.dart';
import '../services/concierge_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/haptics.dart';

/// Vert WhatsApp (reconnaissable instantanement).
const _kWhatsApp = Color(0xFF25D366);
const _kWhatsAppDark = Color(0xFF128C7E);

/// Grande carte "Conciergerie" — point d'entree visible vers WhatsApp Business.
class ConciergeCard extends StatelessWidget {
  const ConciergeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Haptics.light();
          showConciergeSheet(context);
        },
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_kWhatsApp, _kWhatsAppDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x3325D366),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.support_agent,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Conciergerie',
                              style: AppTypography.title
                                  .copyWith(color: Colors.white, fontSize: 18)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('WhatsApp',
                                style: AppTypography.tag
                                    .copyWith(color: Colors.white)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Réservation, renseignements, recommandations — '
                        'on s\'occupe de tout pour vous.',
                        style:
                            AppTypography.caption.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bandeau conciergerie affiche DANS la fiche d'un lieu.
///
/// Important : on precise clairement que ce numero N'EST PAS celui de
/// l'etablissement, mais celui de la conciergerie mapresto (service pro qui
/// s'occupe de tout : reservation, renseignements, recommandations...).
class ConciergePlaceBanner extends StatelessWidget {
  const ConciergePlaceBanner({super.key, required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _kWhatsApp.withValues(alpha: 0.12),
            _kWhatsApp.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kWhatsApp.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: _kWhatsApp.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.support_agent,
                    color: _kWhatsAppDark, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Conciergerie mapresto',
                        style: AppTypography.subtitle
                            .copyWith(fontWeight: FontWeight.w700)),
                    Text('Réservation · infos · recommandations',
                        style: AppTypography.caption
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Mention essentielle pour ne pas tromper l'utilisateur.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline,
                  size: 15, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Ce n\'est pas le numéro de l\'établissement : c\'est notre '
                  'ligne pro qui s\'occupe de tout pour vous (réservation, '
                  'questions, bons plans).',
                  style: AppTypography.caption
                      .copyWith(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                Haptics.light();
                showConciergeSheet(
                  context,
                  customMessage: ConciergeService.messageForPlace(place),
                );
              },
              icon: const Icon(Icons.chat, size: 18),
              label: const Text('Demander pour ce lieu (WhatsApp)'),
              style: FilledButton.styleFrom(
                backgroundColor: _kWhatsApp,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Feuille d'options de la conciergerie : on propose explicitement tous les
/// services puis on ouvre WhatsApp avec un message pre-rempli adapte.
Future<void> showConciergeSheet(BuildContext context, {String? customMessage}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _ConciergeSheet(customMessage: customMessage),
  );
}

class _ConciergeOption {
  final IconData icon;
  final String label;
  final String message;
  const _ConciergeOption(this.icon, this.label, this.message);
}

class _ConciergeSheet extends StatelessWidget {
  const _ConciergeSheet({this.customMessage});
  final String? customMessage;

  static const List<_ConciergeOption> _options = [
    _ConciergeOption(Icons.event_available, 'Réserver une table',
        'Bonjour 👋 J\'aimerais réserver une table. Voici mes infos :'),
    _ConciergeOption(Icons.info_outline, 'Renseignements',
        'Bonjour 👋 J\'ai une question / besoin de renseignements :'),
    _ConciergeOption(Icons.auto_awesome, 'Recommandation perso',
        'Bonjour 👋 Pouvez-vous me recommander des adresses selon mes envies ?'),
    _ConciergeOption(Icons.celebration, 'Organiser une soirée / événement',
        'Bonjour 👋 J\'organise une soirée / un événement et j\'aimerais de l\'aide :'),
    _ConciergeOption(Icons.chat_bubble_outline, 'Autre demande',
        'Bonjour 👋 J\'ai une demande pour la conciergerie mapresto :'),
  ];

  Future<void> _open(BuildContext context, String message) async {
    Haptics.medium();
    final ok = await ConciergeService.openWhatsApp(message: message);
    if (!context.mounted) return;
    Navigator.of(context).pop();
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d\'ouvrir WhatsApp. Est-il installé ?'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.support_agent, color: _kWhatsApp, size: 26),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Votre conciergerie', style: AppTypography.title),
                      Text('Réponse rapide sur WhatsApp',
                          style: AppTypography.caption
                              .copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (customMessage != null) ...[
              _ConciergeTile(
                icon: Icons.place,
                label: 'Demander pour ce lieu',
                highlight: true,
                onTap: () => _open(context, customMessage!),
              ),
              const SizedBox(height: 4),
              const Divider(),
              const SizedBox(height: 4),
            ],
            for (final o in _options)
              _ConciergeTile(
                icon: o.icon,
                label: o.label,
                onTap: () => _open(context, o.message),
              ),
            if (!ConciergeService.isConfigured) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '⚠️ Numéro WhatsApp non configuré (ConciergeService.whatsappNumber).',
                  style: AppTypography.caption
                      .copyWith(color: Colors.orange.shade800),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ConciergeTile extends StatelessWidget {
  const _ConciergeTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlight = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: highlight
            ? _kWhatsApp.withValues(alpha: 0.12)
            : AppColors.background,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: _kWhatsApp, size: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(label,
                      style: AppTypography.body
                          .copyWith(fontWeight: FontWeight.w600)),
                ),
                Icon(Icons.arrow_forward_ios,
                    size: 14, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
