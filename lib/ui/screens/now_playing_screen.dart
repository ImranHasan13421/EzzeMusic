import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

import '../../models/song.dart';
import '../../state/app_state.dart';
import '../../state/player_controller.dart';
import '../theme/app_colors.dart';
import '../widgets/music_visualizer_view.dart';
import '../widgets/shared/app_dialogs.dart';
import '../widgets/shared/smart_marquee.dart';

enum ArtworkDisplayMode { card, vinyl, visualizer }

class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _rotationController;
  StreamSubscription<PlayerState>? _playerStateSub;
  Timer? _sleepTimerTicker;

  // Cycles through Modern Card -> Vinyl -> Visualizer
  ArtworkDisplayMode _artworkMode = ArtworkDisplayMode.card;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.90, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    );

    // Sleep timer ticker for remaining badge
    _sleepTimerTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final app = context.read<AppState>();
      _playerStateSub = app.player.playerStateStream.listen((state) {
        if (state.playing) {
          _rotationController.repeat();
        } else {
          _rotationController.stop();
        }
      });
    });
  }

  @override
  void dispose() {
    _sleepTimerTicker?.cancel();
    _playerStateSub?.cancel();
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  void _cycleArtworkMode() {
    HapticFeedback.selectionClick();
    setState(() {
      _artworkMode = switch (_artworkMode) {
        ArtworkDisplayMode.card => ArtworkDisplayMode.vinyl,
        ArtworkDisplayMode.vinyl => ArtworkDisplayMode.visualizer,
        ArtworkDisplayMode.visualizer => ArtworkDisplayMode.card,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final app = context.watch<AppState>();
    final size = MediaQuery.of(context).size;

    return StreamBuilder<Song?>(
      stream: app.player.currentSongStream.distinct((prev, next) => prev?.id == next?.id),
      initialData: app.player.currentSong,
      builder: (context, snapSong) {
        final Song? song = snapSong.data;
        if (song == null) {
          return Scaffold(
            backgroundColor: AppColors.bgDeep,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textPrimary, size: 32),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
            body: Center(
              child: Text(
                'No song playing',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
              ),
            ),
          );
        }

        final artSize = (size.width * 0.76).clamp(220.0, 340.0);
        final int parsedSongId = int.tryParse(song.id.toString()) ?? 0;

        return Scaffold(
          backgroundColor: AppColors.bgDeep,
          extendBodyBehindAppBar: true,
          appBar: _buildTopAppBar(context, app, song, accent),
          body: Stack(
            fit: StackFit.expand,
            children: [
              // Dynamic Blurred Background
              _buildBlurredBackground(parsedSongId),

              SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: size.width * 0.07),
                  child: Column(
                    children: [
                      const Spacer(flex: 1),

                      // Artwork (Tap to cycle: Card -> Vinyl -> Visualizer)
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _cycleArtworkMode,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 320),
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: ScaleTransition(
                                scale: Tween<double>(begin: 0.94, end: 1.0).animate(
                                  CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOutCubic,
                                  ),
                                ),
                                child: child,
                              ),
                            );
                          },
                          child: switch (_artworkMode) {
                            ArtworkDisplayMode.card => KeyedSubtree(
                                key: const ValueKey('artwork_card'),
                                child: _buildModernArtworkCard(
                                    artSize, parsedSongId, accent),
                              ),
                            ArtworkDisplayMode.vinyl => KeyedSubtree(
                                key: const ValueKey('artwork_vinyl'),
                                child: _buildRotatingVinyl(
                                    artSize, parsedSongId, accent),
                              ),
                            ArtworkDisplayMode.visualizer => KeyedSubtree(
                                key: const ValueKey('artwork_visualizer'),
                                child: MusicVisualizerView(
                                  size: artSize,
                                  song: song,
                                  songId: parsedSongId,
                                  accent: accent,
                                  isPlaying: app.player.playing,
                                  isPlayingStream: app.player.playerStateStream
                                      .map((s) => s.playing)
                                      .distinct(),
                                  positionStream: app.player.positionStream,
                                ),
                              ),
                          },
                        ),
                      ),

                      // Interactive mode switcher pill
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _cycleArtworkMode,
                        child: Container(
                          margin: const EdgeInsets.only(top: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.bgSurface.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.borderSubtle,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                switch (_artworkMode) {
                                  ArtworkDisplayMode.card => Icons.album_rounded,
                                  ArtworkDisplayMode.vinyl => Icons.equalizer_rounded,
                                  ArtworkDisplayMode.visualizer => Icons.image_rounded,
                                },
                                size: 12,
                                color: accent,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                switch (_artworkMode) {
                                  ArtworkDisplayMode.card => 'Tap for Vinyl View',
                                  ArtworkDisplayMode.vinyl => 'Tap for Visualizer View',
                                  ArtworkDisplayMode.visualizer => 'Tap for Card View',
                                },
                                style: TextStyle(
                                  color: AppColors.textMuted.withValues(alpha: 0.9),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(flex: 2),

                      // Song Title, Artist, and Favorite
                      _buildSongInfoRow(app, song, accent),

                      const SizedBox(height: 24),

                      // Scrubber Progress Bar
                      _ProgressSection(app: app, song: song),

                      const SizedBox(height: 24),

                      // Transport Playback Controls
                      _buildControls(app, song, accent),

                      const Spacer(flex: 1),

                      // Bottom Action Bar: Speed, Sleep Timer & Up Next Queue
                      _buildBottomActionBar(context, app, accent),

                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Top Navigation Bar ───────────────────────────────────────────────

  PreferredSizeWidget _buildTopAppBar(
    BuildContext context,
    AppState app,
    Song song,
    Color accent,
  ) {
    final sleepActive = app.sleepEndsAt != null;
    final sleepRem = app.sleepRemaining;

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.keyboard_arrow_down_rounded,
            color: Colors.white, size: 34),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: Column(
        children: [
          Text(
            'NOW PLAYING',
            style: TextStyle(
              color: accent.withValues(alpha: 0.8),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
            ),
          ),
          if (song.album.isNotEmpty)
            Text(
              song.album,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      actions: [
        // Sleep Timer Button with active badge
        IconButton(
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                sleepActive ? Icons.bedtime_rounded : Icons.bedtime_outlined,
                color: sleepActive ? accent : AppColors.textMuted,
                size: 22,
              ),
              if (sleepActive)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          tooltip: sleepActive
              ? 'Sleep timer in ${_formatRemaining(sleepRem)}'
              : 'Set sleep timer',
          onPressed: () => _openSleepTimerSheet(context, app, accent),
        ),

        // Song Info / Metadata Details
        IconButton(
          icon: Icon(Icons.info_outline_rounded,
              color: AppColors.textMuted, size: 22),
          tooltip: 'Track Info',
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => SongDetailsDialog(song: song, accentColor: accent),
            );
          },
        ),
      ],
    );
  }

  // ── Artwork Renderers ────────────────────────────────────────────────

  Widget _buildModernArtworkCard(double size, int songId, Color accent) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.22 * _pulseAnimation.value),
                blurRadius: 40 * _pulseAnimation.value,
                spreadRadius: 6 * _pulseAnimation.value,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 28,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: child,
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            QueryArtworkWidget(
              key: ValueKey('card_art_$songId'),
              id: songId,
              type: ArtworkType.AUDIO,
              artworkHeight: size,
              artworkWidth: size,
              artworkFit: BoxFit.cover,
              quality: 100,
              keepOldArtwork: true,
              nullArtworkWidget: _buildPlaceholderCard(accent, size),
            ),
            // Border highlight
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRotatingVinyl(double size, int songId, Color accent) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.18 * _pulseAnimation.value),
                blurRadius: 50 * _pulseAnimation.value,
                spreadRadius: 8 * _pulseAnimation.value,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.65),
                blurRadius: 30,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: child,
        );
      },
      child: RotationTransition(
        turns: _rotationController,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipOval(
              child: QueryArtworkWidget(
                key: ValueKey('vinyl_art_$songId'),
                id: songId,
                type: ArtworkType.AUDIO,
                artworkHeight: size,
                artworkWidth: size,
                artworkFit: BoxFit.cover,
                quality: 100,
                keepOldArtwork: true,
                nullArtworkWidget: _buildPlaceholderCircle(accent, size),
              ),
            ),
            // Vinyl grooves ring
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 2.5,
                ),
              ),
            ),
            // Center spindle hole
            Center(
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.bgDeep,
                  border: Border.all(
                    color: accent.withValues(alpha: 0.6),
                    width: 3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderCard(Color accent, double size) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [AppColors.bgGlass, AppColors.bgDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.music_note_rounded,
          size: size * 0.35,
          color: accent.withValues(alpha: 0.35),
        ),
      ),
    );
  }

  Widget _buildPlaceholderCircle(Color accent, double size) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppColors.divider, AppColors.bgGlass],
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

  Widget _buildBlurredBackground(int songId) {
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          QueryArtworkWidget(
            key: ValueKey('bg_art_$songId'),
            id: songId,
            type: ArtworkType.AUDIO,
            artworkFit: BoxFit.cover,
            quality: 40,
            size: 250,
            keepOldArtwork: true,
            nullArtworkWidget: Container(color: AppColors.bgDeep),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30.0, sigmaY: 30.0),
            child: Container(color: AppColors.bgDeep.withValues(alpha: 0.82)),
          ),
        ],
      ),
    );
  }

  // ── Song Info Row ────────────────────────────────────────────────────

  Widget _buildSongInfoRow(AppState app, Song song, Color accent) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 38,
                child: SmartMarquee(
                  text: song.title.isEmpty ? 'Unknown Title' : song.title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                  velocity: 35.0,
                  blankSpace: 30.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                song.artist.isEmpty ? 'Unknown Artist' : song.artist,
                style: TextStyle(
                  color: accent.withValues(alpha: 0.85),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Consumer<AppState>(
          builder: (context, appState, _) {
            final isFav = appState.isSongFavourited(song.id);
            return GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                if (isFav) {
                  appState.removeSongFromFavourites(song.id);
                } else {
                  appState.addCurrentSongToFavourites();
                }
              },
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Container(
                  key: ValueKey<bool>(isFav),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFav
                        ? Colors.redAccent.withValues(alpha: 0.15)
                        : AppColors.bgGlass,
                  ),
                  child: Icon(
                    isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: isFav ? Colors.redAccent : AppColors.textMuted,
                    size: 26,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ── Controls ─────────────────────────────────────────────────────────

  Widget _buildControls(AppState app, Song song, Color accent) {
    return StreamBuilder<PlayerState>(
      stream: app.player.playerStateStream,
      builder: (context, snapState) {
        final isPlaying = snapState.data?.playing ?? false;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Shuffle
            StreamBuilder<bool>(
              stream: app.player.shuffleEnabledStream,
              initialData: app.player.shuffleEnabled,
              builder: (context, snap) {
                final isShuffle = snap.data ?? false;
                return _SecondaryButton(
                  icon: Icons.shuffle_rounded,
                  isActive: isShuffle,
                  accent: accent,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    app.player.toggleShuffle();
                  },
                );
              },
            ),

            // Previous
            _TransportButton(
              icon: Icons.skip_previous_rounded,
              size: 38,
              onTap: () {
                HapticFeedback.lightImpact();
                app.player.previous();
              },
            ),

            // Play / Pause
            _PlayButton(
              isPlaying: isPlaying,
              accent: accent,
              onTap: () {
                HapticFeedback.mediumImpact();
                isPlaying ? app.player.pause() : app.player.play();
              },
            ),

            // Next
            _TransportButton(
              icon: Icons.skip_next_rounded,
              size: 38,
              onTap: () {
                HapticFeedback.lightImpact();
                app.player.next();
              },
            ),

            // Repeat
            StreamBuilder<PlaybackRepeatMode>(
              stream: app.player.repeatModeStream,
              initialData: app.player.repeatMode,
              builder: (context, snap) {
                final mode = snap.data ?? PlaybackRepeatMode.off;
                final isRepeatOne = mode == PlaybackRepeatMode.one;
                final isActive = mode != PlaybackRepeatMode.off;
                return _SecondaryButton(
                  icon: isRepeatOne
                      ? Icons.repeat_one_rounded
                      : Icons.repeat_rounded,
                  isActive: isActive,
                  accent: accent,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    app.player.toggleRepeat();
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }

  // ── Bottom Quick Action Bar ──────────────────────────────────────────

  Widget _buildBottomActionBar(
    BuildContext context,
    AppState app,
    Color accent,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Playback Speed Selector
        StreamBuilder<double>(
          stream: app.player.speedStream,
          initialData: app.player.speed,
          builder: (context, snapSpeed) {
            final spd = snapSpeed.data ?? 1.0;
            return GestureDetector(
              onTap: () => _openSpeedSelector(context, app, accent),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.bgGlass,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.speed_rounded, color: accent, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '${spd.toStringAsFixed(spd == spd.roundToDouble() ? 0 : 2)}x',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        // Up Next Queue Button
        GestureDetector(
          onTap: () => _openQueueSheet(context, app, accent),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accent.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.queue_music_rounded, color: accent, size: 17),
                const SizedBox(width: 6),
                Text(
                  'Up Next (${app.player.queue.length})',
                  style: TextStyle(
                    color: accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Sleep Timer Sheet ────────────────────────────────────────────────

  void _openSleepTimerSheet(BuildContext context, AppState app, Color accent) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgGlass,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final options = [
          ('Turn Off', null),
          ('15 minutes', const Duration(minutes: 15)),
          ('30 minutes', const Duration(minutes: 30)),
          ('45 minutes', const Duration(minutes: 45)),
          ('60 minutes', const Duration(minutes: 60)),
          ('90 minutes', const Duration(minutes: 90)),
        ];

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Sleep Timer',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                ...options.map((opt) {
                  final (label, dur) = opt;
                  final isCurrent = dur == null
                      ? app.sleepEndsAt == null
                      : false;

                  return ListTile(
                    dense: true,
                    title: Text(
                      label,
                      style: TextStyle(
                        color: isCurrent ? accent : AppColors.textPrimary,
                        fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    trailing: isCurrent
                        ? Icon(Icons.check_rounded, color: accent, size: 20)
                        : null,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      app.setSleepTimer(dur);
                      Navigator.of(ctx).pop();
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Speed Selector Sheet ─────────────────────────────────────────────

  void _openSpeedSelector(BuildContext context, AppState app, Color accent) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgGlass,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
        final currentSpeed = app.player.speed;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Playback Speed',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                ...speeds.map((s) {
                  final isSelected = (currentSpeed - s).abs() < 0.05;
                  return ListTile(
                    dense: true,
                    title: Text(
                      '${s}x ${s == 1.0 ? "(Normal)" : ""}',
                      style: TextStyle(
                        color: isSelected ? accent : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_rounded, color: accent, size: 20)
                        : null,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      app.player.setSpeed(s);
                      Navigator.of(ctx).pop();
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Up Next Queue Sheet ──────────────────────────────────────────────

  void _openQueueSheet(BuildContext context, AppState app, Color accent) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgDeep,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          expand: false,
          builder: (ctx, scrollController) {
            return StreamBuilder<List<Song>>(
              stream: app.player.queueStream,
              initialData: app.player.queue,
              builder: (context, snapQueue) {
                final queue = snapQueue.data ?? [];
                final currentIndex = app.player.currentIndex ?? 0;

                return Column(
                  children: [
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.divider,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Up Next Queue',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                '${queue.length} songs in queue',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          if (queue.isNotEmpty)
                            TextButton.icon(
                              onPressed: () async {
                                HapticFeedback.mediumImpact();
                                await app.player.clearQueue();
                                if (ctx.mounted) {
                                  Navigator.of(ctx).pop();
                                }
                              },
                              icon: const Icon(Icons.clear_all_rounded,
                                  color: Colors.redAccent, size: 18),
                              label: const Text(
                                'Clear',
                                style: TextStyle(color: Colors.redAccent, fontSize: 13),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: AppColors.divider),
                    Expanded(
                      child: queue.isEmpty
                          ? Center(
                              child: Text(
                                'Queue is empty',
                                style: TextStyle(
                                    color: AppColors.textMuted, fontSize: 14),
                              ),
                            )
                          : ReorderableListView.builder(
                              scrollController: scrollController,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 8),
                              itemCount: queue.length,
                              onReorder: (oldIndex, newIndex) {
                                HapticFeedback.selectionClick();
                                final target = newIndex > oldIndex
                                    ? newIndex - 1
                                    : newIndex;
                                app.player.moveQueueItem(oldIndex, target);
                              },
                              itemBuilder: (context, index) {
                                final song = queue[index];
                                final isCurrent = index == currentIndex;

                                return ListTile(
                                  key: ValueKey('queue_${song.id}_$index'),
                                  dense: true,
                                  leading: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isCurrent
                                          ? accent.withValues(alpha: 0.2)
                                          : AppColors.bgGlass,
                                    ),
                                    child: Center(
                                      child: isCurrent
                                          ? Icon(Icons.equalizer_rounded,
                                              color: accent, size: 18)
                                          : Text(
                                              '${index + 1}',
                                              style: TextStyle(
                                                color: AppColors.textMuted,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                    ),
                                  ),
                                  title: Text(
                                    song.title,
                                    style: TextStyle(
                                      color: isCurrent
                                          ? accent
                                          : AppColors.textPrimary,
                                      fontWeight: isCurrent
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    song.artist,
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.close_rounded,
                                            color: AppColors.textMuted, size: 18),
                                        onPressed: () {
                                          HapticFeedback.lightImpact();
                                          app.player.removeFromQueue(index);
                                        },
                                      ),
                                      Icon(Icons.drag_handle_rounded,
                                          color: AppColors.textMuted, size: 20),
                                    ],
                                  ),
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    app.player.skipTo(index);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  String _formatRemaining(Duration? d) {
    if (d == null || d == Duration.zero) return 'off';
    final m = d.inMinutes;
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

// ── Progress Section ─────────────────────────────────────────────────────────

class _ProgressSection extends StatefulWidget {
  final AppState app;
  final Song song;

  const _ProgressSection({required this.app, required this.song});

  @override
  State<_ProgressSection> createState() => _ProgressSectionState();
}

class _ProgressSectionState extends State<_ProgressSection> {
  double? _dragSeconds;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return StreamBuilder<Duration>(
      stream: widget.app.player.positionStream,
      initialData: Duration.zero,
      builder: (context, snapPos) {
        final pos = snapPos.data ?? Duration.zero;
        final total = widget.song.duration ?? Duration.zero;
        final totalSeconds =
            total.inSeconds == 0 ? 1.0 : total.inSeconds.toDouble();
        final currentSeconds =
            _dragSeconds ?? pos.inSeconds.toDouble().clamp(0.0, totalSeconds);

        final elapsed = Duration(seconds: currentSeconds.round());
        final remaining = total - elapsed;

        return Column(
          children: [
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 4,
                activeTrackColor: accent,
                inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
                thumbColor: Colors.white,
                overlayColor: accent.withValues(alpha: 0.2),
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 6,
                  elevation: 4,
                ),
              ),
              child: Slider(
                min: 0,
                max: totalSeconds,
                value: currentSeconds,
                onChanged: (v) => setState(() => _dragSeconds = v),
                onChangeEnd: (v) async {
                  setState(() => _dragSeconds = null);
                  await widget.app.player.seek(Duration(seconds: v.round()));
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(elapsed),
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  Text(
                    remaining.isNegative
                        ? '00:00'
                        : '-${_formatDuration(remaining)}',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

// ── Play and Transport Buttons ────────────────────────────────────────────────

class _PlayButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onTap;
  final Color accent;

  const _PlayButton({
    required this.isPlaying,
    required this.onTap,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 78,
        height: 78,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [accent.withValues(alpha: 0.85), accent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.45),
              blurRadius: 22,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(
          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: Colors.white,
          size: 42,
        ),
      ),
    );
  }
}

class _TransportButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTap;

  const _TransportButton({
    required this.icon,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white, size: size),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final Color accent;

  const _SecondaryButton({
    required this.icon,
    required this.isActive,
    required this.onTap,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            icon,
            color: isActive ? accent : AppColors.textMuted,
            size: 26,
          ),
          if (isActive)
            Positioned(
              bottom: 0,
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent,
                ),
              ),
            ),
        ],
      ),
    );
  }
}