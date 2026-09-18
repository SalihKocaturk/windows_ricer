import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  static const platform = MethodChannel('winricer/window_manager');
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInBack),
    );
    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // Sarı butona basınca animasyonla içeri süzülüp küçülme efekti
  Future<void> _handleAnimatedMinimize() async {
    await _animController.forward();
    await platform.invokeMethod('minimizeApp');
    // Pencere tekrar açıldığında görünür olması için animasyonu resetle
    _animController.reset();
  }

  Future<void> _handleClose() async {
    await _animController.forward();
    await platform.invokeMethod('closeApp');
  }

  void _launchApp(String command) {
    try {
      Process.run(command, []);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(opacity: _fadeAnimation.value, child: child),
        );
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0C1416).withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF1DE9B6).withValues(alpha: 0.18),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            children: [
              // 1. Özel Pencere Başlık Barı (Özelleştirilmiş macOS Butonları)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.blur_on_rounded,
                      color: Color(0xFF1DE9B6),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "WinRicer",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const Spacer(),
                    // Özelleştirilmiş Butonlar
                    _CustomWindowButton(
                      color: const Color(0xFFFF5F56),
                      hoverIcon: Icons.close_rounded,
                      onTap: _handleClose,
                    ),
                    const SizedBox(width: 8),
                    _CustomWindowButton(
                      color: const Color(0xFFFFBD2E),
                      hoverIcon: Icons.remove_rounded,
                      onTap: _handleAnimatedMinimize, // Animasyonlu küçülme!
                    ),
                    const SizedBox(width: 8),
                    _CustomWindowButton(
                      color: const Color(0xFF27C93F),
                      hoverIcon: Icons.fullscreen_rounded,
                      onTap: () {},
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // 2. Paylaştığın Görseldeki Buz Efektli Görev Çubuğu (Frosted Glass Dock)
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: _FrostedGlassDock(onLaunch: _launchApp),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------- BUZ EFEKTLİ DOCK BİLEŞENİ -------------------
class _FrostedGlassDock extends StatelessWidget {
  final Function(String) onLaunch;
  const _FrostedGlassDock({required this.onLaunch});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 25,
          sigmaY: 25,
        ), // Buz/Frosted Cam Efekti
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(
              0xFF132225,
            ).withValues(alpha: 0.65), // Yarı şeffaf koyu zümrüt cam
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DockIconItem(
                icon: Icons.folder_rounded,
                color: const Color(0xFF4CAF50),
                label: "Files",
                isRunning: true,
                onTap: () => onLaunch("explorer.exe"),
              ),
              _DockIconItem(
                icon: Icons.public_rounded,
                color: const Color(0xFFFF7043),
                label: "Browser",
                isRunning: true,
                onTap: () => onLaunch("chrome.exe"),
              ),
              _DockIconItem(
                icon: Icons.code_rounded,
                color: const Color(0xFF29B6F6),
                label: "VS Code",
                isRunning: true,
                onTap: () => onLaunch("code"),
              ),
              _DockIconItem(
                icon: Icons.terminal_rounded,
                color: const Color(0xFF78909C),
                label: "Terminal",
                isRunning: false,
                onTap: () => onLaunch("wt.exe"),
              ),
              _DockIconItem(
                icon: Icons.tune_rounded,
                color: const Color(0xFF26A69A),
                label: "Settings",
                isRunning: false,
                onTap: () {},
              ),
              _DockIconItem(
                icon: Icons.extension_rounded,
                color: const Color(0xFFAB47BC),
                label: "Extensions",
                isRunning: false,
                onTap: () {},
              ),
              Container(
                height: 28,
                width: 1,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: Colors.white.withValues(alpha: 0.15),
              ),
              _DockIconItem(
                icon: Icons.apps_rounded,
                color: Colors.white70,
                label: "App Drawer",
                isRunning: false,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------- DOCK İKONU VE YAYLANMA (HOVER) EFEKTİ -------------------
class _DockIconItem extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String label;
  final bool isRunning;
  final VoidCallback onTap;

  const _DockIconItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.isRunning,
    required this.onTap,
  });

  @override
  State<_DockIconItem> createState() => _DockIconItemState();
}

class _DockIconItemState extends State<_DockIconItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          transform: Matrix4.translationValues(
            0,
            _isHovered ? -7 : 0,
            0,
          ), // Yukarı zıplama
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: _isHovered ? 48 : 42,
                height: _isHovered ? 48 : 42,
                decoration: BoxDecoration(
                  color: widget.color.withValues(
                    alpha: _isHovered ? 0.28 : 0.16,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isHovered ? widget.color : Colors.white12,
                    width: 1,
                  ),
                ),
                child: Icon(
                  widget.icon,
                  color: widget.color,
                  size: _isHovered ? 26 : 22,
                ),
              ),
              const SizedBox(height: 4),
              // Çalışan uygulama altındaki yeşil nokta göstergesi
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: widget.isRunning
                      ? const Color(0xFF1DE9B6)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------- ÖZEL PENCERE KONTROL BUTONU -------------------
class _CustomWindowButton extends StatefulWidget {
  final Color color;
  final IconData hoverIcon;
  final VoidCallback onTap;

  const _CustomWindowButton({
    required this.color,
    required this.hoverIcon,
    required this.onTap,
  });

  @override
  State<_CustomWindowButton> createState() => _CustomWindowButtonState();
}

class _CustomWindowButtonState extends State<_CustomWindowButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            boxShadow: _hover
                ? [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.6),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: _hover
              ? Center(
                  child: Icon(widget.hoverIcon, size: 9, color: Colors.black87),
                )
              : null,
        ),
      ),
    );
  }
}
