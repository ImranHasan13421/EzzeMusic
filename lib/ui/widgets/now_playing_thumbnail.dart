import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../theme/app_colors.dart';

class NowPlayingThumbnail extends StatelessWidget {
  final int songId;

  const NowPlayingThumbnail({super.key, required this.songId});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final size = MediaQuery.of(context).size;
    final double artSize = size.width * 0.75;

    return Center(
      child: Container(
        width: artSize,
        height: artSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
            BoxShadow(
              color: accent.withValues(alpha: 0.15),
              blurRadius: 50,
              spreadRadius: -2,
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipOval(
              child: QueryArtworkWidget(
                id: songId,
                type: ArtworkType.AUDIO,
                artworkHeight: artSize,
                artworkWidth: artSize,
                artworkFit: BoxFit.cover,
                quality: 100,
                nullArtworkWidget: _buildPlaceholder(accent, artSize),
              ),
            ),
            IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: 2.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(Color accent, double size) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppColors.bgGlass, accent.withValues(alpha: 0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.music_note_rounded,
          size: size * 0.35,
          color: accent.withValues(alpha: 0.25),
        ),
      ),
    );
  }
}