import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arabilogia/providers/theme_provider.dart';

class ThemeToggleButton extends StatefulWidget {
  const ThemeToggleButton({super.key});

  @override
  State<ThemeToggleButton> createState() => _ThemeToggleButtonState();
}

class _ThemeToggleButtonState extends State<ThemeToggleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    if (isDark && _controller.status != AnimationStatus.completed) {
      _controller.value = 0.5;
    } else if (!isDark && _controller.status != AnimationStatus.dismissed) {
      _controller.value = 0.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap(ThemeProvider themeProvider, bool isDark) {
    if (isDark) {
      _controller.reverse();
      themeProvider.setThemeMode(ThemeModeOption.light);
    } else {
      _controller.forward();
      themeProvider.setThemeMode(ThemeModeOption.dark);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return GestureDetector(
      onTap: () => _handleTap(themeProvider, isDark),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF2B2F36).withValues(alpha: 0.9)
              : Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.18)
                : Colors.black.withValues(alpha: 0.1),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            RotationTransition(
              turns: _rotationAnimation,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) => ScaleTransition(
                  scale: anim,
                  child: child,
                ),
                child: Icon(
                  isDark ? Icons.dark_mode_rounded : Icons.wb_sunny_rounded,
                  key: ValueKey<bool>(isDark),
                  size: 20,
                  color: isDark ? const Color(0xFFFFD166) : const Color(0xFFFF9F1C),
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                fontFamily: 'Estedad',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFEAEFF5) : const Color(0xFF1D2023),
              ),
              child: Text(isDark ? 'داكن' : 'فاتح'),
            ),
          ],
        ),
      ),
    );
  }
}

class MobileTheme3DotsMenu extends StatelessWidget {
  const MobileTheme3DotsMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF2B2F36).withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: 0.85),
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.black.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: PopupMenuButton<ThemeModeOption>(
        icon: Icon(
          Icons.more_vert_rounded,
          color: isDark ? const Color(0xFFEAEFF5) : const Color(0xFF1D2023),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: isDark ? const Color(0xFF2B2F36) : Colors.white,
        elevation: 8,
        onSelected: (option) {
          themeProvider.setThemeMode(option);
        },
        itemBuilder: (context) => [
          PopupMenuItem<ThemeModeOption>(
            value: ThemeModeOption.light,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.wb_sunny_rounded,
                  color: Color(0xFFFF9F1C),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  'مظهر فاتح',
                  style: TextStyle(
                    fontFamily: 'Estedad',
                    fontSize: 14,
                    fontWeight: !isDark ? FontWeight.bold : FontWeight.normal,
                    color: isDark ? const Color(0xFFEAEFF5) : const Color(0xFF1D2023),
                  ),
                ),
                if (!isDark) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.check_rounded, size: 18, color: Color(0xFFEB8A00)),
                ],
              ],
            ),
          ),
          PopupMenuItem<ThemeModeOption>(
            value: ThemeModeOption.dark,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.dark_mode_rounded,
                  color: Color(0xFFFFD166),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  'مظهر داكن',
                  style: TextStyle(
                    fontFamily: 'Estedad',
                    fontSize: 14,
                    fontWeight: isDark ? FontWeight.bold : FontWeight.normal,
                    color: isDark ? const Color(0xFFEAEFF5) : const Color(0xFF1D2023),
                  ),
                ),
                if (isDark) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.check_rounded, size: 18, color: Color(0xFFEB8A00)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
