import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../../models/song.dart';
import '../theme/app_colors.dart';

/// Modes of visualizer rendering within the visualizer stage
enum VisualizerStyle {
  radialSpectrum, // 360-degree radial bars with central album art
  studioEqualizer, // Studio multi-band peak analyzer with floating drop caps
  liquidWave, // Multi-layer organic fluid sine wave curves
}

/// High-performance, mathematically synchronized audio visualizer
/// that reacts smoothly in real-time to the current song's playback position and rhythm.
class MusicVisualizerView extends StatefulWidget {
  final double size;
  final Song song;
  final int songId;
  final Color accent;
  final bool isPlaying;
  final Stream<bool>? isPlayingStream;
  final Stream<Duration> positionStream;

  const MusicVisualizerView({
    super.key,
    required this.size,
    required this.song,
    required this.songId,
    required this.accent,
    required this.isPlaying,
    this.isPlayingStream,
    required this.positionStream,
  });

  @override
  State<MusicVisualizerView> createState() => _MusicVisualizerViewState();
}

class _MusicVisualizerViewState extends State<MusicVisualizerView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker;
  Duration _currentPosition = Duration.zero;
  late bool _isPlaying;

  StreamSubscription<bool>? _playingSub;
  StreamSubscription<Duration>? _positionSub;

  // Smoothing buffers for 36 frequency bands
  static const int _numBands = 36;
  final List<double> _bandValues = List.filled(_numBands, 0.1);
  final List<double> _peakValues = List.filled(_numBands, 0.1);

  // Active visualizer style (cycles on double tap or button)
  VisualizerStyle _style = VisualizerStyle.radialSpectrum;

  // Song acoustic seed derived from song ID and duration
  int _seed = 42;

  @override
  void initState() {
    super.initState();
    _isPlaying = widget.isPlaying;
    _seed = (widget.songId * 31 + widget.song.title.hashCode).abs();

    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _positionSub = widget.positionStream.listen((pos) {
      if (mounted) {
        _currentPosition = pos;
      }
    });

    if (widget.isPlayingStream != null) {
      _playingSub = widget.isPlayingStream!.listen((playing) {
        if (mounted && _isPlaying != playing) {
          setState(() {
            _isPlaying = playing;
          });
        }
      });
    }
  }

  @override
  void didUpdateWidget(MusicVisualizerView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.songId != widget.songId) {
      _seed = (widget.songId * 31 + widget.song.title.hashCode).abs();
    }
    if (oldWidget.isPlaying != widget.isPlaying) {
      _isPlaying = widget.isPlaying;
    }
    if (oldWidget.isPlayingStream != widget.isPlayingStream) {
      _playingSub?.cancel();
      _playingSub = widget.isPlayingStream?.listen((playing) {
        if (mounted && _isPlaying != playing) {
          setState(() {
            _isPlaying = playing;
          });
        }
      });
    }
    if (oldWidget.positionStream != widget.positionStream) {
      _positionSub?.cancel();
      _positionSub = widget.positionStream.listen((pos) {
        if (mounted) {
          _currentPosition = pos;
        }
      });
    }
  }

  @override
  void dispose() {
    _playingSub?.cancel();
    _positionSub?.cancel();
    _ticker.dispose();
    super.dispose();
  }

  void _cycleStyle() {
    setState(() {
      _style = switch (_style) {
        VisualizerStyle.radialSpectrum => VisualizerStyle.studioEqualizer,
        VisualizerStyle.studioEqualizer => VisualizerStyle.liquidWave,
        VisualizerStyle.liquidWave => VisualizerStyle.radialSpectrum,
      };
    });
  }

  /// Calculates dynamic frequency spectrum values synchronized with playback position
  void _updateBands(double animValue) {
    if (!_isPlaying) {
      // Smooth decay when paused
      for (int i = 0; i < _numBands; i++) {
        _bandValues[i] = _bandValues[i] * 0.92;
        if (_bandValues[i] < 0.05) _bandValues[i] = 0.05;
        _peakValues[i] = _peakValues[i] * 0.94;
        if (_peakValues[i] < 0.05) _peakValues[i] = 0.05;
      }
      return;
    }

    final ms = _currentPosition.inMilliseconds + (animValue * 16.6).toInt();
    final timeSec = ms / 1000.0;

    // Estimate rhythmic tempo based on seed (110 - 138 BPM range)
    final bpm = 110.0 + (_seed % 28);
    final beatInterval = 60.0 / bpm;
    final beatPhase = (timeSec % beatInterval) / beatInterval;
    // Sharp kick drum punch on beats
    final kickPulse = math.exp(-beatPhase * 4.5);

    for (int i = 0; i < _numBands; i++) {
      final normIdx = i / (_numBands - 1); // 0.0 (bass) to 1.0 (treble)

      // Frequency harmonic components
      final bassFreq = 2.0 * math.pi / beatInterval;
      final midFreq = bassFreq * (2.0 + (i % 5) * 0.7);
      final highFreq = bassFreq * (4.0 + (i % 7) * 1.3);

      final w1 = math.sin(timeSec * bassFreq + i * 0.35);
      final w2 = math.cos(timeSec * midFreq + i * 0.22);
      final w3 = math.sin(timeSec * highFreq + i * 0.55);

      double target = 0.0;
      if (normIdx < 0.25) {
        // Sub-bass & Bass: heavy kick pulse + low resonance
        target = (kickPulse * 0.75) + (w1 * 0.25).abs();
      } else if (normIdx < 0.7) {
        // Midrange: vocal & melody articulation
        target = (w2 * 0.5).abs() + (w1 * 0.3).abs() + (kickPulse * 0.2);
      } else {
        // Treble & Air: rapid shimmer + hi-hat sparkles
        target = (w3 * 0.6).abs() + (w2 * 0.25).abs() + (kickPulse * 0.15);
      }

      // Add dynamic envelope modulation
      final envelope = (math.sin(timeSec * 0.3 + i * 0.1) * 0.15) + 0.85;
      target = (target * envelope).clamp(0.08, 1.0);

      // Smooth interpolation (spring-like responsiveness)
      _bandValues[i] = _bandValues[i] * 0.65 + target * 0.35;

      // Peak-hold decay physics
      if (_bandValues[i] > _peakValues[i]) {
        _peakValues[i] = _bandValues[i];
      } else {
        _peakValues[i] = math.max(_bandValues[i], _peakValues[i] - 0.025);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ticker,
      builder: (context, _) {
        _updateBands(_ticker.value);

        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: AppColors.bgGlass,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: widget.accent.withValues(alpha: 0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.accent.withValues(alpha: 0.20),
                blurRadius: 36,
                spreadRadius: 2,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.55),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Top status bar with style toggle
                Positioned(
                  top: 14,
                  left: 18,
                  right: 18,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isPlaying
                                  ? widget.accent
                                  : AppColors.textMuted,
                              boxShadow: _isPlaying
                                  ? [
                                      BoxShadow(
                                        color: widget.accent,
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isPlaying ? 'LIVE SPECTRUM' : 'PAUSED',
                            style: TextStyle(
                              color: _isPlaying
                                  ? widget.accent
                                  : AppColors.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: _cycleStyle,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: widget.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: widget.accent.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Text(
                            switch (_style) {
                              VisualizerStyle.radialSpectrum => 'RADIAL',
                              VisualizerStyle.studioEqualizer => 'STUDIO',
                              VisualizerStyle.liquidWave => 'WAVE',
                            },
                            style: TextStyle(
                              color: widget.accent,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Visualizer Canvas
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 38, 12, 12),
                  child: switch (_style) {
                    VisualizerStyle.radialSpectrum => _buildRadialSpectrum(),
                    VisualizerStyle.studioEqualizer => _buildStudioEqualizer(),
                    VisualizerStyle.liquidWave => _buildLiquidWave(),
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Style 1: Radial 360° Circular Spectrum ──────────────────────────────────

  Widget _buildRadialSpectrum() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final radius = math.min(constraints.maxWidth, constraints.maxHeight) / 2;
        final center = Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);
        final artDiameter = (radius * 0.88).clamp(80.0, 130.0);

        return Stack(
          alignment: Alignment.center,
          children: [
            // Custom Painted Radial Bars & Soundwave Ripples
            CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _RadialSpectrumPainter(
                bands: _bandValues,
                peaks: _peakValues,
                accent: widget.accent,
                center: center,
                innerRadius: artDiameter / 2 + 6,
                outerRadius: radius - 6,
              ),
            ),

            // Central Floating Album Artwork Disc
            Container(
              width: artDiameter,
              height: artDiameter,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.accent.withValues(alpha: 0.35),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 14,
                  ),
                ],
                border: Border.all(
                  color: widget.accent.withValues(alpha: 0.6),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: QueryArtworkWidget(
                  key: ValueKey('viz_art_${widget.songId}'),
                  id: widget.songId,
                  type: ArtworkType.AUDIO,
                  artworkHeight: artDiameter,
                  artworkWidth: artDiameter,
                  artworkFit: BoxFit.cover,
                  quality: 100,
                  keepOldArtwork: true,
                  nullArtworkWidget: Container(
                    color: AppColors.bgDeep,
                    child: Center(
                      child: Icon(
                        Icons.music_note_rounded,
                        color: widget.accent,
                        size: artDiameter * 0.45,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Style 2: Studio Multiband Equalizer ─────────────────────────────────────

  Widget _buildStudioEqualizer() {
    return CustomPaint(
      painter: _StudioEqualizerPainter(
        bands: _bandValues,
        peaks: _peakValues,
        accent: widget.accent,
      ),
      child: const SizedBox.expand(),
    );
  }

  // ── Style 3: Liquid Fluid Sine Wave ─────────────────────────────────────────

  Widget _buildLiquidWave() {
    return CustomPaint(
      painter: _LiquidWavePainter(
        bands: _bandValues,
        accent: widget.accent,
        animValue: _ticker.value,
      ),
      child: const SizedBox.expand(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM PAINTERS
// ─────────────────────────────────────────────────────────────────────────────

/// Paints 36 radial bars radiating outward from the central album disc
class _RadialSpectrumPainter extends CustomPainter {
  final List<double> bands;
  final List<double> peaks;
  final Color accent;
  final Offset center;
  final double innerRadius;
  final double outerRadius;

  _RadialSpectrumPainter({
    required this.bands,
    required this.peaks,
    required this.accent,
    required this.center,
    required this.innerRadius,
    required this.outerRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final int count = bands.length;
    final double maxBarHeight = outerRadius - innerRadius;
    final double angleStep = (2 * math.pi) / count;

    // 1. Concentric Bass Ripple Waves
    final avgBass = (bands[0] + bands[1] + bands[2]) / 3.0;
    if (avgBass > 0.3) {
      final ripplePaint = Paint()
        ..color = accent.withValues(alpha: (avgBass * 0.25).clamp(0.0, 0.35))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(
        center,
        innerRadius + maxBarHeight * avgBass * 0.7,
        ripplePaint,
      );
    }

    // 2. Radial Frequency Bars
    final barPaint = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final peakPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < count; i++) {
      final angle = i * angleStep - (math.pi / 2);
      final value = bands[i];
      final peak = peaks[i];

      final barLength = math.max(4.0, maxBarHeight * value);
      final startR = innerRadius + 2;
      final endR = startR + barLength;

      final startX = center.dx + math.cos(angle) * startR;
      final startY = center.dy + math.sin(angle) * startR;
      final endX = center.dx + math.cos(angle) * endR;
      final endY = center.dy + math.sin(angle) * endR;

      // Dynamic color gradient per bar
      final color = Color.lerp(
        accent,
        Colors.white,
        (value * 0.5).clamp(0.0, 0.5),
      )!;

      barPaint.color = color;
      barPaint.strokeWidth = 3.5;

      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        barPaint,
      );

      // Peak-hold dot
      if (peak > value + 0.05) {
        final peakR = startR + maxBarHeight * peak;
        final peakX = center.dx + math.cos(angle) * peakR;
        final peakY = center.dy + math.sin(angle) * peakR;

        peakPaint.strokeWidth = 3.0;
        canvas.drawCircle(Offset(peakX, peakY), 1.5, peakPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RadialSpectrumPainter oldDelegate) => true;
}

/// Studio-style vertical multi-band analyzer with peak-hold drop caps
class _StudioEqualizerPainter extends CustomPainter {
  final List<double> bands;
  final List<double> peaks;
  final Color accent;

  _StudioEqualizerPainter({
    required this.bands,
    required this.peaks,
    required this.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final int count = math.min(bands.length, 28);
    final double spacing = 4.0;
    final double totalSpacing = spacing * (count - 1);
    final double barWidth = (size.width - totalSpacing) / count;
    final double maxH = size.height - 16;

    final barPaint = Paint()..style = PaintingStyle.fill;
    final peakPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (int i = 0; i < count; i++) {
      final x = i * (barWidth + spacing);
      final val = bands[i];
      final peak = peaks[i];

      final h = (maxH * val).clamp(4.0, maxH);
      final top = size.height - h;

      // Gradient bar from accent base to high-energy glow
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, top, barWidth, h),
        const Radius.circular(4),
      );

      barPaint.shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          accent.withValues(alpha: 0.4),
          accent,
          Color.lerp(accent, Colors.white, 0.6)!,
        ],
      ).createShader(Rect.fromLTWH(x, top, barWidth, h));

      canvas.drawRRect(rect, barPaint);

      // Peak cap indicator
      final peakY = (size.height - (maxH * peak)).clamp(0.0, size.height - 3);
      final peakRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, peakY, barWidth, 2.5),
        const Radius.circular(1.5),
      );
      canvas.drawRRect(peakRRect, peakPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _StudioEqualizerPainter oldDelegate) => true;
}

/// Organic fluid liquid wave visualizer
class _LiquidWavePainter extends CustomPainter {
  final List<double> bands;
  final Color accent;
  final double animValue;

  _LiquidWavePainter({
    required this.bands,
    required this.accent,
    required this.animValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height * 0.55;
    final avgEnergy = bands.reduce((a, b) => a + b) / bands.length;

    // Dual wave layers with phase difference
    _drawWave(canvas, size, midY, avgEnergy, 0.0, accent.withValues(alpha: 0.35));
    _drawWave(canvas, size, midY, avgEnergy, math.pi * 0.6, accent.withValues(alpha: 0.7));
  }

  void _drawWave(
    Canvas canvas,
    Size size,
    double midY,
    double energy,
    double phaseOffset,
    Color color,
  ) {
    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, midY);

    const int points = 30;
    final stepX = size.width / points;

    for (int i = 0; i <= points; i++) {
      final x = i * stepX;
      final bandIdx = (i * (bands.length - 1) / points).round();
      final amp = bands[bandIdx] * (size.height * 0.38) * (energy + 0.2);

      final y = midY +
          math.sin((i / points) * 3 * math.pi + animValue * 2 * math.pi + phaseOffset) *
              amp;

      if (i == 0) {
        path.lineTo(x, y);
      } else {
        final prevX = (i - 1) * stepX;
        final midPointX = (prevX + x) / 2;
        path.quadraticBezierTo(prevX, y, midPointX, y);
      }
    }

    path.lineTo(size.width, size.height);
    path.close();

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color, color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LiquidWavePainter oldDelegate) => true;
}
