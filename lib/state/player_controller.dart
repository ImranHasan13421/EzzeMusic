// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../models/song.dart';

enum PlaybackRepeatMode { off, one, all }

class PlayerController {
  final AudioPlayer _player = AudioPlayer();
  final List<Song> _queue = <Song>[];
  ConcatenatingAudioSource _playlist = ConcatenatingAudioSource(children: []);

  final StreamController<List<Song>> _queueController =
  StreamController<List<Song>>.broadcast();
  final StreamController<Song?> _currentSongController =
  StreamController<Song?>.broadcast();
  final StreamController<PlaybackRepeatMode> _repeatModeController =
  StreamController<PlaybackRepeatMode>.broadcast();
  final StreamController<bool> _shuffleController =
  StreamController<bool>.broadcast();

  StreamSubscription<SequenceState?>? _sequenceSub;
  StreamSubscription<LoopMode>? _loopModeSub;
  StreamSubscription<bool>? _shuffleSub;

  List<Song> get queue => List.unmodifiable(_queue);
  int? get currentIndex => _player.currentIndex;
  bool get playing => _player.playing;

  Stream<List<Song>> get queueStream => _queueController.stream;
  Stream<Song?> get currentSongStream => _currentSongController.stream;

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration> get bufferedPositionStream =>
      _player.bufferedPositionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<ProcessingState> get processingStateStream =>
      _player.processingStateStream;
  Stream<int?> get currentIndexStream => _player.currentIndexStream;
  Stream<double> get speedStream => _player.speedStream;
  double get speed => _player.speed;
  Stream<PlaybackRepeatMode> get repeatModeStream =>
      _repeatModeController.stream;
  Stream<bool> get shuffleEnabledStream => _shuffleController.stream;

  PlaybackRepeatMode _repeatMode = PlaybackRepeatMode.off;
  PlaybackRepeatMode get repeatMode => _repeatMode;

  bool _shuffleEnabled = false;
  bool get shuffleEnabled => _shuffleEnabled;

  Song? get currentSong {
    final idx = currentIndex;
    if (idx == null || idx < 0 || idx >= _queue.length) return null;
    return _queue[idx];
  }

  Future<void> init() async {
    _queueController.add(queue);
    _currentSongController.add(null);
    _repeatModeController.add(_repeatMode);
    _shuffleController.add(_shuffleEnabled);

    // ── Single reliable source of truth for current song ─────────
    // sequenceStateStream fires AFTER just_audio fully settles on
    // the new track, so the index is always the correct new value.
    _sequenceSub?.cancel();
    _sequenceSub = _player.sequenceStateStream.listen((state) {
      if (_queue.isEmpty) {
        _currentSongController.add(null);
        return;
      }
      final index = state.currentIndex;
      if (index == null || index < 0 || index >= _queue.length) {
        _currentSongController.add(null);
        return;
      }
      _currentSongController.add(_queue[index]);
    });

    _loopModeSub?.cancel();
    _loopModeSub = _player.loopModeStream.listen((mode) {
      final next = switch (mode) {
        LoopMode.off => PlaybackRepeatMode.off,
        LoopMode.one => PlaybackRepeatMode.one,
        LoopMode.all => PlaybackRepeatMode.all,
      };
      _repeatMode = next;
      _repeatModeController.add(next);
    });

    _shuffleSub?.cancel();
    _shuffleSub = _player.shuffleModeEnabledStream.listen((enabled) {
      _shuffleEnabled = enabled;
      _shuffleController.add(enabled);
    });
  }

  Future<void> setQueue(
      List<Song> songs, {
        int startIndex = 0,
        bool playWhenReady = false,
      }) async {
    await stop();

    _queue
      ..clear()
      ..addAll(songs);

    _playlist = ConcatenatingAudioSource(
      children: songs.map(_toAudioSource).toList(),
    );
    _queueController.add(queue);

    final safeStart =
    (startIndex < 0 || startIndex >= songs.length) ? 0 : startIndex;

    await _player.setAudioSource(
      _playlist,
      initialIndex: safeStart,
      initialPosition: Duration.zero,
    );

    if (_shuffleEnabled) {
      await _player.shuffle();
    }

    // Emit immediately so UI shows correct song without waiting
    // for sequenceStateStream to fire
    _currentSongController.add(
      songs.isEmpty ? null : songs[safeStart],
    );

    if (playWhenReady && songs.isNotEmpty) {
      await play();
    }
  }

  Future<void> play() => _player.play();
  Future<void> pause() => _player.pause();
  Future<void> toggle() => playing ? pause() : play();

  Future<void> stop() async {
    await _player.stop();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> skipTo(int index) async {
    if (_queue.isEmpty) return;
    if (index < 0 || index >= _queue.length) return;
    await _player.seek(Duration.zero, index: index);
  }

  Future<void> next() async {
    if (_queue.isEmpty) return;
    if (_player.hasNext) {
      await _player.seekToNext();
      return;
    }
    if (_repeatMode == PlaybackRepeatMode.all) {
      await _player.seek(Duration.zero, index: 0);
    }
  }

  Future<void> previous() async {
    if (_queue.isEmpty) return;
    final pos = _player.position;
    if (pos.inSeconds > 3) {
      await _player.seek(Duration.zero);
      return;
    }
    if (_player.hasPrevious) {
      await _player.seekToPrevious();
      return;
    }
    if (_repeatMode == PlaybackRepeatMode.all && _queue.isNotEmpty) {
      await _player.seek(Duration.zero, index: _queue.length - 1);
    }
  }

  Future<void> setShuffleEnabled(bool enabled) async {
    _shuffleEnabled = enabled;
    await _player.setShuffleModeEnabled(enabled);
    if (enabled) {
      await _player.shuffle();
    }
    _shuffleController.add(enabled);
  }

  Future<void> setRepeatMode(PlaybackRepeatMode mode) async {
    _repeatMode = mode;
    await _player.setLoopMode(
      switch (mode) {
        PlaybackRepeatMode.off => LoopMode.off,
        PlaybackRepeatMode.one => LoopMode.one,
        PlaybackRepeatMode.all => LoopMode.all,
      },
    );
    _repeatModeController.add(mode);
  }

  Future<void> toggleShuffle() async {
    await setShuffleEnabled(!_shuffleEnabled);
  }

  Future<void> toggleRepeat() async {
    await cycleRepeatMode();
  }

  Future<void> cycleRepeatMode() async {
    final next = switch (_repeatMode) {
      PlaybackRepeatMode.off => PlaybackRepeatMode.all,
      PlaybackRepeatMode.all => PlaybackRepeatMode.one,
      PlaybackRepeatMode.one => PlaybackRepeatMode.off,
    };
    await setRepeatMode(next);
  }

  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed.clamp(0.25, 3.0));
  }

  Future<void> clearQueue() async {
    await stop();
    _queue.clear();
    _playlist = ConcatenatingAudioSource(children: []);
    _queueController.add([]);
    _currentSongController.add(null);
  }

  Future<void> addToQueueNext(Song song) async {
    if (_queue.isEmpty) {
      await setQueue([song], startIndex: 0);
      return;
    }
    final idx = currentIndex ?? -1;
    final insertAt =
    (idx < 0) ? _queue.length : (idx + 1).clamp(0, _queue.length);
    _queue.insert(insertAt, song);
    await _playlist.insert(insertAt, _toAudioSource(song));
    _queueController.add(queue);
  }

  Future<void> addToQueueEnd(Song song) async {
    if (_queue.isEmpty) {
      await setQueue([song], startIndex: 0);
      return;
    }
    _queue.add(song);
    await _playlist.add(_toAudioSource(song));
    _queueController.add(queue);
  }

  Future<void> removeFromQueue(int index) async {
    if (_queue.isEmpty) return;
    if (index < 0 || index >= _queue.length) return;

    _queue.removeAt(index);
    await _playlist.removeAt(index);
    _queueController.add(queue);
    if (_queue.isEmpty) await stop();
  }

  Future<void> moveQueueItem(int from, int to) async {
    if (_queue.isEmpty) return;
    if (from < 0 || from >= _queue.length) return;
    if (to < 0 || to >= _queue.length) return;
    if (from == to) return;

    final song = _queue.removeAt(from);
    _queue.insert(to, song);

    await _playlist.move(from, to);
    _queueController.add(queue);
  }

  AudioSource _toAudioSource(Song song) {
    final mediaItem = MediaItem(
      id: song.uri,
      title: song.title,
      artist: song.artist,
      album: song.album,
      duration: song.duration,
      artUri: song.artworkUri,
    );
    return AudioSource.uri(Uri.parse(song.uri), tag: mediaItem);
  }

  Future<void> dispose() async {
    await _sequenceSub?.cancel();
    await _loopModeSub?.cancel();
    await _shuffleSub?.cancel();

    await _queueController.close();
    await _currentSongController.close();
    await _repeatModeController.close();
    await _shuffleController.close();

    await _player.dispose();
  }
}