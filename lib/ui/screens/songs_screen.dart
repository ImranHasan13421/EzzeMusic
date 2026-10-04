import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/song.dart';
import '../../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/shared/action_buttons.dart';
import '../widgets/shared/app_dialogs.dart';

enum SongSort { az, za }

class SongsScreen extends StatefulWidget {
  const SongsScreen({super.key});

  @override
  State<SongsScreen> createState() => _SongsScreenState();
}

class _SongsScreenState extends State<SongsScreen> {
  SongSort _sort = SongSort.az;
  bool _loading = false;
  String? _error;

  // ── Search & Scroll Logic ──
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';

  // ── High Performance Caching (Fixes App Freezing) ──
  List<Song>? _lastCache;
  String _lastQuery = '';
  SongSort _lastSort = SongSort.az;
  List<Song> _cachedDisplaySongs = [];

  // ── Bulk Selection State ──
  final Set<int> _selectedIds = {};
  bool get _isSelectionMode => _selectedIds.isNotEmpty;

  // ── Alphabet Scrollbar State ──
  bool _isDraggingAlpha = false;
  String _currentAlpha = '';
  final List<String> _alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ#'.split('');

  // ── Initial load future (cached to prevent FutureBuilder rebuild loop) ──
  Future<void>? _initialLoadFuture;

  @override
  void initState() {
    super.initState();
    // Sync _searchQuery to the controller so search actually works
    _searchController.addListener(() {
      final text = _searchController.text;
      if (text != _searchQuery) {
        setState(() => _searchQuery = text);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Cache the initial load future so FutureBuilder doesn't re-trigger on every build
    _initialLoadFuture ??= _ensureLoaded(context.read<AppState>());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showSnack(String msg, Color accent) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: TextStyle(
            color: accent,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        backgroundColor: AppColors.bgGlass,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: accent.withValues(alpha: 0.3)),
        ),
        elevation: 8,
      ),
    );
  }

  Future<void> _ensureLoaded(AppState app) async {
    if (app.songsCache.isNotEmpty) return;
    await app.refreshLibrarySongs(forceRescan: false);
  }

  Future<void> _refresh(AppState app, {bool forceRescan = true}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await app.refreshLibrarySongs(forceRescan: forceRescan);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Memoized sorting to prevent main thread ANR stutters
  List<Song> _getFilteredAndSorted(List<Song> masterList) {
    if (_lastCache == masterList &&
        _lastQuery == _searchQuery &&
        _lastSort == _sort) {
      return _cachedDisplaySongs;
    }

    List<Song> filtered = masterList;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = masterList
          .where((s) =>
              s.title.toLowerCase().contains(q) ||
              s.artist.toLowerCase().contains(q))
          .toList();
    } else {
      filtered = List.of(masterList);
    }

    filtered.sort((a, b) =>
        a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    if (_sort == SongSort.za) {
      filtered = filtered.reversed.toList();
    }

    _lastCache = masterList;
    _lastQuery = _searchQuery;
    _lastSort = _sort;
    _cachedDisplaySongs = filtered;

    return _cachedDisplaySongs;
  }

  void _toggleSelection(int songId) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedIds.contains(songId)) {
        _selectedIds.remove(songId);
      } else {
        _selectedIds.add(songId);
      }
    });
  }

  void _selectAll(List<Song> displaySongs) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_selectedIds.length == displaySongs.length) {
        _selectedIds.clear();
      } else {
        _selectedIds.addAll(displaySongs.map((s) => s.id));
      }
    });
  }

  Future<void> _addToFavourites(
    List<Song> songsToAdd,
    AppState app,
    Color accent,
  ) async {
    await app.addSongsToFavourites(songsToAdd.map((s) => s.id).toList());
    if (!mounted) return;
    setState(() => _selectedIds.clear());
    _showSnack('Added to Favourites', accent);
  }

  void _addToPlaylist(List<Song> songsToAdd, AppState app, Color accent) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SelectPlaylistSheet(
        app: app,
        accentColor: accent,
        onSelect: (playlistId) async {
          for (final s in songsToAdd) {
            await app.addSongToPlaylist(playlistId: playlistId, songId: s.id);
          }
          if (!context.mounted) return;
          Navigator.pop(context);
          if (!mounted) return;
          setState(() => _selectedIds.clear());
          _showSnack('Added to playlist', accent);
        },
      ),
    );
  }

  void _showDetails(Song song, Color accent) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (_) => SongDetailsDialog(song: song, accentColor: accent),
    );
  }

  void _scrollToLetter(String letter, List<Song> displaySongs) {
    if (displaySongs.isEmpty) return;
    int index = displaySongs.indexWhere((s) {
      final firstChar = s.title.trim().toUpperCase();
      if (firstChar.isEmpty) return false;
      if (letter == '#') return !RegExp(r'[A-Z]').hasMatch(firstChar[0]);
      return firstChar.startsWith(letter);
    });

    if (index != -1) {
      final offset = index * 65.0;
      _scrollController.jumpTo(
        offset.clamp(0.0, _scrollController.position.maxScrollExtent),
      );
    }
  }

  void _handleAlphaDrag(double dy, double maxHeight, List<Song> displaySongs) {
    if (dy < 0 || dy > maxHeight) return;
    int index = (dy / maxHeight * _alphabet.length).floor();
    index = index.clamp(0, _alphabet.length - 1);
    final letter = _alphabet[index];

    if (_currentAlpha != letter) {
      HapticFeedback.selectionClick();
      setState(() {
        _currentAlpha = letter;
        _isDraggingAlpha = true;
      });
      _scrollToLetter(letter, displaySongs);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final songsCache = context.select<AppState, List<Song>>((a) => a.songsCache);
    final app = context.read<AppState>();

    return FutureBuilder<void>(
      future: _initialLoadFuture,
      builder: (context, snap) {
        final displaySongs = _getFilteredAndSorted(songsCache);

        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.4),
              radius: 1.1,
              colors: [AppColors.bgGlass, AppColors.bgDeep],
            ),
          ),
          child: Column(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SizeTransition(sizeFactor: animation, child: child),
                ),
                child: _isSelectionMode
                    ? _buildSelectionHeader(context, app, displaySongs, accent)
                    : _buildNormalHeader(context, app, displaySongs, accent),
              ),

              if (_error != null) _buildErrorBanner(),

              Expanded(
                child: Stack(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: displaySongs.isEmpty && !_loading
                          ? _buildEmptyState(context, app, accent)
                          : RefreshIndicator(
                              color: accent,
                              backgroundColor: AppColors.bgGlass,
                              strokeWidth: 2.5,
                              onRefresh: () => _refresh(app, forceRescan: true),
                              child: _buildSongList(
                                context,
                                app,
                                displaySongs,
                                accent,
                              ),
                            ),
                    ),

                    if (displaySongs.isNotEmpty &&
                        _searchQuery.isEmpty &&
                        !_isSelectionMode)
                      Positioned(
                        left: 4,
                        top: 10,
                        bottom: 10,
                        child: _buildAlphabetScrollbar(accent, displaySongs),
                      ),

                    if (_isDraggingAlpha && !_isSelectionMode)
                      Center(
                        child: IgnorePointer(
                          child: AnimatedOpacity(
                            opacity: _isDraggingAlpha ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 150),
                            child: AnimatedScale(
                              scale: _isDraggingAlpha ? 1.0 : 0.5,
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeOutBack,
                              child: Container(
                                width: 86,
                                height: 86,
                                decoration: BoxDecoration(
                                  color: AppColors.bgGlass.withValues(alpha: 0.95),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: accent.withValues(alpha: 0.5),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: accent.withValues(alpha: 0.2),
                                      blurRadius: 24,
                                      spreadRadius: 8,
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  _currentAlpha,
                                  style: TextStyle(
                                    color: accent,
                                    fontSize: 40,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSelectionHeader(
    BuildContext context,
    AppState app,
    List<Song> displaySongs,
    Color accent,
  ) {
    final allSelected = _selectedIds.length == displaySongs.length;

    return Container(
      key: const ValueKey('selection_header'),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.bgGlass,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.close_rounded, color: AppColors.textPrimary),
            onPressed: () => setState(() => _selectedIds.clear()),
          ),
          const SizedBox(width: 8),
          Text(
            '${_selectedIds.length} Selected',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => _selectAll(displaySongs),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: allSelected ? accent : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: allSelected ? accent : AppColors.textMuted,
                  width: 2,
                ),
              ),
              child: allSelected
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          _buildBulkMenu(app, displaySongs, accent),
        ],
      ),
    );
  }

  Widget _buildBulkMenu(AppState app, List<Song> displaySongs, Color accent) {
    return ThemedMenu(
      onSelected: (val) {
        final selectedSongs =
            displaySongs.where((s) => _selectedIds.contains(s.id)).toList();
        if (val == 'fav') _addToFavourites(selectedSongs, app, accent);
        if (val == 'playlist') _addToPlaylist(selectedSongs, app, accent);
      },
      items: const [
        PopupMenuItem(
          value: 'fav',
          child: ThemedMenuItem(
            icon: Icons.favorite_border_rounded,
            label: 'Add to Favourite',
          ),
        ),
        PopupMenuItem(
          value: 'playlist',
          child: ThemedMenuItem(
            icon: Icons.playlist_add_rounded,
            label: 'Add to Playlist',
          ),
        ),
      ],
    );
  }

  Widget _buildNormalHeader(
    BuildContext context,
    AppState app,
    List<Song> songs,
    Color accent,
  ) {
    return Container(
      key: const ValueKey('normal_header'),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SONGS',
            style: TextStyle(
              color: accent.withValues(alpha: 0.8),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.bgGlass,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
              cursorColor: accent,
              decoration: InputDecoration(
                hintText: 'Search titles or artists...',
                hintStyle: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: accent.withValues(alpha: 0.6),
                  size: 20,
                ),
                suffixIcon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            color: AppColors.textMuted,
                            size: 18,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : const SizedBox.shrink(),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _searchQuery.isEmpty ? 'Your Tracks' : 'Search Results',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${songs.length} songs',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _SortToggle(
                current: _sort,
                accentColor: accent,
                onChanged: (s) => setState(() => _sort = s),
              ),
              const SizedBox(width: 8),
              IconCircleButton(
                size: 36,
                onTap: songs.isEmpty
                    ? null
                    : () {
                        HapticFeedback.mediumImpact();
                        app.playSongsShuffled(songs);
                      },
                child: Icon(
                  Icons.shuffle_rounded,
                  color: songs.isEmpty ? AppColors.textMuted : accent,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              IconCircleButton(
                size: 36,
                onTap: _loading ? null : () => _refresh(app, forceRescan: true),
                child: _loading
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: accent,
                        ),
                      )
                    : Icon(
                        Icons.refresh_rounded,
                        color: AppColors.textSecondary,
                        size: 18,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlphabetScrollbar(Color accent, List<Song> displaySongs) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragDown: (details) => _handleAlphaDrag(
            details.localPosition.dy,
            constraints.maxHeight,
            displaySongs,
          ),
          onVerticalDragUpdate: (details) => _handleAlphaDrag(
            details.localPosition.dy,
            constraints.maxHeight,
            displaySongs,
          ),
          onVerticalDragEnd: (_) => setState(() => _isDraggingAlpha = false),
          onVerticalDragCancel: () => setState(() => _isDraggingAlpha = false),
          child: SizedBox(
            width: 32,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: _alphabet.map((l) {
                final isSelected = _isDraggingAlpha && _currentAlpha == l;
                return AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 150),
                  style: TextStyle(
                    color: isSelected
                        ? accent
                        : AppColors.textMuted.withValues(alpha: 0.5),
                    fontSize: isSelected ? 15 : 10,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                  ),
                  child: Text(l),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSongList(
    BuildContext context,
    AppState app,
    List<Song> songs,
    Color accent,
  ) {
    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: EdgeInsets.fromLTRB(_isSelectionMode ? 12 : 48, 8, 8, 140),
      itemCount: songs.length,
      itemExtent: 65.0,
      itemBuilder: (context, index) {
        final song = songs[index];
        final isSelected = _selectedIds.contains(song.id);

        return _SongRow(
          song: song,
          index: index,
          accentColor: accent,
          isSelectionMode: _isSelectionMode,
          isSelected: isSelected,
          onTap: () async {
            if (_isSelectionMode) {
              _toggleSelection(song.id);
            } else {
              await app.player.setQueue(songs, startIndex: index);
              await app.player.play();
            }
          },
          onLongPress: () {
            if (!_isSelectionMode) _toggleSelection(song.id);
          },
          onActionSelected: (val) {
            if (val == 'fav') _addToFavourites([song], app, accent);
            if (val == 'playlist') _addToPlaylist([song], app, accent);
            if (val == 'details') _showDetails(song, accent);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, AppState app, Color accent) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Center(
          child: Column(
            children: [
              Icon(
                _searchQuery.isEmpty
                    ? Icons.library_music_rounded
                    : Icons.search_off_rounded,
                size: 64,
                color: AppColors.textMuted.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                _searchQuery.isEmpty
                    ? 'No songs found'
                    : 'No results for "$_searchQuery"',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.redAccent,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Song Row ─────────────────────────────────────────────────────────────────

class _SongRow extends StatefulWidget {
  final Song song;
  final int index;
  final Color accentColor;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final ValueChanged<String> onActionSelected;

  const _SongRow({
    required this.song,
    required this.index,
    required this.accentColor,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    required this.onActionSelected,
  });

  @override
  State<_SongRow> createState() => _SongRowState();
}

class _SongRowState extends State<_SongRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final accent = widget.accentColor;

    return StreamBuilder<Song?>(
      stream: app.player.currentSongStream,
      initialData: app.player.currentSong,
      builder: (context, snap) {
        final isPlaying =
            snap.data?.id == widget.song.id && !widget.isSelectionMode;
        final highlight = widget.isSelected || isPlaying;

        return GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) {
            setState(() => _pressed = false);
            widget.onTap();
          },
          onTapCancel: () => setState(() => _pressed = false),
          onLongPress: () {
            setState(() => _pressed = false);
            widget.onLongPress();
          },
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutQuart,
            margin: const EdgeInsets.symmetric(vertical: 5),
            transform: Matrix4.diagonal3Values(
              _pressed ? 0.97 : 1.0,
              _pressed ? 0.97 : 1.0,
              1.0,
            ),
            transformAlignment: Alignment.center,
            padding: const EdgeInsets.only(left: 7, right: 4, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: highlight
                  ? accent.withValues(alpha: 0.10)
                  : (_pressed
                      ? AppColors.bgGlass.withValues(alpha: 0.6)
                      : Colors.transparent),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: highlight
                    ? accent.withValues(alpha: 0.35)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutQuart,
                  child: widget.isSelectionMode
                      ? Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: widget.isSelected
                                  ? accent
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: widget.isSelected
                                    ? accent
                                    : AppColors.textMuted,
                                width: 2,
                              ),
                            ),
                            child: widget.isSelected
                                ? const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  )
                                : null,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.song.title,
                        style: TextStyle(
                          color: highlight
                              ? (widget.isSelected ? Colors.white : accent)
                              : AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight:
                              highlight ? FontWeight.w800 : FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.song.artist.isEmpty
                            ? 'Unknown Artist'
                            : widget.song.artist,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (!widget.isSelectionMode) ...[
                  const SizedBox(width: 8),
                  ThemedMenu(
                    onSelected: widget.onActionSelected,
                    items: const [
                      PopupMenuItem(
                        value: 'fav',
                        child: ThemedMenuItem(
                          icon: Icons.favorite_border_rounded,
                          label: 'Add to Favourite',
                        ),
                      ),
                      PopupMenuItem(
                        value: 'playlist',
                        child: ThemedMenuItem(
                          icon: Icons.playlist_add_rounded,
                          label: 'Add to Playlist',
                        ),
                      ),
                      PopupMenuItem(
                        value: 'details',
                        child: ThemedMenuItem(
                          icon: Icons.info_outline_rounded,
                          label: 'Details',
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Miscellaneous UI ─────────────────────────────────────────────────────────

class _SortToggle extends StatelessWidget {
  final SongSort current;
  final Color accentColor;
  final ValueChanged<SongSort> onChanged;

  const _SortToggle({
    required this.current,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: AppColors.bgGlass,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggle('A–Z', SongSort.az),
          Container(width: 1, height: 18, color: AppColors.divider),
          _toggle('Z–A', SongSort.za),
        ],
      ),
    );
  }

  Widget _toggle(String label, SongSort value) {
    final active = current == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onChanged(value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        height: 34,
        decoration: BoxDecoration(
          color: active
              ? accentColor.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: active ? accentColor : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: active ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}