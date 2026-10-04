import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import 'screens/browse_screen.dart';
import 'screens/now_playing_screen.dart';
import 'screens/playlists_screen.dart';
import 'screens/search_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/songs_screen.dart';
import 'theme/app_colors.dart';
import 'widgets/mini_player_bar.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  final _tabs = const <Widget>[
    SongsScreen(),
    PlaylistsScreen(),
    BrowseScreen(),
    SearchScreen(),
    SettingsScreen(),
  ];

  static const _destinations = [
    (Icons.music_note_rounded, Icons.music_note_outlined, 'Tracks'),
    (Icons.queue_music_rounded, Icons.queue_music_outlined, 'Playlists'),
    (Icons.grid_view_rounded, Icons.grid_view_outlined, 'Browse'),
    (Icons.search_rounded, Icons.search_outlined, 'Search'),
    (Icons.settings_rounded, Icons.settings_outlined, 'Settings'),
  ];

  void _openNowPlaying(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, anim, secAnim) => const NowPlayingScreen(),
        transitionsBuilder: (context, anim, secAnim, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          final tween = Tween(begin: begin, end: end)
              .chain(CurveTween(curve: Curves.easeOutCubic));
          return SlideTransition(position: anim.drive(tween), child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final colors = context.colors;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final app = context.watch<AppState>();
    final hasSong = app.player.currentSong != null;

    final navBarBottom = bottomPadding > 0 ? bottomPadding : 14.0;
    final miniPlayerBottom = navBarBottom + 66.0;

    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        setState(() => _index = 0);
      },
      child: Scaffold(
        backgroundColor: colors.bgDeep,
        extendBody: true,
        body: Stack(
          children: [
            // ── Main Tab Content ──
            SafeArea(
              bottom: false,
              child: IndexedStack(
                index: _index,
                children: _tabs,
              ),
            ),

            // ── Floating Mini Player Bar ──
            Positioned(
              left: 12,
              right: 12,
              bottom: miniPlayerBottom,
              child: AnimatedSlide(
                offset: hasSong ? Offset.zero : const Offset(0, 1.5),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                child: AnimatedOpacity(
                  opacity: hasSong ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 250),
                  child: hasSong
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: MiniPlayerBar(
                            onTap: () => _openNowPlaying(context),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),

            // ── Floating Sleek Navigation Bar ──
            Positioned(
              left: 12,
              right: 12,
              bottom: navBarBottom,
              child: _ThemedNavBar(
                selectedIndex: _index,
                destinations: _destinations,
                accentColor: accent,
                onTap: (i) {
                  HapticFeedback.selectionClick();
                  setState(() => _index = i);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Themed Sliding Floating Nav Bar ───────────────────────────────────────────

class _ThemedNavBar extends StatelessWidget {
  final int selectedIndex;
  final List<(IconData, IconData, String)> destinations;
  final Color accentColor;
  final ValueChanged<int> onTap;

  const _ThemedNavBar({
    required this.selectedIndex,
    required this.destinations,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: colors.bgGlass.withValues(alpha: colors.isDark ? 0.95 : 0.98),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: colors.borderSubtle, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: colors.isDark ? 0.45 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(destinations.length, (i) {
          final (activeIcon, inactiveIcon, label) = destinations[i];
          final isSelected = selectedIndex == i;

          return _NavItem(
            activeIcon: activeIcon,
            inactiveIcon: inactiveIcon,
            label: label,
            isSelected: isSelected,
            accentColor: accentColor,
            onTap: () => onTap(i),
          );
        }),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  const _NavItem({
    required this.activeIcon,
    required this.inactiveIcon,
    required this.label,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: colors.isDark ? 0.16 : 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected ? accentColor : colors.textMuted,
              size: 22,
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              child: isSelected
                  ? Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}