import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ezze_music/models/song.dart';
import 'package:ezze_music/ui/widgets/music_visualizer_view.dart';

void main() {
  group('MusicVisualizerView Widget Tests', () {
    final testSong = const Song(
      id: 101,
      title: 'Echoes of Eternity',
      artist: 'Solaris',
      album: 'Cosmic Drift',
      duration: Duration(minutes: 4),
      uri: 'content://media/external/audio/media/101',
    );

    testWidgets('Renders MusicVisualizerView with live status and style indicator', (tester) async {
      final positionController = StreamController<Duration>.broadcast();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MusicVisualizerView(
              size: 300,
              song: testSong,
              songId: 101,
              accent: Colors.cyanAccent,
              isPlaying: true,
              positionStream: positionController.stream,
            ),
          ),
        ),
      );

      // Verify header components
      expect(find.text('LIVE SPECTRUM'), findsOneWidget);
      expect(find.text('RADIAL'), findsOneWidget);

      // Advance animation ticker
      await tester.pump(const Duration(milliseconds: 50));
      positionController.add(const Duration(seconds: 15));
      await tester.pump(const Duration(milliseconds: 50));

      // Tap style button to cycle to STUDIO
      await tester.tap(find.text('RADIAL'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('STUDIO'), findsOneWidget);

      // Tap style button to cycle to WAVE
      await tester.tap(find.text('STUDIO'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('WAVE'), findsOneWidget);

      // Tap style button to cycle back to RADIAL
      await tester.tap(find.text('WAVE'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('RADIAL'), findsOneWidget);

      await positionController.close();
    });

    testWidgets('Shows PAUSED status when isPlaying is false', (tester) async {
      final positionController = StreamController<Duration>.broadcast();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MusicVisualizerView(
              size: 300,
              song: testSong,
              songId: 101,
              accent: Colors.deepPurpleAccent,
              isPlaying: false,
              positionStream: positionController.stream,
            ),
          ),
        ),
      );

      expect(find.text('PAUSED'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 100));
      await positionController.close();
    });
  });
}
