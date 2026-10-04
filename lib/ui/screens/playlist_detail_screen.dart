import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/song.dart';
import '../../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/mini_player_bar.dart';
import '../widgets/shared/action_buttons.dart';
import '../widgets/shared/app_dialogs.dart';
import 'now_playing_screen.dart';

class PlaylistDetailScreen extends StatelessWidget {
  final String playlistId;

  const PlaylistDetailScreen({super.key, required this.playlistId});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final app = context.watch<AppState>();

    // Safety check for deleted playlists
    final playlistIndex = app.playlists.indexWhere((p) => p.id == playlistId);
    if (playlistIndex == -1) {
      return const Scaffold(body: Center(child: Text('Playlist not found')));
    }
    final playlist = app.playlists[playlistIndex];

    final songsById = {for (final s in app.songsCache) s.id: s};
    final songs = playlist.songIds
        .map((id) => songsById[id])
        .whereType<Song>()
        .toList();

    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      extendBody: true,
      appBar: _buildAppBar(context, playlist, accent),
      floatingActionButton: _buildFAB(context, accent),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.4),
            radius: 1.2,
            colors: [AppColors.bgGlass, AppColors.bgDeep],
          ),
        ),
        child: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: songs.isEmpty
                ? _buildEmptyState(context, accent)
                : _buildSongList(context, app, songs),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: MiniPlayerBar(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, anim, _) => const NowPlayingScreen(),
                transitionsBuilder: (context, anim, _, child) {
                  return SlideTransition(
                    position: Tween(begin: const Offset(0, 1), end: Offset.zero)
                        .chain(CurveTween(curve: Curves.easeOutQuart))
                        .animate(anim),
                    child: child,
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, dynamic playlist, Color accent) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(
          Icons.keyboard_arrow_left_rounded,
          color: Colors.white,
          size: 32,
        ),
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.maybePop(context);
        },
      ),
      title: Column(
        children: [
          Text(
            'PLAYLIST',
            style: TextStyle(
              color: accent.withValues(alpha: 0.6),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            playlist.name,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
      actions: [
        IconCircleButton(
          onTap: () {
            HapticFeedback.lightImpact();
            _renameDialog(context, playlist);
          },
          child: Icon(
            Icons.drive_file_rename_outline_rounded,
            color: AppColors.textSecondary,
            size: 18,
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildFAB(BuildContext context, Color accent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 80.0),
      child: FloatingActionButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          _openAddSongs(context);
        },
        backgroundColor: accent,
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildSongList(BuildContext context, AppState app, List<Song> songs) {
    final accent = Theme.of(context).colorScheme.primary;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
      physics: const BouncingScrollPhysics(),
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        return _DetailSongRow(
          song: song,
          index: index,
          accentColor: accent,
          onPlay: () {
            HapticFeedback.selectionClick();
            app.player.setQueue(songs, startIndex: index);
          },
          onRemove: () {
            HapticFeedback.lightImpact();
            app.removeSongFromPlaylist(playlistId: playlistId, songId: song.id);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, Color accent) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.bgGlass,
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Icon(
              Icons.music_off_rounded,
              size: 48,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Your playlist is empty',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to add your favorite tracks.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _renameDialog(BuildContext context, dynamic playlist) async {
    final ctrl = TextEditingController(text: playlist.name);
    final accent = Theme.of(context).colorScheme.primary;

    final ok = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (_) => ThemedInputDialog(
        title: 'Rename Playlist',
        hint: 'Enter name...',
        confirmLabel: 'Update',
        controller: ctrl,
        accentColor: accent,
      ),
    );
    if (ok == true && ctrl.text.trim().isNotEmpty) {
      if (!context.mounted) return;
      await context.read<AppState>().renamePlaylist(playlistId, ctrl.text.trim());
    }
  }

  Future<void> _openAddSongs(BuildContext context) async {
    final app = context.read<AppState>();
    if (app.songsCache.isEmpty) await app.refreshLibrarySongs();
    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => _AddSongsSheet(playlistId: playlistId),
    );
  }
}

// ── Detail Song Row ─────────────────────────────────────────────────────────

class _DetailSongRow extends StatefulWidget {
  final Song song;
  final int index;
  final Color accentColor;
  final VoidCallback onPlay;
  final VoidCallback onRemove;

  const _DetailSongRow({
    required this.song,
    required this.index,
    required this.accentColor,
    required this.onPlay,
    required this.onRemove,
  });

  @override
  State<_DetailSongRow> createState() => _DetailSongRowState();
}

class _DetailSongRowState extends State<_DetailSongRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();

    return StreamBuilder<Song?>(
      stream: app.player.currentSongStream,
      initialData: app.player.currentSong,
      builder: (context, snap) {
        final isPlaying = snap.data?.id == widget.song.id;
        final color = isPlaying ? widget.accentColor : AppColors.textPrimary;

        return GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) {
            setState(() => _pressed = false);
            widget.onPlay();
          },
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: _pressed
                  ? Colors.white.withValues(alpha: 0.05)
                  : (isPlaying
                      ? widget.accentColor.withValues(alpha: 0.08)
                      : Colors.transparent),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: isPlaying
                        ? Icon(
                            Icons.bar_chart_rounded,
                            color: widget.accentColor,
                            size: 20,
                            key: const ValueKey('playing'),
                          )
                        : Text(
                            '${widget.index + 1}'.padLeft(2, '0'),
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            key: const ValueKey('index'),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.song.title,
                        style: TextStyle(
                          color: color,
                          fontSize: 14,
                          fontWeight:
                              isPlaying ? FontWeight.w900 : FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.song.artist,
                        style: TextStyle(
                          color: isPlaying
                              ? widget.accentColor.withValues(alpha: 0.7)
                              : AppColors.textSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: widget.onRemove,
                  icon: const Icon(
                    Icons.remove_circle_outline_rounded,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                  style: IconButton.styleFrom(visualDensity: VisualDensity.compact),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Add Songs Bottom Sheet ───────────────────────────────────────────────────

class _AddSongsSheet extends StatelessWidget {
  final String playlistId;

  const _AddSongsSheet({required this.playlistId});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final app = context.watch<AppState>();
    final songs = app.songsCache;
    final playlist = app.playlists.firstWhere((p) => p.id == playlistId);
    final Set<int> existingSongIds = playlist.songIds.toSet();

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F13),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 40)],
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ADD TO PLAYLIST',
                        style: TextStyle(
                          color: accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${songs.length} tracks found',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                IconCircleButton(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white10),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
              physics: const BouncingScrollPhysics(),
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final s = songs[index];
                return _AddSongRow(
                  song: s,
                  index: index,
                  accentColor: accent,
                  isInitiallyAdded: existingSongIds.contains(s.id),
                  onAdd: () => app.addSongToPlaylist(
                    playlistId: playlistId,
                    songId: s.id,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AddSongRow extends StatefulWidget {
  final Song song;
  final int index;
  final Color accentColor;
  final bool isInitiallyAdded;
  final VoidCallback onAdd;

  const _AddSongRow({
    required this.song,
    required this.index,
    required this.accentColor,
    required this.isInitiallyAdded,
    required this.onAdd,
  });

  @override
  State<_AddSongRow> createState() => _AddSongRowState();
}

class _AddSongRowState extends State<_AddSongRow> {
  late bool _added;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _added = widget.isInitiallyAdded;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _pressed ? Colors.white.withValues(alpha: 0.03) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.song.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.song.artist,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: _added
                  ? null
                  : () {
                      HapticFeedback.lightImpact();
                      widget.onAdd();
                      setState(() => _added = true);
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutBack,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _added
                      ? widget.accentColor.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _added ? widget.accentColor : Colors.white10,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _added ? Icons.check_rounded : Icons.add_rounded,
                      color: _added ? widget.accentColor : Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _added ? 'Added' : 'Add',
                      style: TextStyle(
                        color: _added ? widget.accentColor : Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}