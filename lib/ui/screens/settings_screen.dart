import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../theme/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Update every 10 seconds if sleep timer is active so subtitle stays fresh
    _ticker = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final accent = app.accentColor;
    final size = MediaQuery.of(context).size;

    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.4),
          radius: 1.1,
          colors: [AppColors.bgGlass, AppColors.bgDeep],
        ),
      ),
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          size.width * 0.06,
          20,
          size.width * 0.06,
          140,
        ),
        children: [
          Text(
            'SETTINGS',
            style: TextStyle(
              color: accent.withValues(alpha: 0.8),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Preferences',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 24),

          // ── AUDIO & PLAYBACK ──────────────────────────────────────
          const _SectionHeader(title: 'Audio & Playback'),
          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.bedtime_rounded,
                title: 'Sleep Timer',
                subtitle: app.sleepEndsAt == null
                    ? 'Off'
                    : 'Stops in ${_formatRemaining(app.sleepRemaining)}',
                isActive: app.sleepEndsAt != null,
                accentColor: accent,
                onTap: () => _openSleepTimerSheet(context),
              ),
              Divider(height: 1, color: AppColors.divider.withValues(alpha: 0.5)),
              _SettingsTile(
                icon: Icons.filter_alt_rounded,
                title: 'Filter Short Audio',
                subtitle: 'Ignore ringtones and clips under 30s',
                accentColor: accent,
                trailing: Switch(
                  value: app.hideShortClips,
                  onChanged: (val) => app.toggleHideShortClips(val),
                ),
                onTap: () => app.toggleHideShortClips(!app.hideShortClips),
              ),
              Divider(height: 1, color: AppColors.divider.withValues(alpha: 0.5)),
              _SettingsTile(
                icon: Icons.file_upload_rounded,
                title: 'Import Audio Files',
                subtitle: 'Add local audio files to library',
                accentColor: accent,
                onTap: () async {
                  await app.importSongs();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Imported ${app.songsCache.length} tracks'),
                      ),
                    );
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: 28),

          // ── PERSONALIZATION ───────────────────────────────────────
          const _SectionHeader(title: 'Personalization'),
          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.palette_rounded,
                title: 'Accent Color',
                subtitle: 'Customize highlights and glows',
                accentColor: accent,
                trailing: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
                onTap: () => _openColorPicker(context),
              ),
              Divider(height: 1, color: AppColors.divider.withValues(alpha: 0.5)),
              _SettingsTile(
                icon: Icons.dark_mode_rounded,
                title: 'Theme Mode',
                subtitle: switch (app.themeMode) {
                  ThemeMode.dark => 'Dark theme',
                  ThemeMode.light => 'Light theme',
                  ThemeMode.system => 'System theme',
                },
                accentColor: accent,
                onTap: () => _openThemeModeSheet(context),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // ── ADVANCED ──────────────────────────────────────────────
          const _SectionHeader(title: 'Advanced & System'),
          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.security_rounded,
                title: 'App Permissions',
                subtitle: 'Manage storage and audio access',
                accentColor: accent,
                onTap: () => openAppSettings(),
              ),
              Divider(height: 1, color: AppColors.divider.withValues(alpha: 0.5)),
              _SettingsTile(
                icon: Icons.refresh_rounded,
                title: 'Rescan Device Storage',
                subtitle: 'Force refresh library cache',
                accentColor: accent,
                onTap: () async {
                  await app.refreshLibrarySongs(forceRescan: true);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Scanned ${app.songsCache.length} tracks'),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openColorPicker(BuildContext context) {
    final app = context.read<AppState>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _ColorPickerSheet(
        currentColor: app.accentColor,
        onSelect: (newColor) {
          app.updateAccentColor(newColor);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _openThemeModeSheet(BuildContext context) {
    final app = context.read<AppState>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.bgDeep,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'THEME MODE',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.brightness_auto_rounded, color: AppColors.textPrimary),
              title: Text('System Default', style: TextStyle(color: AppColors.textPrimary)),
              trailing: app.themeMode == ThemeMode.system ? Icon(Icons.check, color: app.accentColor) : null,
              onTap: () {
                app.setThemeMode(ThemeMode.system);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.dark_mode_rounded, color: AppColors.textPrimary),
              title: Text('Dark Mode', style: TextStyle(color: AppColors.textPrimary)),
              trailing: app.themeMode == ThemeMode.dark ? Icon(Icons.check, color: app.accentColor) : null,
              onTap: () {
                app.setThemeMode(ThemeMode.dark);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.light_mode_rounded, color: AppColors.textPrimary),
              title: Text('Light Mode', style: TextStyle(color: AppColors.textPrimary)),
              trailing: app.themeMode == ThemeMode.light ? Icon(Icons.check, color: app.accentColor) : null,
              onTap: () {
                app.setThemeMode(ThemeMode.light);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSleepTimerSheet(BuildContext context) async {
    final app = context.read<AppState>();
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SleepTimerSheet(
        onSelect: (d) {
          app.setSleepTimer(d);
          Navigator.pop(context);
        },
        accentColor: app.accentColor,
      ),
    );
  }

  static String _formatRemaining(Duration? d) {
    if (d == null) return '—';
    final mTotal = (d.inSeconds / 60).ceil();
    return mTotal >= 60 ? '${mTotal ~/ 60}h ${mTotal % 60}m' : '${mTotal}m';
  }
}

// ── COLOR PICKER ─────────────────────────────────────────────────────

class _ColorPickerSheet extends StatelessWidget {
  final Color currentColor;
  final ValueChanged<Color> onSelect;

  const _ColorPickerSheet({
    required this.currentColor,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.accentPresets;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.bgDeep,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'ACCENT COLOR',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 5,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: palette.map((c) {
              final isSelected = c.toARGB32() == currentColor.toARGB32();
              return GestureDetector(
                onTap: () => onSelect(c),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 20)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── REUSABLE UI COMPONENTS ──────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgGlass,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(children: children),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isActive;
  final Color accentColor;
  final VoidCallback onTap;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.accentColor,
    this.isActive = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isActive
                    ? accentColor.withValues(alpha: 0.15)
                    : AppColors.divider.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isActive ? accentColor : AppColors.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isActive ? accentColor : AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            trailing ??
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textDim,
                  size: 20,
                ),
          ],
        ),
      ),
    );
  }
}

class _SleepTimerSheet extends StatelessWidget {
  final ValueChanged<Duration?> onSelect;
  final Color accentColor;

  const _SleepTimerSheet({
    required this.onSelect,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgDeep,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'SLEEP TIMER',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: Icon(Icons.timer_off_rounded, color: AppColors.textMuted),
            title: Text('Turn Off Timer', style: TextStyle(color: AppColors.textPrimary)),
            onTap: () => onSelect(null),
          ),
          ListTile(
            leading: Icon(Icons.timer_rounded, color: accentColor),
            title: Text('15 minutes', style: TextStyle(color: AppColors.textPrimary)),
            onTap: () => onSelect(const Duration(minutes: 15)),
          ),
          ListTile(
            leading: Icon(Icons.timer_rounded, color: accentColor),
            title: Text('30 minutes', style: TextStyle(color: AppColors.textPrimary)),
            onTap: () => onSelect(const Duration(minutes: 30)),
          ),
          ListTile(
            leading: Icon(Icons.timer_rounded, color: accentColor),
            title: Text('45 minutes', style: TextStyle(color: AppColors.textPrimary)),
            onTap: () => onSelect(const Duration(minutes: 45)),
          ),
          ListTile(
            leading: Icon(Icons.nightlight_round, color: accentColor),
            title: Text('1 hour', style: TextStyle(color: AppColors.textPrimary)),
            onTap: () => onSelect(const Duration(hours: 1)),
          ),
        ],
      ),
    );
  }
}