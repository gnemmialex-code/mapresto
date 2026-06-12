import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Photo selectionnee : fichier + octets (pour l'apercu et l'upload web).
class PickedPhoto {
  final XFile file;
  final Uint8List bytes;
  const PickedPhoto(this.file, this.bytes);
}

/// Grille de selection de photos (galerie), avec apercu et suppression.
class PhotoPickerField extends StatelessWidget {
  const PhotoPickerField({
    super.key,
    required this.photos,
    required this.onChanged,
    this.minRequired = 0,
    this.maxPhotos = 6,
  });

  final List<PickedPhoto> photos;
  final ValueChanged<List<PickedPhoto>> onChanged;
  final int minRequired;
  final int maxPhotos;

  Future<void> _pick(BuildContext context) async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage(
      imageQuality: 80,
      maxWidth: 1600,
    );
    if (files.isEmpty) return;
    final updated = [...photos];
    for (final f in files) {
      if (updated.length >= maxPhotos) break;
      updated.add(PickedPhoto(f, await f.readAsBytes()));
    }
    onChanged(updated);
  }

  void _remove(int index) {
    final updated = [...photos]..removeAt(index);
    onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final missing = minRequired - photos.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (var i = 0; i < photos.length; i++)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      photos[i].bytes,
                      width: 84,
                      height: 84,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: GestureDetector(
                      onTap: () => _remove(i),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            if (photos.length < maxPhotos)
              InkWell(
                onTap: () => _pick(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.5)),
                    color: AppColors.primary.withValues(alpha: 0.06),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo,
                          color: AppColors.primary, size: 24),
                      SizedBox(height: 4),
                      Text('Ajouter',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.primary)),
                    ],
                  ),
                ),
              ),
          ],
        ),
        if (minRequired > 0) ...[
          const SizedBox(height: 6),
          Text(
            missing > 0
                ? '$missing photo(s) encore requise(s) (minimum $minRequired)'
                : 'Minimum atteint ($minRequired photos)',
            style: AppTypography.caption.copyWith(
              color: missing > 0 ? Colors.redAccent : AppColors.parc,
            ),
          ),
        ],
      ],
    );
  }
}
