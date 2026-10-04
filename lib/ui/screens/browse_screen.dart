import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

import '../../models/song.dart';
import '../../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/shared/action_buttons.dart';

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final app = context.watch<AppState>();
    final size = MediaQuery.of(context).size;

    final artists = app.artists;
    final albums = app.albums;

    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.4),
          radius: 1.1,
          colors: [AppColors.bgGlass, AppColors.bgDeep],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Padding(
              padding: EdgeInsets.fromLTRB(size.width * 0.06, 20, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DISCOVER',
                    style: TextStyle(
                      color: accent.withValues(alpha: 0.8),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Artists & Albums',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),

            // ── Segmented Tab Switcher ──
            Padding(
              padding: EdgeInsets.symmetric(horizontal: size.width * 0.05, vertical: 8),
              child: Container(
                height: 44,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.bgGlass,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.divider),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textMuted,
                  labelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                  tabs: [
                    Tab(text: 'Artists (${artists.length})'),
                    Tab(text: 'Albums (${albums.length})'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ── Tab Views ──
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildArtistsTab(context, app, artists, accent),
                  _buildAlbumsTab(context, app, albums, accent),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── ARTISTS TAB ─────────────────────────────────────────────────────────────

  Widget _buildArtistsTab(
    BuildContext context,
    AppState app,
    List<String> artists,
    Color accent,
  ) {
    if (artists.isEmpty) {
      return _buildEmptyState(
        icon: Icons.person_rounded,
        title: 'No artists found',
        subtitle: 'Add songs with artist metadata to explore artists',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 130),
      itemCount: artists.length,
      separatorBuilder: (context, index) =>
          Divider(height: 1, color: AppColors.divider, indent: 72),
      itemBuilder: (context, index) {
        final artist = artists[index];
        final artistSongs = app.songsForArtist(artist);
        final firstSong = artistSongs.isNotEmpty ? artistSongs.first : null;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.15),
              border: Border.all(color: accent.withValues(alpha: 0.3)),
            ),
            child: ClipOval(
              child: firstSong != null
                  ? QueryArtworkWidget(
                      id: firstSong.id,
                      type: ArtworkType.AUDIO,
                      artworkFit: BoxFit.cover,
                      nullArtworkWidget: Center(
                        child: Text(
                          artist.isNotEmpty ? artist[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: accent,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Icon(Icons.person_rounded, color: accent, size: 24),
                    ),
            ),
          ),
          title: Text(
            artist,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${artistSongs.length} ${artistSongs.length == 1 ? 'song' : 'songs'}',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textMuted,
            size: 22,
          ),
          onTap: () => _openArtistDetail(context, app, artist, artistSongs, accent),
        );
      },
    );
  }

  // ── ALBUMS TAB ─────────────────────────────────────────────────────────────

  Widget _buildAlbumsTab(
    BuildContext context,
    AppState app,
    Map<String, List<Song>> albums,
    Color accent,
  ) {
    if (albums.isEmpty) {
      return _buildEmptyState(
        icon: Icons.album_rounded,
        title: 'No albums found',
        subtitle: 'Add songs with album metadata to explore albums',
      );
    }

    final albumKeys = albums.keys.toList();

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 130),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 16,
        childAspectRatio: 0.76,
      ),
      itemCount: albumKeys.length,
      itemBuilder: (context, index) {
        final albumName = albumKeys[index];
        final songs = albums[albumName] ?? [];
        final firstSong = songs.isNotEmpty ? songs.first : null;
        final artist = firstSong?.artist.isNotEmpty == true
            ? firstSong!.artist
            : 'Various Artists';

        return GestureDetector(
          onTap: () => _openAlbumDetail(context, app, albumName, artist, songs, accent),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.bgGlass,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Album Art
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (firstSong != null)
                          QueryArtworkWidget(
                            id: firstSong.id,
                            type: ArtworkType.AUDIO,
                            artworkFit: BoxFit.cover,
                            nullArtworkWidget: Container(
                              color: AppColors.bgDeep,
                              child: Center(
                                child: Icon(
                                  Icons.album_rounded,
                                  color: accent.withValues(alpha: 0.4),
                                  size: 48,
                                ),
                              ),
                            ),
                          )
                        else
                          Container(
                            color: AppColors.bgDeep,
                            child: Center(
                              child: Icon(
                                Icons.album_rounded,
                                color: accent.withValues(alpha: 0.4),
                                size: 48,
                              ),
                            ),
                          ),
                        // Soft vignette
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.4),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Album Info
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        albumName,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        artist,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${songs.length} ${songs.length == 1 ? 'track' : 'tracks'}',
                        style: TextStyle(
                          color: accent.withValues(alpha: 0.8),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── DETAIL VIEWS ────────────────────────────────────────────────────────────

  void _openArtistDetail(
    BuildContext context,
    AppState app,
    String artist,
    List<Song> songs,
    Color accent,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _GroupDetailScreen(
          title: artist,
          subtitle: 'Artist • ${songs.length} tracks',
          songs: songs,
          accent: accent,
          isArtist: true,
        ),
      ),
    );
  }

  void _openAlbumDetail(
    BuildContext context,
    AppState app,
    String album,
    String artist,
    List<Song> songs,
    Color accent,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _GroupDetailScreen(
          title: album,
          subtitle: '$artist • ${songs.length} tracks',
          songs: songs,
          accent: accent,
          isArtist: false,
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.bgGlass,
              border: Border.all(color: AppColors.divider),
            ),
            child: Icon(icon, color: AppColors.textMuted, size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ── Generic Group Detail Screen (Artist / Album) ──────────────────────────────

class _GroupDetailScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Song> songs;
  final Color accent;
  final bool isArtist;

  const _GroupDetailScreen({
    required this.title,
    required this.subtitle,
    required this.songs,
    required this.accent,
    required this.isArtist,
  });

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final firstSong = songs.isNotEmpty ? songs.first : null;

    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: Container(
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
              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    IconCircleButton(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Hero Action Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: [
                    // Artwork preview
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(isArtist ? 36 : 12),
                        color: accent.withValues(alpha: 0.12),
                        border: Border.all(color: accent.withValues(alpha: 0.25)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(isArtist ? 36 : 12),
                        child: firstSong != null
                            ? QueryArtworkWidget(
                                id: firstSong.id,
                                type: ArtworkType.AUDIO,
                                artworkFit: BoxFit.cover,
                                nullArtworkWidget: Icon(
                                  isArtist ? Icons.person_rounded : Icons.album_rounded,
                                  color: accent,
                                  size: 32,
                                ),
                              )
                            : Icon(
                                isArtist ? Icons.person_rounded : Icons.album_rounded,
                                color: accent,
                                size: 32,
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Play All & Shuffle Buttons
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                HapticFeedback.mediumImpact();
                                await app.player.setQueue(songs, startIndex: 0, playWhenReady: true);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accent,
                                foregroundColor: Colors.white,
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              icon: const Icon(Icons.play_arrow_rounded, size: 20),
                              label: const Text(
                                'Play',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                HapticFeedback.mediumImpact();
                                await app.playSongsShuffled(songs);
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: accent.withValues(alpha: 0.5)),
                                foregroundColor: accent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              icon: const Icon(Icons.shuffle_rounded, size: 18),
                              label: const Text(
                                'Shuffle',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Divider(height: 1, color: AppColors.divider),

              // Song List
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
                  itemCount: songs.length,
                  separatorBuilder: (context, index) =>
                      Divider(height: 1, color: AppColors.divider, indent: 64),
                  itemBuilder: (context, index) {
                    final song = songs[index];
                    final isPlaying = app.player.currentSong?.id == song.id;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: AppColors.bgGlass,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: QueryArtworkWidget(
                            id: song.id,
                            type: ArtworkType.AUDIO,
                            artworkFit: BoxFit.cover,
                            nullArtworkWidget: Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: isPlaying ? accent : AppColors.textMuted,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        song.title,
                        style: TextStyle(
                          color: isPlaying ? accent : AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: isPlaying ? FontWeight.w800 : FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        song.artist,
                        style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(
                        _formatDuration(song.duration),
                        style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                      ),
                      onTap: () async {
                        HapticFeedback.lightImpact();
                        await app.player.setQueue(songs, startIndex: index, playWhenReady: true);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDuration(Duration? d) {
    if (d == null) return '--:--';
    final m = d.inMinutes;
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
