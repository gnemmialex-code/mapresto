import 'package:flutter/material.dart';

import '../../models/contribution.dart';
import '../../models/place.dart';
import '../../services/submission_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/place_visuals.dart';
import '../../widgets/photo_picker_field.dart';
import '../../widgets/primary_button.dart';

/// Formulaire "Ajouter une adresse" : nom, adresse approximative,
/// 2 photos minimum, courte description (+ champs optionnels).
/// Envoye dans Supabase (table `address_submissions`) pour verification.
class AddAddressScreen extends StatefulWidget {
  const AddAddressScreen({super.key});

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  static const int _minPhotos = 2;

  final _formKey = GlobalKey<FormState>();
  final _service = SubmissionService();

  final _name = TextEditingController();
  final _address = TextEditingController();
  final _description = TextEditingController();
  final _website = TextEditingController();
  final _instagram = TextEditingController();
  final _email = TextEditingController();

  PlaceType _type = PlaceType.restaurant;
  List<PickedPhoto> _photos = [];
  bool _photosError = false;
  bool _showMore = false;
  bool _sending = false;

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _description.dispose();
    _website.dispose();
    _instagram.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final formOk = _formKey.currentState!.validate();
    final photosOk = _photos.length >= _minPhotos;
    setState(() => _photosError = !photosOk);
    if (!formOk || !photosOk) return;

    setState(() => _sending = true);
    final result = await _service.submitAddress(
      AddressSubmission(
        name: _name.text.trim(),
        address: _address.text.trim(),
        description: _description.text.trim(),
        type: _type,
        website: _website.text.trim(),
        instagram: _instagram.text.trim(),
        submitterEmail: _email.text.trim(),
      ),
      photos: _photos.map((p) => p.file).toList(),
    );
    if (!mounted) return;
    setState(() => _sending = false);

    switch (result) {
      case SubmissionResult.savedOnline:
        _showSuccess(
          'Votre adresse a bien ete envoyee ! Nous la verifions puis '
          'l\'ajoutons sur la carte.',
        );
      case SubmissionResult.emailFallback:
        _showSuccess(
          'Votre messagerie va s\'ouvrir avec la proposition preremplie. '
          'Appuyez sur "Envoyer" pour nous la transmettre.',
        );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter une adresse')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const Icon(Icons.add_location_alt,
                      color: Colors.white, size: 30),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Une bonne adresse a partager ? Proposez-la, nous la '
                      'verifions puis l\'ajoutons sur la carte !',
                      style: AppTypography.body.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _label('Type de lieu'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final t in PlaceType.values)
                  ChoiceChip(
                    avatar: Icon(PlaceVisuals.icon(t), size: 16),
                    label: Text(t.label),
                    selected: _type == t,
                    onSelected: (_) => setState(() => _type = t),
                    showCheckmark: false,
                  ),
              ],
            ),
            const SizedBox(height: 16),

            _field(_name, 'Nom de l\'etablissement *', Icons.storefront,
                required: true),
            _field(_address, 'Adresse (approximative) *', Icons.place,
                required: true),
            _field(_description, 'Courte description *', Icons.notes,
                required: true, maxLines: 3),

            _label('Photos * (minimum $_minPhotos)'),
            const SizedBox(height: 8),
            PhotoPickerField(
              photos: _photos,
              minRequired: _minPhotos,
              onChanged: (p) => setState(() {
                _photos = p;
                if (p.length >= _minPhotos) _photosError = false;
              }),
            ),
            if (_photosError)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Ajoutez au moins $_minPhotos photos du lieu.',
                  style: AppTypography.caption
                      .copyWith(color: Colors.redAccent),
                ),
              ),
            const SizedBox(height: 16),

            // ---- Champs optionnels (repliables) ----
            InkWell(
              onTap: () => setState(() => _showMore = !_showMore),
              child: Row(
                children: [
                  Icon(_showMore ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text('En dire plus (optionnel)',
                      style: AppTypography.subtitle
                          .copyWith(color: AppColors.primary)),
                ],
              ),
            ),
            if (_showMore) ...[
              const SizedBox(height: 12),
              _field(_website, 'Site web', Icons.language),
              _field(_instagram, 'Instagram', Icons.camera_alt),
              _field(_email, 'Votre email (pour vous tenir au courant)',
                  Icons.alternate_email),
            ],
            const SizedBox(height: 16),

            PrimaryButton(
              label: _sending ? 'Envoi...' : 'Envoyer l\'adresse',
              icon: Icons.send,
              onPressed: _sending ? null : _submit,
            ),
            const SizedBox(height: 8),
            Text(
              'Votre proposition est verifiee par notre equipe avant '
              'd\'apparaitre sur la carte.',
              textAlign: TextAlign.center,
              style: AppTypography.caption,
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text, style: AppTypography.subtitle);

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool required = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null
            : null,
      ),
    );
  }
}
