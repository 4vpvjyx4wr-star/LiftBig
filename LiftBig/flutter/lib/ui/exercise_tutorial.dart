import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../theme.dart';

/// YouTube tutorial: thumbnail first, then the in-app player. An external
/// link is only the fallback when the thumbnail or embed fails.
class ExerciseTutorial extends StatefulWidget {
  const ExerciseTutorial({super.key, required this.url, required this.videoId});

  final String url;
  final String videoId;

  @override
  State<ExerciseTutorial> createState() => _ExerciseTutorialState();
}

class _ExerciseTutorialState extends State<ExerciseTutorial> {
  YoutubePlayerController? _controller;
  StreamSubscription<YoutubePlayerValue>? _subscription;
  var _thumbnailFailed = false;
  var _thumbnailFailureQueued = false;
  var _playerFailed = false;
  var _closed = false;

  void _play() {
    if (_controller != null || _playerFailed || _thumbnailFailed) return;
    try {
      final controller = YoutubePlayerController(
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
          strictRelatedVideos: true,
          enableCaption: false,
          playsInline: true,
        ),
        onWebResourceError: (error) {
          if (error.isForMainFrame != true) return;
          _markPlayerFailed();
        },
      );
      _controller = controller;
      _subscription = controller.stream.listen((value) {
        if (value.hasError) _markPlayerFailed();
      });
      setState(() {});
      unawaited(
        controller
            .loadVideoById(videoId: widget.videoId)
            .then<void>(
              (_) {},
              onError: (Object _, StackTrace _) => _markPlayerFailed(),
            ),
      );
    } catch (_) {
      _markPlayerFailed();
    }
  }

  void _scheduleThumbnailFailure() {
    if (_thumbnailFailed || _thumbnailFailureQueued) return;
    _thumbnailFailureQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _thumbnailFailed || _controller != null) return;
      setState(() => _thumbnailFailed = true);
    });
  }

  void _markPlayerFailed() {
    if (_playerFailed) return;
    _playerFailed = true;
    unawaited(_closePlayer());
    if (mounted) setState(() {});
  }

  Future<void> _closePlayer() async {
    if (_closed) return;
    _closed = true;
    await _subscription?.cancel();
    _subscription = null;
    final controller = _controller;
    _controller = null;
    await controller?.close();
  }

  @override
  void dispose() {
    unawaited(_closePlayer());
    super.dispose();
  }

  Future<void> _openExternally() async {
    final uri = Uri.tryParse(widget.url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    if (_thumbnailFailed || _playerFailed) {
      return _externalFallback();
    }
    final controller = _controller;
    if (controller != null) {
      return _framed(context,
        YoutubePlayer(
          controller: controller,
          aspectRatio: 16 / 9,
          autoFullScreen: false,
          enableFullScreenOnVerticalDrag: false,
          backgroundColor: context.liftBig.card,
        ),
      );
    }
    return _thumbnail();
  }

  Widget _thumbnail() {
    return _framed(
      context,
      Material(
        color: context.liftBig.card,
        child: InkWell(
          onTap: _play,
          child: Semantics(
            button: true,
            label: 'Play tutorial',
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    'https://img.youtube.com/vi/${widget.videoId}/hqdefault.jpg',
                    fit: BoxFit.cover,
                    excludeFromSemantics: true,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return  ColoredBox(
                        color: context.liftBig.card,
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      _scheduleThumbnailFailure();
                      return  ColoredBox(color: context.liftBig.card);
                    },
                  ),
                  const ColoredBox(color: Color(0x33000000)),
                  const Center(child: _TutorialPlayButton()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _externalFallback() {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: _openExternally,
        style: TextButton.styleFrom(
          foregroundColor: context.liftBig.foreground,
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        icon: const Icon(Icons.open_in_new, size: 16),
        label: const Text('Watch the tutorial'),
      ),
    );
  }
}

Widget _framed(BuildContext context, Widget child) {
  return Container(
    foregroundDecoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: context.liftBig.border),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ColoredBox(color: context.liftBig.card, child: child),
    ),
  );
}

class _TutorialPlayButton extends StatelessWidget {
  const _TutorialPlayButton();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.liftBig.primary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 12,
          ),
        ],
      ),
      child: const ExcludeSemantics(
        child: Padding(
          padding: EdgeInsets.all(10),
          child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
        ),
      ),
    );
  }
}
