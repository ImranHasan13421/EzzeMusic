import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Required for compute()
import 'package:collection/collection.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/songs_repository.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import 'player_controller.dart';

class AppState extends ChangeNotifier {
  static const _kThemeModeKey = 'themeMode';
  static const _kPlaylistsKey = 'playlists';
  static const _kLastQueueKey = 'lastQueue.v1';
  static const _kLastIndexKey = 'lastIndex.v1';
  static const _kAccentColorKey = 'accentColor';
  static const _kHideShortClipsKey = 'hideShortClips';
  static const _kFavouritesPlaylistId = 'pl_favourites';
  static const _kFavouritesPlaylistName = 'Favourite';
  static const _kRecentSearchesKey = 'recent_searches.v1';

  late final SharedPreferences _prefs;
  late final PlayerController player;
  late final SongsRepository songsRepository;

  StreamSubscription<List<Song>>? _queueSub;
  StreamSubscription<int?>? _indexSub;

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  Color _accentColor = const Color(0xFF4044FA);
  Color get accentColor => _accentColor;

  bool _hideShortClips = false;
  bool get hideShortClips => _hideShortClips;

  // ── High Performance Caching ──────────────────────────────────
  List<Song> _allSongsMaster = []; // Memory cache of full library
  List<Song> _songsCache = const [];
  List<Song> get songsCache => _songsCache;

  List<String> _recentSearches = [];
  List<String> get recentSearches => List.unmodifiable(_recentSearches);

  final List<Playlist> _playlists = [];
  List<Playlist> get playlists => List.unmodifiable(_playlists);

  Playlist? get favouritesPlaylist =>
      _playlists.where((p) => p.id == _kFavouritesPlaylistId).firstOrNull;

  List<Song> get likedSongs {
    final fav = favouritesPlaylist;
    if (fav == null || fav.songIds.isEmpty) return const [];
    final set = fav.songIds.toSet();
    return _songsCache.where((s) => set.contains(s.id)).toList();
  }

  List<String> get artists {
    final set = <String>{};
    for (final s in _songsCache) {
      final a = s.artist.trim();
      if (a.isNotEmpty && a.toLowerCase() != '<unknown>') {
        set.add(a);
      }
    }
    final list = set.toList();
    list.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  List<Song> songsForArtist(String artist) {
    return _songsCache
        .where((s) => s.artist.trim().toLowerCase() == artist.trim().toLowerCase())
        .toList();
  }

  Map<String, List<Song>> get albums {
    final map = <String, List<Song>>{};
    for (final s in _songsCache) {
      final a = s.album.trim();
      final key = a.isEmpty ? 'Unknown Album' : a;
      (map[key] ??= []).add(s);
    }
    return map;
  }

  Timer? _sleepTimer;
  DateTime? _sleepEndsAt;
  DateTime? get sleepEndsAt => _sleepEndsAt;

  Duration? get sleepRemaining {
    final endsAt = _sleepEndsAt;
    if (endsAt == null) return null;
    final d = endsAt.difference(DateTime.now());
    if (d.isNegative) return Duration.zero;
    return d;
  }

  // ── Initialization ───────────────────────────────────────────

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadTheme();
    await _loadPlaylists(); // 🟢 NUCLEAR FIX: Awaited to prevent async race conditions
    _loadAccentColor();
    _loadLibraryFilters();
    _loadRecentSearches();

    player = PlayerController();
    await player.init();

    songsRepository = SongsRepository();
    await songsRepository.init();

    _queueSub?.cancel();
    _queueSub = player.queueStream.listen((_) => _saveLastPlayed());
    _indexSub?.cancel();
    _indexSub = player.currentIndexStream.listen((_) => _saveLastPlayed());

    await _restoreLastPlayed();

    // Initial load: Full scan on app start
    await refreshLibrarySongs(forceRescan: true);
  }

  // ── Optimized Library Logic ──────────────────────────────────

  Future<void> refreshLibrarySongs({bool forceRescan = false}) async {
    // Fetch from storage only if needed
    if (_allSongsMaster.isEmpty || forceRescan) {
      _allSongsMaster = await songsRepository.getLibrarySongsAscending();
    }

    if (_hideShortClips) {
      // Background filtering to keep UI smooth
      _songsCache = await compute(_filterMusicLogic, _allSongsMaster);
    } else {
      // Just copy the whole list to the cache
      _songsCache = List.from(_allSongsMaster);
    }

    notifyListeners();
  }

  static List<Song> _filterMusicLogic(List<Song> songs) {
    const validExtensions = {'.mp3', '.m4a', '.aac', '.wav', '.flac', '.ogg', '.wma', '.opus'};
    return songs.where((s) {
      final duration = s.duration ?? Duration.zero;
      if (duration.inSeconds < 30) return false;

      final path = s.uri.toLowerCase();
      return validExtensions.any((ext) => path.endsWith(ext));
    }).toList();
  }

  Future<void> toggleHideShortClips(bool value) async {
    _hideShortClips = value;
    await _prefs.setBool(_kHideShortClipsKey, value);
    // Refresh using RAM cache (instant)
    await refreshLibrarySongs(forceRescan: false);
  }

  Future<void> importSongs() async {
    final imported = await songsRepository.importSongsFromFilesPicker();
    _allSongsMaster = imported; // Keep master cache in sync
    _songsCache = List.from(imported);
    notifyListeners();
  }

  // ── Playlists ────────────────────────────────────────────────

  Future<void> createPlaylist(String name) async {
    _playlists.add(Playlist.newPlaylist(name: name));
    await _savePlaylists();
    notifyListeners();
  }

  Future<void> renamePlaylist(String playlistId, String newName) async {
    final idx = _playlists.indexWhere((p) => p.id == playlistId);
    if (idx == -1) return;
    _playlists[idx] = _playlists[idx].copyWith(name: newName);
    await _savePlaylists();
    notifyListeners();
  }

  Future<void> deletePlaylist(String playlistId) async {
    _playlists.removeWhere((p) => p.id == playlistId);
    await _savePlaylists();
    notifyListeners();
  }

  // ── Favourites ───────────────────────────────────────────────

  Future<void> addCurrentSongToFavourites() async {
    final song = player.currentSong;
    if (song == null) return;
    final fav = await _ensureFavouritesPlaylist();
    await addSongToPlaylist(playlistId: fav.id, songId: song.id);
  }

  Future<void> removeSongFromFavourites(int songId) async {
    final fav = favouritesPlaylist;
    if (fav == null) return;
    await removeSongFromPlaylist(playlistId: fav.id, songId: songId);
  }

  bool isSongFavourited(int songId) {
    final fav = favouritesPlaylist;
    return fav != null && fav.songIds.contains(songId);
  }

  Future<void> addSongsToFavourites(List<int> songIds) async {
    final fav = await _ensureFavouritesPlaylist();
    for (var id in songIds) {
      final idx = _playlists.indexWhere((p) => p.id == fav.id);
      if (idx != -1) {
        _playlists[idx] = _playlists[idx].addSong(id);
      }
    }
    await _savePlaylists();
    notifyListeners();
  }

  // ── Playlist Internals ───────────────────────────────────────

  Future<Playlist> _ensureFavouritesPlaylist() async {
    final existing = favouritesPlaylist;
    if (existing != null) return existing;
    final created = Playlist(
      id: _kFavouritesPlaylistId,
      name: _kFavouritesPlaylistName,
      songIds: const [],
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    _playlists.add(created);
    await _savePlaylists();
    notifyListeners();
    return created;
  }

  Future<void> addSongToPlaylist({required String playlistId, required int songId}) async {
    final idx = _playlists.indexWhere((p) => p.id == playlistId);
    if (idx == -1) return;
    _playlists[idx] = _playlists[idx].addSong(songId);
    await _savePlaylists();
    notifyListeners();
  }

  Future<void> removeSongFromPlaylist({required String playlistId, required int songId}) async {
    final idx = _playlists.indexWhere((p) => p.id == playlistId);
    if (idx == -1) return;
    _playlists[idx] = _playlists[idx].removeSong(songId);
    await _savePlaylists();
    notifyListeners();
  }

  // ── Personalization ──────────────────────────────────────────

  void _loadAccentColor() {
    final val = _prefs.getInt(_kAccentColorKey);
    if (val != null) _accentColor = Color(val);
  }

  Future<void> updateAccentColor(Color color) async {
    _accentColor = color;
    await _prefs.setInt(_kAccentColorKey, color.toARGB32());
    notifyListeners();
  }

  void _loadTheme() {
    final v = _prefs.getString(_kThemeModeKey);
    _themeMode = v == 'light' ? ThemeMode.light : v == 'dark' ? ThemeMode.dark : ThemeMode.system;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs.setString(_kThemeModeKey, mode.name);
    notifyListeners();
  }

  void _loadLibraryFilters() {
    _hideShortClips = _prefs.getBool(_kHideShortClipsKey) ?? false;
  }

  void _loadRecentSearches() {
    _recentSearches = _prefs.getStringList(_kRecentSearchesKey) ?? [];
  }

  Future<void> addSearchQuery(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    _recentSearches.removeWhere((item) => item.toLowerCase() == q.toLowerCase());
    _recentSearches.insert(0, q);
    if (_recentSearches.length > 15) {
      _recentSearches = _recentSearches.sublist(0, 15);
    }
    await _prefs.setStringList(_kRecentSearchesKey, _recentSearches);
    notifyListeners();
  }

  Future<void> clearRecentSearches() async {
    _recentSearches.clear();
    await _prefs.remove(_kRecentSearchesKey);
    notifyListeners();
  }

  Future<void> playSong(Song song, {List<Song>? contextQueue}) async {
    final list = (contextQueue != null && contextQueue.isNotEmpty)
        ? contextQueue
        : _songsCache;
    final idx = list.indexWhere((s) => s.id == song.id);
    if (idx != -1) {
      await player.setQueue(list, startIndex: idx, playWhenReady: true);
    } else {
      await player.setQueue([song, ...list.where((s) => s.id != song.id)],
          startIndex: 0, playWhenReady: true);
    }
  }

  Future<void> playSongsShuffled(List<Song> songs) async {
    if (songs.isEmpty) return;
    final shuffled = List<Song>.from(songs)..shuffle();
    await player.setQueue(shuffled, startIndex: 0, playWhenReady: true);
    await player.setShuffleEnabled(true);
  }

  Future<void> setSleepTimer(Duration? duration) async {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepEndsAt = null;
    if (duration != null) {
      _sleepEndsAt = DateTime.now().add(duration);
      _sleepTimer = Timer(duration, () async {
        await player.pause();
        _sleepEndsAt = null;
        notifyListeners();
      });
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _queueSub?.cancel();
    _indexSub?.cancel();
    player.dispose();
    super.dispose();
  }

  // ── Core Persistence (NUCLEAR FIX) ───────────────────────────

  Future<void> _saveLastPlayed() async {
    final q = player.queue;
    if (q.isEmpty) return;

    // NUCLEAR FIX: JSON Encoding sent to a background core
    final jsonString = await compute(_encodeQueueWorker, q);
    await _prefs.setString(_kLastQueueKey, jsonString);
    await _prefs.setInt(_kLastIndexKey, player.currentIndex ?? 0);
  }

  Future<void> _restoreLastPlayed() async {
    final raw = _prefs.getString(_kLastQueueKey);
    if (raw == null) return;
    try {
      // NUCLEAR FIX: JSON Decoding sent to a background core
      final list = await compute(_decodeQueueWorker, raw);
      final idx = _prefs.getInt(_kLastIndexKey) ?? 0;
      await player.setQueue(list, startIndex: idx.clamp(0, list.length - 1));
    } catch (_) {}
  }

  Future<void> _loadPlaylists() async {
    final raw = _prefs.getString(_kPlaylistsKey);
    if (raw != null) {
      // NUCLEAR FIX: Decodes massive playlists without stuttering the UI
      final decoded = await compute(_decodePlaylistsWorker, raw);
      _playlists..clear()..addAll(decoded);
    }
  }

  Future<void> _savePlaylists() async {
    // NUCLEAR FIX: Encodes massive playlists without stuttering the UI
    final jsonString = await compute(_encodePlaylistsWorker, _playlists);
    await _prefs.setString(_kPlaylistsKey, jsonString);
  }

  // ── BACKGROUND WORKERS FOR HEAVY PARSING ─────────────────────
  // These must be static so Flutter can safely run them in an Isolate

  static String _encodeQueueWorker(List<Song> queue) {
    return jsonEncode(queue.map((e) => e.toJson()).toList());
  }

  static List<Song> _decodeQueueWorker(String rawJson) {
    return (jsonDecode(rawJson) as List).cast<Map<String, dynamic>>().map(Song.fromJson).toList();
  }

  static String _encodePlaylistsWorker(List<Playlist> playlists) {
    return jsonEncode(playlists.map((e) => e.toJson()).toList());
  }

  static List<Playlist> _decodePlaylistsWorker(String rawJson) {
    return (jsonDecode(rawJson) as List).cast<Map<String, dynamic>>().map(Playlist.fromJson).toList();
  }
}