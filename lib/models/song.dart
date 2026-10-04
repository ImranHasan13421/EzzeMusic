class Song {
  final int id;
  final String title;
  final String artist;
  final String album;
  final int? albumId;
  final int? artistId;
  final String? genre;
  final int? track;
  final String uri;
  final Duration? duration;
  final Uri? artworkUri;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    this.album = '',
    this.albumId,
    this.artistId,
    this.genre,
    this.track,
    required this.uri,
    required this.duration,
    this.artworkUri,
  });

  Song copyWith({
    int? id,
    String? title,
    String? artist,
    String? album,
    int? albumId,
    int? artistId,
    String? genre,
    int? track,
    String? uri,
    Duration? duration,
    Uri? artworkUri,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      albumId: albumId ?? this.albumId,
      artistId: artistId ?? this.artistId,
      genre: genre ?? this.genre,
      track: track ?? this.track,
      uri: uri ?? this.uri,
      duration: duration ?? this.duration,
      artworkUri: artworkUri ?? this.artworkUri,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'albumId': albumId,
      'artistId': artistId,
      'genre': genre,
      'track': track,
      'uri': uri,
      'durationMs': duration?.inMilliseconds,
      'artworkUri': artworkUri?.toString(),
    };
  }

  factory Song.fromJson(Map<String, dynamic> json) {
    final durationMs = json['durationMs'] as int?;
    final artwork = json['artworkUri'] as String?;
    return Song(
      id: (json['id'] as num).toInt(),
      title: (json['title'] as String?) ?? '',
      artist: (json['artist'] as String?) ?? '',
      album: (json['album'] as String?) ?? '',
      albumId: (json['albumId'] as num?)?.toInt(),
      artistId: (json['artistId'] as num?)?.toInt(),
      genre: json['genre'] as String?,
      track: (json['track'] as num?)?.toInt(),
      uri: (json['uri'] as String?) ?? '',
      duration: durationMs == null ? null : Duration(milliseconds: durationMs),
      artworkUri: artwork == null ? null : Uri.tryParse(artwork),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Song &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          uri == other.uri;

  @override
  int get hashCode => id.hashCode ^ uri.hashCode;
}

