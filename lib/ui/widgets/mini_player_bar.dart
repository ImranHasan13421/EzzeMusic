import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../theme/app_colors.dart';
import 'shared/smart_marquee.dart';

class MiniPlayerBar extends StatelessWidget {
  final VoidCallback? onTap;

  const MiniPlayerBar({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final colors = context.colors;
    final app = context.watch<AppState>();

    return StreamBuilder(
      stream: app.player.currentSongStream,
      initialData: app.player.currentSong,
      builder: (context, snapSong) {
        final song = snapSong.data;
        if (song == null) return const SizedBox.shrink();

        final int parsedSongId = int.tryParse(song.id.toString()) ?? 0;

        return Container(
          decoration: BoxDecoration(
            color: colors.bgGlass,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.divider, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: colors.isDark ? 0.45 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: GestureDetector(
              onTap: onTap,
              onHorizontalDragEnd: (details) {
                final velocity = details.primaryVelocity ?? 0;
                if (velocity < -200) {
                  // Swipe left -> skip next
                  app.player.next();
                } else if (velocity > 200) {
                  // Swipe right -> skip previous
                  app.player.previous();
                }
              },
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        // Album icon
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accent.withValues(alpha: 0.12),
                            border: Border.all(color: accent.withValues(alpha: 0.25)),
                          ),
                          child: ClipOval(
                            child: QueryArtworkWidget(
                              id: parsedSongId,
                              type: ArtworkType.AUDIO,
                              artworkHeight: 44,
                              artworkWidth: 44,
                              artworkFit: BoxFit.cover,
                              keepOldArtwork: true,
                              nullArtworkWidget: Center(
                                child: Icon(
                                  Icons.music_note_rounded,
                                  color: accent,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Song info
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: 18,
                                child: SmartMarquee(
                                  text: song.title.isEmpty ? 'Unknown Title' : song.title,
                                  style: TextStyle(
                                    color: colors.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  velocity: 30.0,
                                  blankSpace: 20.0,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                song.artist.isEmpty ? 'Unknown Artist' : song.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Controls
                        _ControlButton(
                          icon: Icons.skip_previous_rounded,
                          isAccent: false,
                          accentColor: accent,
                          onTap: () => app.player.previous(),
                        ),

                        const SizedBox(width: 6),

                        StreamBuilder<PlayerState>(
                          stream: app.player.playerStateStream,
                          builder: (context, snapState) {
                            final playing = snapState.data?.playing ?? app.player.playing;
                            return _ControlButton(
                              icon: playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              isAccent: true,
                              accentColor: accent,
                              onTap: () => app.player.toggle(),
                            );
                          },
                        ),

                        const SizedBox(width: 6),

                        _ControlButton(
                          icon: Icons.skip_next_rounded,
                          isAccent: false,
                          accentColor: accent,
                          onTap: () => app.player.next(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Progress bar
                    _MiniProgressBar(app: app, accentColor: accent),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Control Button ────────────────────────────────────────────────────────────

class _ControlButton extends StatefulWidget {
  final IconData icon;
  final bool isAccent;
  final Color accentColor;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.isAccent,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_ControlButton> createState() => _ControlButtonState();
}

class _ControlButtonState extends State<_ControlButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 110),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.isAccent
              ? (_pressed
                  ? accent.withValues(alpha: 0.35)
                  : accent.withValues(alpha: 0.18))
              : (_pressed ? AppColors.divider : Colors.transparent),
          border: widget.isAccent
              ? Border.all(color: accent.withValues(alpha: 0.35))
              : null,
        ),
        child: Icon(
          widget.icon,
          color: widget.isAccent ? accent : AppColors.textMuted,
          size: widget.isAccent ? 20 : 18,
        ),
      ),
    );
  }
}

// ── Mini Progress Bar ─────────────────────────────────────────────────────────

class _MiniProgressBar extends StatelessWidget {
  final AppState app;
  final Color accentColor;

  const _MiniProgressBar({required this.app, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration?>(
      stream: app.player.durationStream,
      builder: (context, snapDur) {
        final duration = snapDur.data ?? Duration.zero;
        final total = duration.inMilliseconds == 0 ? 1 : duration.inMilliseconds;

        return StreamBuilder<Duration>(
          stream: app.player.positionStream,
          initialData: Duration.zero,
          builder: (context, snapPos) {
            final pos = snapPos.data ?? Duration.zero;
            final ratio = (pos.inMilliseconds / total).clamp(0.0, 1.0);

            return ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: SizedBox(
                height: 2.5,
                child: LinearProgressIndicator(
                  value: ratio,
                  backgroundColor: context.colors.divider,
                  valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                ),
              ),
            );
          },
        );
      },
    );
  }
}