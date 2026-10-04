import 'package:ezze_music/models/playlist.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Playlist Model Tests', () {
    test('Playlist creation and immutable operations work as expected', () {
      final initial = Playlist.newPlaylist(name: 'Chill Vibes');

      expect(initial.name, equals('Chill Vibes'));
      expect(initial.songIds, isEmpty);
      expect(initial.id, isNotEmpty);

      // Add songs immutably
      final withSong1 = initial.addSong(101);
      expect(withSong1.songIds, equals([101]));
      expect(initial.songIds, isEmpty); // Original remains untouched

      // Adding the same song again does not duplicate
      final withDuplicate = withSong1.addSong(101);
      expect(withDuplicate.songIds.length, equals(1));

      // Add a second song
      final withSong2 = withSong1.addSong(102);
      expect(withSong2.songIds, equals([101, 102]));

      // Remove a song immutably
      final removed = withSong2.removeSong(101);
      expect(removed.songIds, equals([102]));
      expect(withSong2.songIds, equals([101, 102]));
    });

    test('Playlist serialization and deserialization retains data', () {
      final playlist = Playlist(
        id: 'pl_favorites_custom',
        name: 'Late Night Coding',
        songIds: [1, 5, 9, 13],
        createdAtMs: 1728000000000,
      );

      final json = playlist.toJson();
      final fromJson = Playlist.fromJson(json);

      expect(fromJson.id, equals(playlist.id));
      expect(fromJson.name, equals(playlist.name));
      expect(fromJson.songIds, equals(playlist.songIds));
      expect(fromJson.createdAtMs, equals(playlist.createdAtMs));
      expect(fromJson, equals(playlist));
    });

    test('Playlist copyWith modifies only specified attributes', () {
      final original = Playlist(
        id: 'pl_orig',
        name: 'Original',
        songIds: [1, 2],
        createdAtMs: 123456789,
      );

      final updated = original.copyWith(name: 'Renamed Playlist');

      expect(updated.id, equals('pl_orig'));
      expect(updated.name, equals('Renamed Playlist'));
      expect(updated.songIds, equals([1, 2]));
      expect(updated.createdAtMs, equals(123456789));
    });
  });
}
