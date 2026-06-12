import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/contribution.dart';
import '../../models/place.dart';
import '../../services/submission_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/place_visuals.dart';
import '../../viewmodels/places_view_model.dart';
import '../../widgets/photo_picker_field.dart';
import '../../widgets/primary_button.dart';

/// "Donner mon avis" : avis sur un lieu existant (selecteur avec recherche)
/// ou sur un lieu pas encore en ligne, note 1-5 etoiles, commentaire,
/// photos optionnelles. Envoye dans Supabase (table `review_submissions`).
class ReviewFormScreen extends StatefulWidget {
  const ReviewFormScreen({super.key});

  @override
  State<ReviewFormScreen> createState() => _ReviewFormScreenState();
}

class _ReviewFormScreenState extends State<ReviewFormScreen> {
  final _service = SubmissionService();

  final _comment = TextEditingController();
  final _newPlaceName = TextEditingController();
  final _newPlaceAddress = TextEditingController();
  final _authorName = TextEditingController();
  final _authorEmail = TextEditingController();

  Place? _selectedPlace;
  bool _isNewPlace = false;
  int _rating = 0;
  List<PickedPhoto> _photos = [];
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _comment.dispose();
    _newPlaceName.dispose();
    _newPlaceAddress.dispose();
    _authorName.dispose();
    _authorEmail.dispose();
    super.dispose();
  }

  // ---- Validation + envoi ----

  String? _validate() {
    if (_isNewPlace) {
      if (_newPlaceName.text.trim().isEmpty) {
        return 'Indiquez le nom du lieu a proposer.';
      }
    } else if (_selectedPlace == null) {
      return 'Selectionnez le lieu concerne par votre avis.';
    }
    if (_rating == 0) return 'Choisissez une note de 1 a 5 etoiles.';
    if (_comment.text.trim().isEmpty) return 'Ecrivez un commentaire.';
    return null;
  }

  Future<void> _submit() async {
    final error = _validate();
    setState(() => _error = error);
    if (error != null) return;

    setState(() => _sending = true);
    final result = await _service.submitReview(
      ReviewSubmission(
        placeId: _isNewPlace ? null : _selectedPlace!.id,
        placeName:
            _isNewPlace ? _newPlaceName.text.trim() : _selectedPlace!.name,
        isNewPlace: _isNewPlace,
        newPlaceAddress: _newPlaceAddress.text.trim(),
        rating: _rating,
        comment: _comment.text.trim(),
        submitterName: _authorName.text.trim(),
        submitterEmail: _authorEmail.text.trim(),
      ),
      photos: _photos.map((p) => p.file).toList(),
    );
    if (!mounted) return;
    setState(() => _sending = false);

    switch (result) {
      case SubmissionResult.savedOnline:
        _showSuccess(
            'Votre avis a bien ete envoye ! Nous le verifions avant de le '
            'publier.');
      case SubmissionResult.emailFallback:
        _showSuccess(
            'Votre messagerie va s\'ouvrir avec l\'avis preremple. Appuyez '
            'sur "Envoyer" pour nous le transmettre.');
      case SubmissionResult.failed:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Envoi impossible. Reessayez ou ecrivez-nous a ${SubmissionService.ownerEmail}'),
          ),
        );
    }
  }

  void _showSuccess(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.parc),
            SizedBox(width: 8),
            Text('Merci !'),
          ],
        ),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop(); // dialog
              Navigator.of(context).pop(); // ecran
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ---- Selecteur de lieu (bottom sheet avec recherche) ----

  Future<void> _pickPlace() async {
    final places = context.read<PlacesViewModel>().allPlaces;
    final selected = await showModalBottomSheet<Place>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _PlacePickerSheet(places: places),
    );
    if (selected != null) {
      setState(() {
        _selectedPlace = selected;
        _isNewPlace = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Donner mon avis')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ---- En-tete ----
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.rate_review,
                      color: Colors.white, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Votre avis compte !',
                          style: AppTypography.subtitle
                              .copyWith(color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(
                        'Partagez votre experience : elle aide la communaute '
                        'a denicher les meilleures adresses.',
                        style: AppTypography.caption
                            .copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ---- 1. Le lieu ----
          _SectionCard(
            step: '1',
            title: 'Le lieu',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!_isNewPlace)
                  InkWell(
                    onTap: _pickPlace,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _selectedPlace != null
                              ? AppColors.primary
                              : AppColors.textSecondary
                                  .withValues(alpha: 0.4),
                        ),
                        color: _selectedPlace != null
                            ? AppColors.primary.withValues(alpha: 0.06)
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _selectedPlace != null
                                ? PlaceVisuals.icon(_selectedPlace!.type)
                                : Icons.search,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _selectedPlace == null
                                ? Text('Selectionner le lieu...',
                                    style: AppTypography.body.copyWith(
                                        color: AppColors.textSecondary))
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(_selectedPlace!.name,
                                          style: AppTypography.subtitle),
                                      Text(_selectedPlace!.address,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTypography.caption),
                                    ],
                                  ),
                          ),
                          const Icon(Icons.expand_more,
                              color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
                if (_isNewPlace) ...[
                  TextField(
                    controller: _newPlaceName,
                    decoration: const InputDecoration(
                      labelText: 'Nom du lieu *',
                      prefixIcon: Icon(Icons.storefront),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _newPlaceAddress,
                    decoration: const InputDecoration(
                      labelText: 'Adresse (approximative)',
                      prefixIcon: Icon(Icons.place),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                InkWell(
                  onTap: () => setState(() {
                    _isNewPlace = !_isNewPlace;
                    if (_isNewPlace) _selectedPlace = null;
                  }),
                  child: Row(
                    children: [
                      Icon(
                        _isNewPlace
                            ? Icons.arrow_back
                            : Icons.add_location_alt_outlined,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isNewPlace
                            ? 'Revenir aux lieux existants'
                            : 'Le lieu n\'est pas dans la liste ? Proposez-le',
                        style: AppTypography.caption
                            .copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ---- 2. La note ----
          _SectionCard(
            step: '2',
            title: 'Votre note',
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 1; i <= 5; i++)
                      IconButton(
                        iconSize: 40,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 2),
                        onPressed: () => setState(() => _rating = i),
                        icon: AnimatedScale(
                          scale: _rating >= i ? 1.12 : 1,
                          duration: const Duration(milliseconds: 150),
                          child: Icon(
                            _rating >= i
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: _rating >= i
                                ? AppColors.rating
                                : AppColors.textSecondary
                                    .withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                  ],
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    switch (_rating) {
                      1 => 'Decevant',
                      2 => 'Moyen',
                      3 => 'Bien',
                      4 => 'Tres bien',
                      5 => 'Coup de coeur !',
                      _ => 'Touchez une etoile',
                    },
                    key: ValueKey(_rating),
                    style: AppTypography.subtitle.copyWith(
                      color: _rating > 0
                          ? AppColors.rating
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ---- 3. Le commentaire ----
          _SectionCard(
            step: '3',
            title: 'Votre commentaire',
            child: TextField(
              controller: _comment,
              maxLines: 5,
              maxLength: 600,
              decoration: const InputDecoration(
                hintText:
                    'Ambiance, service, plats, petits plus... racontez !',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // ---- 4. Photos (optionnel) ----
          _SectionCard(
            step: '4',
            title: 'Vos photos (optionnel)',
            child: PhotoPickerField(
              photos: _photos,
              onChanged: (p) => setState(() => _photos = p),
            ),
          ),
          const SizedBox(height: 14),

          // ---- 5. Vous (optionnel) ----
          _SectionCard(
            step: '5',
            title: 'Vous (optionnel)',
            child: Column(
              children: [
                TextField(
                  controller: _authorName,
                  decoration: const InputDecoration(
                    labelText: 'Votre prenom / pseudo',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _authorEmail,
                  decoration: const InputDecoration(
                    labelText: 'Votre email',
                    prefixIcon: Icon(Icons.alternate_email),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style:
                    AppTypography.caption.copyWith(color: Colors.redAccent),
              ),
            ),

          PrimaryButton(
            label: _sending ? 'Envoi...' : 'Envoyer mon avis',
            icon: Icons.send,
            onPressed: _sending ? null : _submit,
          ),
          const SizedBox(height: 8),
          Text(
            'Votre avis est verifie par notre equipe avant publication.',
            textAlign: TextAlign.center,
            style: AppTypography.caption,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Carte de section numerotee du formulaire d'avis.
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.step,
    required this.title,
    required this.child,
  });

  final String step;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Text(step,
                    style: AppTypography.tag.copyWith(color: Colors.white)),
              ),
              const SizedBox(width: 10),
              Text(title, style: AppTypography.subtitle),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

/// Bottom sheet : recherche + liste des lieux existants.
class _PlacePickerSheet extends StatefulWidget {
  const _PlacePickerSheet({required this.places});

  final List<Place> places;

  @override
  State<_PlacePickerSheet> createState() => _PlacePickerSheetState();
}

class _PlacePickerSheetState extends State<_PlacePickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.toLowerCase();
    final results = q.isEmpty
        ? widget.places
        : widget.places
            .where((p) =>
                p.name.toLowerCase().contains(q) ||
                p.address.toLowerCase().contains(q))
            .toList();

    return Padding(
      // Garde la barre de recherche au-dessus du clavier.
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.72,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                autofocus: false,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Rechercher un lieu...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  isDense: true,
                ),
              ),
            ),
            Expanded(
              child: results.isEmpty
                  ? Center(
                      child: Text('Aucun lieu trouve.',
                          style: AppTypography.body),
                    )
                  : ListView.builder(
                      itemCount: results.length,
                      itemBuilder: (context, i) {
                        final p = results[i];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: PlaceVisuals.color(p.type)
                                .withValues(alpha: 0.15),
                            child: Icon(PlaceVisuals.icon(p.type),
                                color: PlaceVisuals.color(p.type), size: 20),
                          ),
                          title: Text(p.name, style: AppTypography.subtitle),
                          subtitle: Text(p.address,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          onTap: () => Navigator.of(context).pop(p),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
