import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../models/place.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/place_visuals.dart';
import '../../viewmodels/collections_view_model.dart';
import '../../viewmodels/places_view_model.dart';
import '../map/map_shared.dart';

/// Feed vidéo vertical facon TikTok : swipe-up pour decouvrir les lieux.
/// [isActive] indique si l'onglet est affiche (sinon on met en pause).
class VideoFeedScreen extends StatefulWidget {
  const VideoFeedScreen({super.key, this.isActive = true});

  final bool isActive;

  @override
  State<VideoFeedScreen> createState() => _VideoFeedScreenState();
}

class _VideoFeedScreenState extends State<VideoFeedScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Place> _feed(PlacesViewModel vm) =>
      vm.allPlaces.where((p) => _videoOf(p) != null).toList();

  static String? _videoOf(Place p) {
    if (p.instagramVideos.isNotEmpty) return p.instagramVideos.first;
    if (p.originalVideos.isNotEmpty) return p.originalVideos.first;
    if (p.videos.isNotEmpty) return p.videos.first;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final places = _feed(context.watch<PlacesViewModel>());

    return Scaffold(
      backgroundColor: Colors.black,
      body: places.isEmpty
          ? const Center(
              child: Text('Aucune video disponible',
                  style: TextStyle(color: Colors.white70)),
            )
          : PageView.builder(
              controller: _controller,
              scrollDirection: Axis.vertical,
              itemCount: places.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) {
                return _VideoPage(
                  place: places[i],
                  videoUrl: _videoOf(places[i])!,
                  play: widget.isActive && i == _index,
                  showSwipeHint: i == 0,
                );
              },
            ),
    );
  }
}

class _VideoPage extends StatefulWidget {
  const _VideoPage({
    required this.place,
    required this.videoUrl,
    required this.play,
    this.showSwipeHint = false,
  });

  final Place place;
  final String videoUrl;
  final bool play;
  final bool showSwipeHint;

  @override
  State<_VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<_VideoPage> {
  late final VideoPlayerController _controller;
  bool _ready = false;
  bool _error = false;
  bool _manualPause = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..setLooping(true)
      // Muet : indispensable pour l'autoplay sur le Web.
      ..setVolume(0)
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _ready = true);
        _syncPlayback();
      }).catchError((_) {
        if (mounted) setState(() => _error = true);
      });
  }

  @override
  void didUpdateWidget(covariant _VideoPage old) {
    super.didUpdateWidget(old);
    if (old.play != widget.play) _syncPlayback();
  }

  void _syncPlayback() {
    if (!_ready) return;
    if (widget.play && !_manualPause) {
      _controller.play();
    } else {
      _controller.pause();
    }
  }

  void _togglePlay() {
    setState(() => _manualPause = !_manualPause);
    _syncPlayback();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final place = widget.place;
    final color = PlaceVisuals.color(place.type);

    return GestureDetector(
      onTap: _togglePlay,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ---- Video (couvre l'ecran) ----
          if (_error)
            Container(
              color: color.withValues(alpha: 0.4),
              alignment: Alignment.center,
              child: const Icon(Icons.videocam_off,
                  color: Colors.white54, size: 48),
            )
          else if (!_ready)
            const Center(
                child: CircularProgressIndicator(color: Colors.white))
          else
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            ),

          // ---- Voile degrade pour lisibilite ----
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.center,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black87],
              ),
            ),
          ),

          // Icone play si en pause manuelle.
          if (_manualPause && _ready)
            const Center(
              child: Icon(Icons.play_arrow, color: Colors.white70, size: 72),
            ),

          // ---- Infos lieu (bas-gauche) ----
          Positioned(
            left: 16,
            right: 80,
            bottom: 28,
            child: _PlaceOverlay(place: place, color: color),
          ),

          // ---- Actions (droite) ----
          Positioned(
            right: 10,
            bottom: 40,
            child: _ActionsColumn(place: place),
          ),

          // Indice de swipe sur la 1re video.
          if (widget.showSwipeHint)
            const Positioned(
              left: 0,
              right: 0,
              bottom: 6,
              child: Column(
                children: [
                  Icon(Icons.keyboard_arrow_up, color: Colors.white70),
                  Text('Swipe',
                      style: TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PlaceOverlay extends StatelessWidget {
  const _PlaceOverlay({required this.place, required this.color});
  final Place place;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(PlaceVisuals.icon(place.type), size: 13, color: Colors.white),
              const SizedBox(width: 4),
              Text(place.type.label,
                  style: AppTypography.tag.copyWith(color: Colors.white)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          place.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.title.copyWith(color: Colors.white, fontSize: 22),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.star, color: AppColors.rating, size: 15),
            const SizedBox(width: 3),
            Text('${place.rating}',
                style: AppTypography.caption.copyWith(color: Colors.white)),
            const SizedBox(width: 8),
            Text('${place.averagePrice}€ · ${place.priceLabel}',
                style: AppTypography.caption.copyWith(color: Colors.white70)),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.place, color: Colors.white70, size: 14),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                place.address,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(color: Colors.white70),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionsColumn extends StatelessWidget {
  const _ActionsColumn({required this.place});
  final Place place;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CollectionsViewModel>();
    final saved = vm.isInMyMap(place);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionButton(
          icon: saved ? Icons.bookmark : Icons.bookmark_border,
          label: saved ? 'Sauve' : 'Sauver',
          highlight: saved,
          onTap: () {
            if (saved) {
              vm.removeFromMyMap(place);
            } else {
              final ok = vm.addToMyMap(place);
              if (!ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Limite atteinte. Parrainez ou passez Createur.'),
                  ),
                );
              }
            }
          },
        ),
        const SizedBox(height: 18),
        _ActionButton(
          icon: Icons.info_outline,
          label: 'En savoir',
          onTap: () => showPlaceQuickSheet(context, place),
        ),
        const SizedBox(height: 18),
        _ActionButton(
          icon: Icons.directions,
          label: 'Y aller',
          onTap: () => launchExternal(place.directionsUrl()),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
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
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: highlight
                  ? AppColors.primary
                  : Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 5),
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 11)),
        ],
      ),
    );
  }
}
