import 'package:flutter/material.dart';
import 'package:ezze_music/ui/theme/app_colors.dart';

/// Circular glass action button with subtle border and haptics
class IconCircleButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double size;
  final Color? backgroundColor;

  const IconCircleButton({
    super.key,
    required this.child,
    this.onTap,
    this.size = 40,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor ?? AppColors.bgGlass,
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Center(child: child),
      ),
    );
  }
}

/// Themed popup menu with rounded obsidian glass look
class ThemedMenu extends StatelessWidget {
  final ValueChanged<String> onSelected;
  final List<PopupMenuEntry<String>> items;
  final IconData icon;
  final Color? iconColor;

  const ThemedMenu({
    super.key,
    required this.onSelected,
    required this.items,
    this.icon = Icons.more_vert_rounded,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        popupMenuTheme: PopupMenuThemeData(
          color: AppColors.bgGlass,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.divider),
          ),
          elevation: 12,
        ),
      ),
      child: PopupMenuButton<String>(
        onSelected: onSelected,
        icon: Icon(
          icon,
          color: iconColor ?? AppColors.textMuted,
          size: 20,
        ),
        itemBuilder: (_) => items,
      ),
    );
  }
}

/// Individual item for ThemedMenu with optional destructive highlighting
class ThemedMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDestructive;

  const ThemedMenuItem({
    super.key,
    required this.icon,
    required this.label,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.redAccent : AppColors.textPrimary;
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
