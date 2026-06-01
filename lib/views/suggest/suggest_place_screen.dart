import 'package:flutter/material.dart';

import '../../models/place.dart';
import '../../models/place_suggestion.dart';
import '../../services/suggestion_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/place_visuals.dart';
import '../../widgets/primary_button.dart';

/// Formulaire : suggerer un lieu manquant. A l'envoi, ouvre un mail
/// preremple vers l'equipe (qui l'ajoutera ensuite a la carte).
class SuggestPlaceScreen extends StatefulWidget {
  const SuggestPlaceScreen({super.key});

  @override
  State<SuggestPlaceScreen> createState() => _SuggestPlaceScreenState();
}

class _SuggestPlaceScreenState extends State<SuggestPlaceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = SuggestionService();

  final _name = TextEditingController();
  final _address = TextEditingController();
  final _website = TextEditingController();
  final _instagram = TextEditingController();
  final _comment = TextEditingController();
  final _email = TextEditingController();

  PlaceType _type = PlaceType.bar;
  bool _sending = false;

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _website.dispose();
    _instagram.dispose();
    _comment.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);

    final suggestion = PlaceSuggestion(
      name: _name.text.trim(),
      type: _type,
      address: _address.text.trim(),
      website: _website.text.trim(),
      instagram: _instagram.text.trim(),
      comment: _comment.text.trim(),
      submitterEmail: _email.text.trim(),
    );

    final ok = await _service.submit(suggestion);
    if (!mounted) return;
    setState(() => _sending = false);

    if (ok) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.mark_email_read, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Merci !'),
            ],
          ),
          content: const Text(
            'Votre messagerie va s\'ouvrir avec la suggestion preremplie. '
            'Appuyez sur "Envoyer" pour nous la transmettre — nous '
            'ajouterons le lieu a la carte.',
          ),
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Impossible d\'ouvrir la messagerie. Ecrivez-nous a ${SuggestionService.ownerEmail}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Suggerer un lieu')),
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
                      'Un lieu manque sur la carte ? Proposez-le, on l\'ajoute !',
                      style: AppTypography.body.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _label('Type de lieu'),
            const SizedBox(height: 8),
            SegmentedButton<PlaceType>(
              segments: [
                for (final t in PlaceType.values)
                  ButtonSegment(
                    value: t,
                    label: Text(t.label),
                    icon: Icon(PlaceVisuals.icon(t)),
                  ),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 16),

            _field(_name, 'Nom du lieu *', Icons.storefront,
                required: true),
            _field(_address, 'Adresse *', Icons.place, required: true),
            _field(_website, 'Site web (optionnel)', Icons.language),
            _field(_instagram, 'Instagram (optionnel)', Icons.camera_alt),
            _field(_comment, 'Commentaire (optionnel)', Icons.notes,
                maxLines: 3),
            _field(_email, 'Votre email (optionnel)', Icons.alternate_email),
            const SizedBox(height: 12),

            PrimaryButton(
              label: _sending ? 'Envoi...' : 'Envoyer la suggestion',
              icon: Icons.send,
              onPressed: _sending ? null : _submit,
            ),
            const SizedBox(height: 8),
            Text(
              'Votre suggestion nous est envoyee par email. Nous l\'ajoutons '
              'ensuite manuellement sur la carte.',
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
