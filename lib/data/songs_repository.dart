import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';

class SongsRepository {
  final OnAudioQuery _query = OnAudioQuery();
  static const _kImportedSongsKey = 'importedSongs.v1';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<bool> ensurePermission() async {
    if (!Platform.isAndroid) return false;

    final statusAudio = await Permission.audio.status;
    if (statusAudio.isGranted) return true;

    final result = await Permission.audio.request();
    if (result.isGranted) return true;

    final storage = await Permission.storage.request();
    return storage.isGranted;
  }

  Future<List<Song>> getLibrarySongsAscending() async {
    if (Platform.isAndroid) {
      return getDeviceSongsAscending();
    }
    // iOS, desktop, and web all use the imported songs path
    return getImportedSongsAscending();
  }

  Future<List<Song>> getDeviceSongsAscending() async {
    if (!Platform.isAndroid) return const [];

    final can = await ensurePermission();
    if (!can) return const [];

    final songs = await _query.querySongs(
      sortType: SongSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );

    return songs
        .where((s) => s.data.isNotEmpty) // USE ACTUAL FILE PATH
        .map(
          (s) => Song(
        id: s.id,
        title: (s.title).trim(),
        artist: (s.artist ?? 'Unknown artist').trim(),
        album: (s.album ?? '').trim(),
        albumId: s.albumId,
        artistId: s.artistId,
        genre: (s.genre ?? '').trim().isEmpty ? null : (s.genre ?? '').trim(),
        track: s.track,
        // Convert the absolute path into a safe file:// URI for deletion
        uri: Uri.file(s.data).toString(),
        duration: s.duration == null ? null : Duration(milliseconds: s.duration!),
        artworkUri: s.albumId == null ? null : androidAlbumArtUri(s.albumId!),
      ),
    )
        .toList();
  }

  Uri androidAlbumArtUri(int albumId) {
    return Uri.parse('content://media/external/audio/albumart/$albumId');
  }

  Future<List<Song>> getImportedSongsAscending() async {
    await init();
    final raw = _prefs!.getString(_kImportedSongsKey);
    if (raw == null) return const [];
    final list = (jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>();
    final songs = list.map(Song.fromJson).toList();
    songs.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return songs;
  }

  Future<List<Song>> importSongsFromFilesPicker() async {
    // File picker import is available on all platforms except Android (which uses MediaStore)
    if (Platform.isAndroid) return await getDeviceSongsAscending();
    await init();

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: true,
      allowedExtensions: const ['mp3', 'm4a', 'aac', 'wav', 'flac', 'ogg'],
      withData: false,
    );
    if (result == null) return await getImportedSongsAscending();

    final existing = await getImportedSongsAscending();
    final byUri = <String, Song>{for (final s in existing) s.uri: s};

    for (final file in result.files) {
      final path = file.path;
      if (path == null || path.isEmpty) continue;
      final uri = Uri.file(path).toString();
      final title = (file.name).replaceAll(RegExp(r'\.[^.]+$'), '').trim();
      byUri[uri] = Song(
        id: uri.hashCode,
        title: title.isEmpty ? file.name : title,
        artist: 'Imported',
        album: '',
        uri: uri,
        duration: null,
        artworkUri: null,
      );
    }

    final updated = byUri.values.toList()
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

    await _prefs!.setString(
      _kImportedSongsKey,
      jsonEncode(updated.map((e) => e.toJson()).toList()),
    );

    return updated;
  }
}