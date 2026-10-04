import 'package:ezze_music/models/song.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Song Model Tests', () {
    test('Song serialization to and from JSON produces identical object', () {
      final song = Song(
        id: 101,
        title: 'Midnight Echoes',
        artist: 'Antigravity Sound',
        album: 'Neon Horizon',
        albumId: 55,
        artistId: 22,
        genre: 'Synthwave',
        track: 1,
        uri: 'file:///storage/emulated/0/Music/midnight_echoes.mp3',
        duration: const Duration(minutes: 3, seconds: 45),
        artworkUri: Uri.parse('content://media/external/audio/albumart/55'),
      );

      final json = song.toJson();
      final fromJson = Song.fromJson(json);

      expect(fromJson.id, equals(song.id));
      expect(fromJson.title, equals(song.title));
      expect(fromJson.artist, equals(song.artist));
      expect(fromJson.album, equals(song.album));
      expect(fromJson.albumId, equals(song.albumId));
      expect(fromJson.artistId, equals(song.artistId));
      expect(fromJson.genre, equals(song.genre));
      expect(fromJson.track, equals(song.track));
      expect(fromJson.uri, equals(song.uri));
      expect(fromJson.duration, equals(song.duration));
      expect(fromJson.artworkUri, equals(song.artworkUri));
    });

    test('Song deserialization handles nullable/missing fields gracefully', () {
      final json = {
        'id': 202,
        'title': 'Minimal Track',
        'artist': 'Solo Artist',
        'uri': 'file:///music/track.flac',
      };

      final song = Song.fromJson(json);
      expect(song.id, equals(202));
      expect(song.title, equals('Minimal Track'));
      expect(song.artist, equals('Solo Artist'));
      expect(song.album, isEmpty);
      expect(song.duration, isNull);
      expect(song.artworkUri, isNull);
    });

    test('Song equality matches on id and uri', () {
      final songA = Song(
        id: 1,
        title: 'Track A',
        artist: 'Artist',
        uri: 'file:///a.mp3',
        duration: null,
      );
      final songB = Song(
        id: 1,
        title: 'Track A (Remastered)',
        artist: 'Artist',
        uri: 'file:///a.mp3',
        duration: null,
      );

      expect(songA, equals(songB));
      expect(songA.hashCode, equals(songB.hashCode));
    });
  });
}
