import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/song.dart';
import '../../state/app_state.dart';
import '../theme/app_colors.dart';

class MiniSongTile extends StatefulWidget {
  final Song song;
  final VoidCallback? onTap;
  final Widget? trailing;

  const MiniSongTile({
    super.key,
    required this.song,
    this.onTap,
    this.trailing,
  });

  @override
  State<MiniSongTile> createState() => _MiniSongTileState();
}

class _MiniSongTileState extends State<MiniSongTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final app = context.watch<AppState>();
    final isPlaying = app.player.currentSong?.id == widget.song.id;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.diagonal3Values(
          _pressed ? 0.98 : 1.0,
          _pressed ? 0.98 : 1.0,
          1.0,
        ),
        transformAlignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        decoration: BoxDecoration(
          color: isPlaying
              ? accent.withValues(alpha: 0.08)
              : (_pressed ? AppColors.bgGlass.withValues(alpha: 0.6) : Colors.transparent),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Icon Circle
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isPlaying
                    ? accent.withValues(alpha: 0.15)
                    : AppColors.bgGlass,
                border: Border.all(
                  color: isPlaying
                      ? accent.withValues(alpha: 0.4)
                      : AppColors.divider,
                ),
                boxShadow: isPlaying
                    ? [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.2),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ]
                    : [],
              ),
              child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.music_note_rounded,
                color: isPlaying ? accent : AppColors.textMuted,
                size: 20,
              ),
            ),

            const SizedBox(width: 14),

            // Title + Artist
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.song.title.isEmpty ? 'Unknown Title' : widget.song.title,
                    style: TextStyle(
                      color: isPlaying ? accent : AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: isPlaying ? FontWeight.w700 : FontWeight.w600,
                      letterSpacing: 0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.song.artist.isEmpty ? 'Unknown Artist' : widget.song.artist,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Trailing widget
            if (widget.trailing != null) ...[
              const SizedBox(width: 4),
              IconTheme(
                data: IconThemeData(
                  color: isPlaying ? accent : AppColors.textMuted,
                  size: 20,
                ),
                child: widget.trailing!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}