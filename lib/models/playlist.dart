import 'package:collection/collection.dart';

class Playlist {
  final String id;
  final String name;
  final List<int> songIds;
  final int createdAtMs;

  const Playlist({
    required this.id,
    required this.name,
    required this.songIds,
    required this.createdAtMs,
  });

  factory Playlist.newPlaylist({required String name}) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return Playlist(
      id: 'pl_$now',
      name: name.trim().isEmpty ? 'New Playlist' : name.trim(),
      songIds: const [],
      createdAtMs: now,
    );
  }

  Playlist copyWith({
    String? name,
    List<int>? songIds,
  }) {
    return Playlist(
      id: id,
      name: name ?? this.name,
      songIds: songIds ?? this.songIds,
      createdAtMs: createdAtMs,
    );
  }

  Playlist addSong(int songId) {
    if (songIds.contains(songId)) return this;
    return copyWith(songIds: [...songIds, songId]);
  }

  Playlist removeSong(int songId) {
    return copyWith(songIds: songIds.whereNot((id) => id == songId).toList());
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'songIds': songIds,
        'createdAtMs': createdAtMs,
      };

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      songIds: (json['songIds'] as List<dynamic>? ?? const [])
          .map((e) => e as int)
          .toList(),
      createdAtMs: (json['createdAtMs'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Playlist &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          const ListEquality().equals(songIds, other.songIds) &&
          createdAtMs == other.createdAtMs;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      const ListEquality().hash(songIds) ^
      createdAtMs.hashCode;
}

