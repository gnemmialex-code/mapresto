import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../theme/app_colors.dart';

/// Lecteur video simple ouvert en plein ecran (modal).
/// Supporte les URLs reseau (mock) ; pour des assets locaux, utiliser
/// `VideoPlayerController.asset(...)`.
class PlaceVideoPlayer extends StatefulWidget {
  const PlaceVideoPlayer({super.key, required this.url});

  final String url;

  /// Ouvre le lecteur en plein ecran.
  static Future<void> open(BuildContext context, String url) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => PlaceVideoPlayer(url: url),
      ),
    );
  }

  @override
  State<PlaceVideoPlayer> createState() => _PlaceVideoPlayerState();
}

class _PlaceVideoPlayerState extends State<PlaceVideoPlayer> {
  late final VideoPlayerController _controller;
  bool _ready = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _ready = true);
        _controller
          ..setLooping(true)
          ..play();
      }).catchError((_) {
        if (mounted) setState(() => _error = true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: _error
            ? const Text('Video indisponible',
                style: TextStyle(color: Colors.white70))
            : !_ready
                ? const CircularProgressIndicator(color: AppColors.primary)
                : AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  ),
      ),
      floatingActionButton: _ready && !_error
          ? FloatingActionButton(
              backgroundColor: AppColors.primary,
              onPressed: () => setState(() {
                _controller.value.isPlaying
                    ? _controller.pause()
                    : _controller.play();
              }),
              child: Icon(
                _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              ),
            )
          : null,
    );
  }
}
