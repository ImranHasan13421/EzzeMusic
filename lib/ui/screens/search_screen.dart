import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

import '../../models/song.dart';
import '../../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/shared/app_dialogs.dart';

enum SearchFilter { all, songs, artists, albums }

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _query = '';
  SearchFilter _filter = SearchFilter.all;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final q = _controller.text;
      if (q != _query) {
        setState(() => _query = q);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchSubmit(String query, AppState app) {
    if (query.trim().isNotEmpty) {
      app.addSearchQuery(query.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final app = context.watch<AppState>();
    final size = MediaQuery.of(context).size;

    final trimmed = _query.trim().toLowerCase();
    final allSongs = app.songsCache;

    // Filter results
    final matchedSongs = trimmed.isEmpty
        ? <Song>[]
        : allSongs.where((s) {
            return s.title.toLowerCase().contains(trimmed) ||
                s.artist.toLowerCase().contains(trimmed) ||
                s.album.toLowerCase().contains(trimmed);
          }).toList();

    final matchedArtists = trimmed.isEmpty
        ? <String>[]
        : app.artists
            .where((a) => a.toLowerCase().contains(trimmed))
            .toList();

    final matchedAlbums = trimmed.isEmpty
        ? <String>[]
        : app.albums.keys
            .where((a) => a.toLowerCase().contains(trimmed))
            .toList();

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
            // ── Search Input Field ──
            Padding(
              padding: EdgeInsets.fromLTRB(size.width * 0.05, 16, size.width * 0.05, 10),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.bgGlass,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _focusNode.hasFocus
                        ? accent.withValues(alpha: 0.6)
                        : AppColors.divider,
                  ),
                  boxShadow: [
                    if (_focusNode.hasFocus)
                      BoxShadow(
                        color: accent.withValues(alpha: 0.15),
                        blurRadius: 16,
                      ),
                  ],
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (val) => _onSearchSubmit(val, app),
                  decoration: InputDecoration(
                    hintText: 'Search songs, artists, albums...',
                    hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
                    prefixIcon: Icon(Icons.search_rounded, color: accent, size: 22),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.close_rounded,
                                color: AppColors.textMuted, size: 18),
                            onPressed: () {
                              _controller.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),

            // ── Filter Chips Row ──
            if (trimmed.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: size.width * 0.05, vertical: 4),
                child: Row(
                  children: SearchFilter.values.map((f) {
                    final isSelected = _filter == f;
                    final label = switch (f) {
                      SearchFilter.all => 'All',
                      SearchFilter.songs => 'Songs (${matchedSongs.length})',
                      SearchFilter.artists => 'Artists (${matchedArtists.length})',
                      SearchFilter.albums => 'Albums (${matchedAlbums.length})',
                    };

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _filter = f);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? accent
                                : AppColors.bgGlass.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? accent
                                  : AppColors.divider.withValues(alpha: 0.6),
                            ),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

            // ── Body ──
            Expanded(
              child: trimmed.isEmpty
                  ? _buildEmptyOrHistory(app, accent)
                  : _buildResultsList(
                      app: app,
                      accent: accent,
                      songs: matchedSongs,
                      artists: matchedArtists,
                      albums: matchedAlbums,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── History & Empty Suggestions ──
  Widget _buildEmptyOrHistory(AppState app, Color accent) {
    final recent = app.recentSearches;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 130),
      children: [
        if (recent.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Searches',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextButton(
                onPressed: () => app.clearRecentSearches(),
                child: Text(
                  'Clear all',
                  style: TextStyle(color: accent, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: recent.map((term) {
              return ActionChip(
                backgroundColor: AppColors.bgGlass,
                side: BorderSide(color: AppColors.divider),
                avatar: Icon(Icons.history_rounded,
                    color: AppColors.textMuted, size: 16),
                label: Text(
                  term,
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                ),
                onPressed: () {
                  _controller.text = term;
                  _controller.selection =
                      TextSelection.fromPosition(TextPosition(offset: term.length));
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
        ],

        // Suggestions / Discovery
        Text(
          'Quick Browse',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickBrowseCard(
                title: 'Liked Songs',
                subtitle: '${app.likedSongs.length} tracks',
                icon: Icons.favorite_rounded,
                iconColor: Colors.redAccent,
                onTap: () {
                  final liked = app.likedSongs;
                  if (liked.isNotEmpty) {
                    app.player.setQueue(liked, startIndex: 0, playWhenReady: true);
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickBrowseCard(
                title: 'Shuffle All',
                subtitle: '${app.songsCache.length} tracks',
                icon: Icons.shuffle_rounded,
                iconColor: accent,
                onTap: () {
                  if (app.songsCache.isNotEmpty) {
                    app.playSongsShuffled(app.songsCache);
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Results List ──
  Widget _buildResultsList({
    required AppState app,
    required Color accent,
    required List<Song> songs,
    required List<String> artists,
    required List<String> albums,
  }) {
    final showSongs = (_filter == SearchFilter.all || _filter == SearchFilter.songs) &&
        songs.isNotEmpty;
    final showArtists = (_filter == SearchFilter.all || _filter == SearchFilter.artists) &&
        artists.isNotEmpty;
    final showAlbums = (_filter == SearchFilter.all || _filter == SearchFilter.albums) &&
        albums.isNotEmpty;

    if (!showSongs && !showArtists && !showAlbums) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, color: AppColors.textMuted, size: 48),
            const SizedBox(height: 16),
            Text(
              'No results for "$_query"',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Check your spelling or try another keyword',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 130),
      children: [
        // ── Artists Section ──
        if (showArtists) ...[
          _SectionTitle(title: 'Artists', count: artists.length, accent: accent),
          ...artists.take(_filter == SearchFilter.all ? 3 : 20).map((art) {
            final artSongs = app.songsForArtist(art);
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.15),
                ),
                child: Center(
                  child: Text(
                    art.isNotEmpty ? art[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              title: Text(
                art,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                '${artSongs.length} songs',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              onTap: () {
                _onSearchSubmit(_query, app);
                if (artSongs.isNotEmpty) {
                  app.player.setQueue(artSongs, startIndex: 0, playWhenReady: true);
                }
              },
            );
          }),
          const SizedBox(height: 16),
        ],

        // ── Albums Section ──
        if (showAlbums) ...[
          _SectionTitle(title: 'Albums', count: albums.length, accent: accent),
          ...albums.take(_filter == SearchFilter.all ? 3 : 20).map((alb) {
            final albSongs = app.albums[alb] ?? [];
            final firstSong = albSongs.isNotEmpty ? albSongs.first : null;
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
                  child: firstSong != null
                      ? QueryArtworkWidget(
                          id: firstSong.id,
                          type: ArtworkType.AUDIO,
                          artworkFit: BoxFit.cover,
                          nullArtworkWidget: Icon(
                            Icons.album_rounded,
                            color: AppColors.textMuted,
                            size: 24,
                          ),
                        )
                      : Icon(Icons.album_rounded,
                          color: AppColors.textMuted, size: 24),
                ),
              ),
              title: Text(
                alb,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                '${albSongs.length} tracks',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              onTap: () {
                _onSearchSubmit(_query, app);
                if (albSongs.isNotEmpty) {
                  app.player.setQueue(albSongs, startIndex: 0, playWhenReady: true);
                }
              },
            );
          }),
          const SizedBox(height: 16),
        ],

        // ── Songs Section ──
        if (showSongs) ...[
          _SectionTitle(title: 'Songs', count: songs.length, accent: accent),
          ...songs.map((song) {
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
                      child: Icon(
                        Icons.music_note_rounded,
                        color: isPlaying ? accent : AppColors.textMuted,
                        size: 22,
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
                '${song.artist} • ${song.album.isNotEmpty ? song.album : "Unknown Album"}',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                icon: Icon(Icons.more_vert_rounded,
                    color: AppColors.textMuted, size: 20),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => SongDetailsDialog(song: song, accentColor: accent),
                  );
                },
              ),
              onTap: () {
                _onSearchSubmit(_query, app);
                app.playSong(song, contextQueue: songs);
              },
            );
          }),
        ],
      ],
    );
  }
}

// ── Components ────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final int count;
  final Color accent;

  const _SectionTitle({
    required this.title,
    required this.count,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 6, top: 4),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: accent.withValues(alpha: 0.9),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.bgGlass,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickBrowseCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _QuickBrowseCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgGlass,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
