import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import '../home_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  VideoPlayerController? _videoController;
  late final AudioPlayer _introAudioPlayer;

  bool _isVideoInitialized = false;
  bool _isNavigating = false;
  Timer? _fallbackTimer;

  @override
  void initState() {
    super.initState();
    _introAudioPlayer = AudioPlayer();

    _initializeIntroMedia();

    // Fallback timer: intro_video is ~10 seconds. Fallback at 10.5s guarantees progression.
    _fallbackTimer = Timer(const Duration(milliseconds: 10500), () {
      _navigateToHome();
    });
  }

  Future<void> _initializeIntroMedia() async {
    // 1. Start audio playback in parallel with local cache guarantee
    _playIntroMusic();

    // 2. Initialize and play the custom MP4 intro video
    try {
      final controller = VideoPlayerController.asset('assets/intro/intro_video.mp4');
      _videoController = controller;

      await controller.initialize();
      await controller.setVolume(1.0);
      await controller.setLooping(false);

      if (!mounted) {
        controller.dispose();
        return;
      }

      setState(() {
        _isVideoInitialized = true;
      });

      await controller.play();

      controller.addListener(() {
        if (!mounted || _isNavigating) return;
        final value = controller.value;
        if (value.isInitialized &&
            value.duration > Duration.zero &&
            value.position >= value.duration) {
          _navigateToHome();
        }
      });
    } catch (e) {
      debugPrint('Intro video initialization error: $e');
      // If video playback fails, fallback timer or audio completion will navigate
    }
  }

  Future<void> _playIntroMusic() async {
    try {
      // Extract asset to a local cache file for 100% reliable offline playback on Android 14
      // This bypasses Android localhost cleartext proxy restrictions completely.
      final byteData = await rootBundle.load('assets/intro/intro_music.mp3');
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/intro_music.mp3');
      await tempFile.writeAsBytes(
        byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
        flush: true,
      );

      await _introAudioPlayer.setFilePath(tempFile.path);
      await _introAudioPlayer.setVolume(1.0);
      await _introAudioPlayer.play();
    } catch (e) {
      debugPrint('Direct file audio playback failed, falling back to asset: $e');
      try {
        await _introAudioPlayer.setAsset('assets/intro/intro_music.mp3');
        await _introAudioPlayer.setVolume(1.0);
        await _introAudioPlayer.play();
      } catch (err) {
        debugPrint('Intro audio playback error: $err');
      }
    }
  }

  void _navigateToHome() {
    if (_isNavigating || !mounted) return;
    _isNavigating = true;

    _fallbackTimer?.cancel();

    // Gracefully stop media
    try {
      _videoController?.pause();
    } catch (_) {}
    try {
      _introAudioPlayer.stop();
    } catch (_) {}

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const HomeShell(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _videoController?.dispose();
    _introAudioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final logoSize = (size.width * 0.65).clamp(240.0, 360.0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: GestureDetector(
          // Allow tapping anywhere to enter instantly without any button clutter
          onTap: _navigateToHome,
          behavior: HitTestBehavior.opaque,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Clean white canvas matching native splash theme
              Container(color: Colors.white),

              // Custom MP4 Intro Video
              if (_isVideoInitialized && _videoController != null)
                Center(
                  child: SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _videoController!.value.size.width > 0
                            ? _videoController!.value.size.width
                            : size.width,
                        height: _videoController!.value.size.height > 0
                            ? _videoController!.value.size.height
                            : size.height,
                        child: VideoPlayer(_videoController!),
                      ),
                    ),
                  ),
                )
              else
                // Seamless placeholder during video initialization (matches native launch)
                Center(
                  child: Image.asset(
                    'assets/icon/logo_white_bg.png',
                    width: logoSize,
                    height: logoSize,
                    fit: BoxFit.contain,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}