import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../models/contribution.dart';

/// Canal par lequel la contribution a ete transmise.
enum SubmissionResult {
  savedOnline,   // enregistree dans Supabase (tables *_submissions)
  emailFallback, // Supabase indisponible : client mail ouvert en repli
  failed,        // rien n'a pu etre envoye
}

/// Envoie les contributions ("Ajouter une adresse" / "Donner mon avis").
///
/// Destination principale : Supabase.
///   - Photos    -> bucket Storage public `contributions`
///   - Adresses  -> table `address_submissions`
///   - Avis      -> table `review_submissions`
/// Chaque ligne arrive avec status = 'pending' : tout se retrouve dans le
/// dashboard Supabase (Table Editor) pour verification avant mise en ligne.
/// Setup SQL : voir supabase/contributions_setup.sql
///
/// Repli si Supabase echoue : ouverture du client mail avec le recapitulatif.
class SubmissionService {
  static const String ownerEmail = 'gnemmialex@gmail.com';
  static const String bucket = 'contributions';

  SupabaseClient get _client => Supabase.instance.client;

  /// Upload les photos dans le bucket et renvoie leurs URLs publiques.
  Future<List<String>> uploadPhotos(String folder, List<XFile> photos) async {
    final urls = <String>[];
    final storage = _client.storage.from(bucket);
    final stamp = DateTime.now().millisecondsSinceEpoch;
    for (var i = 0; i < photos.length; i++) {
      final bytes = await photos[i].readAsBytes();
      final path = '$folder/${stamp}_$i.jpg';
      await storage.uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(contentType: 'image/jpeg'),
      );
      urls.add(storage.getPublicUrl(path));
    }
    return urls;
  }

  Future<SubmissionResult> submitAddress(
    AddressSubmission submission, {
    List<XFile> photos = const [],
  }) async {
    if (Config.isSupabaseConfigured) {
      try {
        final urls = await uploadPhotos('addresses', photos);
        final row = AddressSubmission(
          name: submission.name,
          address: submission.address,
          description: submission.description,
          type: submission.type,
          website: submission.website,
          instagram: submission.instagram,
          submitterEmail: submission.submitterEmail,
          photoUrls: urls,
        );
        await _client.from('address_submissions').insert(row.toRow());
        return SubmissionResult.savedOnline;
      } catch (_) {
        // On bascule sur le repli email ci-dessous.
      }
    }
    final sent = await _mailto(
        'Adresse a ajouter : ${submission.name}', submission.toEmailBody());
    return sent ? SubmissionResult.emailFallback : SubmissionResult.failed;
  }

  Future<SubmissionResult> submitReview(
    ReviewSubmission submission, {
    List<XFile> photos = const [],
  }) async {
    if (Config.isSupabaseConfigured) {
      try {
        final urls = await uploadPhotos('reviews', photos);
        final row = ReviewSubmission(
          placeId: submission.placeId,
          placeName: submission.placeName,
          isNewPlace: submission.isNewPlace,
          newPlaceAddress: submission.newPlaceAddress,
          rating: submission.rating,
          comment: submission.comment,
          submitterName: submission.submitterName,
          submitterEmail: submission.submitterEmail,
          photoUrls: urls,
        );
        await _client.from('review_submissions').insert(row.toRow());
        return SubmissionResult.savedOnline;
      } catch (_) {
        // On bascule sur le repli email ci-dessous.
      }
    }
    final sent = await _mailto(
        'Avis sur : ${submission.placeName}', submission.toEmailBody());
    return sent ? SubmissionResult.emailFallback : SubmissionResult.failed;
  }

  Future<bool> _mailto(String subject, String body) async {
    final uri = Uri.parse(
      'mailto:$ownerEmail'
      '?subject=${Uri.encodeComponent(subject)}'
      '&body=${Uri.encodeComponent(body)}',
    );
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
