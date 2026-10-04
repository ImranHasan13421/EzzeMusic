import 'package:flutter_test/flutter_test.dart';
import 'package:ezze_music/models/song.dart';

void main() {
  group('Music Library Grouping Logic Tests', () {
    final testSongs = [
      const Song(
        id: 1,
        title: 'Midnight City',
        artist: 'M83',
        album: 'Hurry Up, We\'re Dreaming',
        uri: 'file:///storage/emulated/0/Music/midnight.mp3',
        duration: Duration(minutes: 4, seconds: 3),
      ),
      const Song(
        id: 2,
        title: 'Wait',
        artist: 'M83',
        album: 'Hurry Up, We\'re Dreaming',
        uri: 'file:///storage/emulated/0/Music/wait.mp3',
        duration: Duration(minutes: 5, seconds: 43),
      ),
      const Song(
        id: 3,
        title: 'Instant Crush',
        artist: 'Daft Punk',
        album: 'Random Access Memories',
        uri: 'file:///storage/emulated/0/Music/crush.mp3',
        duration: Duration(minutes: 5, seconds: 37),
      ),
      const Song(
        id: 4,
        title: 'Get Lucky',
        artist: 'Daft Punk',
        album: 'Random Access Memories',
        uri: 'file:///storage/emulated/0/Music/lucky.mp3',
        duration: Duration(minutes: 4, seconds: 8),
      ),
    ];

    test('Artists extraction groups unique artists case-insensitively sorted', () {
      final set = <String>{};
      for (final s in testSongs) {
        final a = s.artist.trim();
        if (a.isNotEmpty) set.add(a);
      }
      final artists = set.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

      expect(artists, equals(['Daft Punk', 'M83']));
    });

    test('Albums extraction groups songs by album correctly', () {
      final albums = <String, List<Song>>{};
      for (final s in testSongs) {
        final a = s.album.trim();
        final key = a.isEmpty ? 'Unknown Album' : a;
        (albums[key] ??= []).add(s);
      }

      expect(albums.keys.length, equals(2));
      expect(albums['Hurry Up, We\'re Dreaming']!.length, equals(2));
      expect(albums['Random Access Memories']!.length, equals(2));
      expect(albums['Random Access Memories']!.first.title, equals('Instant Crush'));
    });

    test('Search filtering matches on title, artist, or album', () {
      const query = 'daft';
      final filtered = testSongs.where((s) {
        final q = query.toLowerCase();
        return s.title.toLowerCase().contains(q) ||
            s.artist.toLowerCase().contains(q) ||
            s.album.toLowerCase().contains(q);
      }).toList();

      expect(filtered.length, equals(2));
      expect(filtered.every((s) => s.artist == 'Daft Punk'), isTrue);
    });

    test('Search history de-duplicates and prepends latest query', () {
      final history = <String>['Rock', 'Pop'];
      const newQuery = 'pop';

      history.removeWhere((item) => item.toLowerCase() == newQuery.toLowerCase());
      history.insert(0, newQuery);

      expect(history.first, equals('pop'));
      expect(history.length, equals(2));
      expect(history, equals(['pop', 'Rock']));
    });
  });
}
