import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RiceSuiteScreen extends StatefulWidget {
  const RiceSuiteScreen({super.key});

  @override
  State<RiceSuiteScreen> createState() => _RiceSuiteScreenState();
}

class _RiceSuiteScreenState extends State<RiceSuiteScreen>
    with SingleTickerProviderStateMixin {
  static const platform = MethodChannel('winricer/window_manager');

  String _currentTime = "";
  int _selectedWorkspace = 0;
  late Timer _timer;

  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());

    // Sarı butona basınca çalışacak küçülme animasyonu
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInBack),
    );
    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeIn));
  }

  void _updateTime() {
    final now = DateTime.now();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    setState(() => _currentTime = "$h:$m");
  }

  @override
  void dispose() {
    _timer.cancel();
    _animController.dispose();
    super.dispose();
  }

  // Sarı buton: Animasyonla içeri süzülüp simge durumuna küçülme
  Future<void> _handleMinimize() async {
    await _animController.forward();
    try {
      await platform.invokeMethod('minimizeApp');
    } catch (_) {}
    _animController.reset();
  }

  // Kırmızı buton: Kapatma
  Future<void> _handleClose() async {
    await _animController.forward();
    try {
      await platform.invokeMethod('closeApp');
    } catch (_) {}
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
            color: const Color(0xFF0C1414).withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF1DE9B6).withValues(alpha: 0.18),
              width: 1.2,
            ),
          ),
          child: Column(
            children: [
              // 1. Üst Waybar (Saat, Workspaces ve macOS Butonları)
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF112020),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(15),
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: const Color(0xFF1DE9B6).withValues(alpha: 0.1),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // Workspaces: [A, B, C, D, E]
                    Row(
                      children: List.generate(5, (index) {
                        final labels = ['A', 'B', 'C', 'D', 'E'];
                        final isSelected = _selectedWorkspace == index;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedWorkspace = index),
                          child: Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF1DE9B6)
                                  : Colors.black38,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              labels[index],
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.black
                                    : Colors.white70,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const Spacer(),
                    // Müzik & Saat Kapsülü
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.music_note_rounded,
                            color: Color(0xFF1DE9B6),
                            size: 13,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            "Lyn - No More What Ifs",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _currentTime,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Sağ Üst macOS Butonları
                    Row(
                      children: [
                        _WindowDotButton(
                          color: const Color(0xFFFF5F56),
                          icon: Icons.close_rounded,
                          onTap: _handleClose,
                        ),
                        const SizedBox(width: 8),
                        _WindowDotButton(
                          color: const Color(0xFFFFBD2E),
                          icon: Icons.remove_rounded,
                          onTap: _handleMinimize,
                        ), // Animasyonlu küçülme
                        const SizedBox(width: 8),
                        _WindowDotButton(
                          color: const Color(0xFF27C93F),
                          icon: Icons.fullscreen_rounded,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // 2. Paylaştığın Görseldeki Buz Efektli Görev Çubuğu (Frosted Glass Dock)
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: _FrostedDock(onLaunch: _launchApp),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------- BUZ EFEKTLİ DOCK -------------------
class _FrostedDock extends StatelessWidget {
  final Function(String) onLaunch;
  const _FrostedDock({required this.onLaunch});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFF132225).withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DockItem(
                icon: Icons.folder_rounded,
                color: const Color(0xFF4CAF50),
                isRunning: true,
                onTap: () => onLaunch("explorer.exe"),
              ),
              _DockItem(
                icon: Icons.public_rounded,
                color: const Color(0xFFFF7043),
                isRunning: true,
                onTap: () => onLaunch("chrome.exe"),
              ),
              _DockItem(
                icon: Icons.code_rounded,
                color: const Color(0xFF29B6F6),
                isRunning: true,
                onTap: () => onLaunch("code"),
              ),
              _DockItem(
                icon: Icons.terminal_rounded,
                color: const Color(0xFF78909C),
                isRunning: false,
                onTap: () => onLaunch("wt.exe"),
              ),
              _DockItem(
                icon: Icons.tune_rounded,
                color: const Color(0xFF26A69A),
                isRunning: false,
                onTap: () {},
              ),
              Container(
                height: 24,
                width: 1,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                color: Colors.white24,
              ),
              _DockItem(
                icon: Icons.apps_rounded,
                color: Colors.white70,
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

// ------------------- DOCK İKONU VE HOVER HAREKETİ -------------------
class _DockItem extends StatefulWidget {
  final IconData icon;
  final Color color;
  final bool isRunning;
  final VoidCallback onTap;

  const _DockItem({
    required this.icon,
    required this.color,
    required this.isRunning,
    required this.onTap,
  });

  @override
  State<_DockItem> createState() => _DockItemState();
}

class _DockItemState extends State<_DockItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          transform: Matrix4.translationValues(0, _isHovered ? -6 : 0, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: _isHovered ? 44 : 38,
                height: _isHovered ? 44 : 38,
                decoration: BoxDecoration(
                  color: widget.color.withValues(
                    alpha: _isHovered ? 0.3 : 0.16,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _isHovered ? widget.color : Colors.white12,
                    width: 1,
                  ),
                ),
                child: Icon(
                  widget.icon,
                  color: widget.color,
                  size: _isHovered ? 24 : 20,
                ),
              ),
              const SizedBox(height: 3),
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

// ------------------- PENCERE KONTROL BUTONU -------------------
class _WindowDotButton extends StatefulWidget {
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _WindowDotButton({
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_WindowDotButton> createState() => _WindowDotButtonState();
}

class _WindowDotButtonState extends State<_WindowDotButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
          ),
          child: _hover
              ? Center(child: Icon(widget.icon, size: 8, color: Colors.black87))
              : null,
        ),
      ),
    );
  }
}
