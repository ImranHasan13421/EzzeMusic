import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/shared/action_buttons.dart';
import '../widgets/shared/app_dialogs.dart';
import 'playlist_detail_screen.dart';

class PlaylistsScreen extends StatelessWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final app = context.watch<AppState>();
    final playlists = app.playlists;
    final size = MediaQuery.of(context).size;

    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.4),
          radius: 1.1,
          colors: [AppColors.bgGlass, AppColors.bgDeep],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: EdgeInsets.fromLTRB(size.width * 0.06, 20, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PLAYLISTS',
                    style: TextStyle(
                      color: accent.withValues(alpha: 0.8),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your Library',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${playlists.length} ${playlists.length == 1 ? 'playlist' : 'playlists'}',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // New playlist button
                      GestureDetector(
                        onTap: () => _createPlaylist(context, accent),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [accent.withValues(alpha: 0.85), accent],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(50),
                            boxShadow: [
                              BoxShadow(
                                color: accent.withValues(alpha: 0.35),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_rounded, color: Colors.white, size: 18),
                              SizedBox(width: 6),
                              Text(
                                'New',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
                ],
              ),
            ),

            // ── Body ──
            Expanded(
              child: playlists.isEmpty
                  ? _buildEmptyState(context, accent)
                  : _buildPlaylistList(context, app, playlists, size, accent),
            ),
          ],
        ),
      ),
    );
  }

  // ── Playlist list ──
  Widget _buildPlaylistList(
    BuildContext context,
    AppState app,
    List playlists,
    Size size,
    Color accent,
  ) {
    final customPlaylists = playlists.where((p) => p.id != 'pl_favourites').toList();
    final likedCount = app.likedSongs.length;
    final favPlaylist = app.favouritesPlaylist;

    return ListView(
      padding: EdgeInsets.fromLTRB(size.width * 0.04, 4, size.width * 0.04, 130),
      children: [
        // ── Liked Songs Hero Card ──
        GestureDetector(
          onTap: () {
            if (favPlaylist != null) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PlaylistDetailScreen(playlistId: favPlaylist.id),
                ),
              );
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFE91E63).withValues(alpha: 0.25),
                  accent.withValues(alpha: 0.15),
                  AppColors.bgGlass,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFE91E63).withValues(alpha: 0.35),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE91E63).withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF4081), Color(0xFFE040FB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF4081).withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.favorite_rounded, color: Colors.white, size: 28),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Liked Songs',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$likedCount ${likedCount == 1 ? 'favorite track' : 'favorite tracks'}',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (likedCount > 0)
                  IconButton(
                    icon: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent,
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    onPressed: () {
                      final songs = app.likedSongs;
                      if (songs.isNotEmpty) {
                        app.player.setQueue(songs, startIndex: 0, playWhenReady: true);
                      }
                    },
                  ),
              ],
            ),
          ),
        ),

        // ── Custom Playlists Header ──
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'YOUR PLAYLISTS (${customPlaylists.length})',
                style: TextStyle(
                  color: accent.withValues(alpha: 0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),

        if (customPlaylists.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.bgGlass.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.playlist_add_rounded,
                  color: AppColors.textMuted,
                  size: 32,
                ),
                const SizedBox(height: 10),
                Text(
                  'No custom playlists yet',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap "New" at the top to create one',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          )
        else
          ...customPlaylists.map((p) {
            return Column(
              children: [
                _PlaylistRow(
                  name: p.name,
                  songCount: p.songIds.length,
                  accentColor: accent,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PlaylistDetailScreen(playlistId: p.id),
                    ),
                  ),
                  onRename: () => _renamePlaylist(context, p.id, p.name, accent),
                  onDelete: () => context.read<AppState>().deletePlaylist(p.id),
                ),
                Divider(height: 1, color: AppColors.divider, indent: 72),
              ],
            );
          }),
      ],
    );
  }

  // ── Empty state ──
  Widget _buildEmptyState(BuildContext context, Color accent) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.bgGlass,
              border: Border.all(color: AppColors.divider),
            ),
            child: Icon(
              Icons.queue_music_rounded,
              color: AppColors.textMuted,
              size: 36,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No playlists yet',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Create your first playlist to organize tracks',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => _createPlaylist(context, accent),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: accent.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, color: accent, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Create Playlist',
                    style: TextStyle(
                      color: accent,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Create dialog ──
  Future<void> _createPlaylist(BuildContext context, Color accent) async {
    final ctrl = TextEditingController();
    final ok = await _showPlaylistDialog(
      context: context,
      title: 'New Playlist',
      hint: 'Playlist name',
      confirmLabel: 'Create',
      controller: ctrl,
      accent: accent,
    );
    if (ok != true) return;
    if (!context.mounted) return;
    if (ctrl.text.trim().isNotEmpty) {
      await context.read<AppState>().createPlaylist(ctrl.text.trim());
    }
  }

  // ── Rename dialog ──
  Future<void> _renamePlaylist(
    BuildContext context,
    String playlistId,
    String currentName,
    Color accent,
  ) async {
    final ctrl = TextEditingController(text: currentName);
    final ok = await _showPlaylistDialog(
      context: context,
      title: 'Rename Playlist',
      hint: 'Playlist name',
      confirmLabel: 'Save',
      controller: ctrl,
      accent: accent,
    );
    if (ok != true) return;
    if (!context.mounted) return;
    if (ctrl.text.trim().isNotEmpty) {
      await context.read<AppState>().renamePlaylist(playlistId, ctrl.text.trim());
    }
  }

  Future<bool?> _showPlaylistDialog({
    required BuildContext context,
    required String title,
    required String hint,
    required String confirmLabel,
    required TextEditingController controller,
    required Color accent,
  }) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => ThemedInputDialog(
        title: title,
        hint: hint,
        confirmLabel: confirmLabel,
        controller: controller,
        accentColor: accent,
      ),
    );
  }
}

// ── Playlist Row ─────────────────────────────────────────────────────────────

class _PlaylistRow extends StatefulWidget {
  final String name;
  final int songCount;
  final Color accentColor;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const _PlaylistRow({
    required this.name,
    required this.songCount,
    required this.accentColor,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

  @override
  State<_PlaylistRow> createState() => _PlaylistRowState();
}

class _PlaylistRowState extends State<_PlaylistRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        transform: Matrix4.diagonal3Values(
          _pressed ? 0.98 : 1.0,
          _pressed ? 0.98 : 1.0,
          1.0,
        ),
        transformAlignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        decoration: BoxDecoration(
          color: _pressed ? AppColors.bgGlass.withValues(alpha: 0.6) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.bgGlass,
                border: Border.all(color: AppColors.divider),
              ),
              child: Icon(
                Icons.queue_music_rounded,
                color: widget.songCount > 0 ? widget.accentColor : AppColors.textMuted,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.name,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.songCount} ${widget.songCount == 1 ? 'song' : 'songs'}',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            ThemedMenu(
              onSelected: (val) {
                if (val == 'rename') widget.onRename();
                if (val == 'delete') widget.onDelete();
              },
              items: const [
                PopupMenuItem(
                  value: 'rename',
                  child: ThemedMenuItem(
                    icon: Icons.drive_file_rename_outline_rounded,
                    label: 'Rename',
                  ),
                ),
                PopupMenuDivider(height: 1),
                PopupMenuItem(
                  value: 'delete',
                  child: ThemedMenuItem(
                    icon: Icons.delete_outline_rounded,
                    label: 'Delete',
                    isDestructive: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}