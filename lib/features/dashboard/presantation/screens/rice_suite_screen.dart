import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RiceSuiteScreen extends StatefulWidget {
  const RiceSuiteScreen({super.key});

  @override
  State<RiceSuiteScreen> createState() => _RiceSuiteScreenState();
}

class _RiceSuiteScreenState extends State<RiceSuiteScreen> {
  static const platform = MethodChannel('winricer/window_manager');

  bool _isActive = false;
  double _height = 64.0; // Görev Çubuğu Boyuna Yükseklik (48 -> 64)
  double _radius = 18.0; // Köşe Kavisi
  double _margin = 60.0; // Sağdan/Soldan Boşluk

  void _sync({
    bool? active,
    double? height,
    double? radius,
    double? margin,
  }) async {
    final nActive = active ?? _isActive;
    final nHeight = height ?? _height;
    final nRadius = radius ?? _radius;
    final nMargin = margin ?? _margin;

    setState(() {
      _isActive = nActive;
      _height = nHeight;
      _radius = nRadius;
      _margin = nMargin;
    });

    try {
      await platform.invokeMethod('applyTaskbarHook', {
        'isActive': nActive,
        'height': nHeight,
        'radius': nRadius,
        'margin': nMargin,
      });
    } catch (e) {
      print("Kanca hatası: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0C1416).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF1DE9B6).withValues(alpha: 0.22),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 32,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.tune_rounded,
                    color: Color(0xFF1DE9B6),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "WinRicer — Dahili XAML Görev Çubuğu Motoru",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const Spacer(),
                  _MacButton(
                    color: const Color(0xFFFF5F56),
                    icon: Icons.close_rounded,
                    onTap: () => platform.invokeMethod('closeApp'),
                  ),
                  const SizedBox(width: 8),
                  _MacButton(
                    color: const Color(0xFFFFBD2E),
                    icon: Icons.remove_rounded,
                    onTap: () => platform.invokeMethod('minimizeApp'),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white10, height: 1),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    // Sol: Ana Açma/Kapama Butonu
                    Expanded(
                      flex: 4,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF122022),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () => _sync(active: !_isActive),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _isActive
                                      ? const Color(
                                          0xFF1DE9B6,
                                        ).withValues(alpha: 0.18)
                                      : Colors.white.withValues(alpha: 0.04),
                                  border: Border.all(
                                    color: _isActive
                                        ? const Color(0xFF1DE9B6)
                                        : Colors.white24,
                                    width: 3,
                                  ),
                                  boxShadow: _isActive
                                      ? [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF1DE9B6,
                                            ).withValues(alpha: 0.4),
                                            blurRadius: 28,
                                            spreadRadius: 3,
                                          ),
                                        ]
                                      : [],
                                ),
                                child: Icon(
                                  Icons.power_settings_new_rounded,
                                  size: 56,
                                  color: _isActive
                                      ? const Color(0xFF1DE9B6)
                                      : Colors.white30,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _isActive
                                  ? "DAHİLİ KANCA: AKTİF"
                                  : "DAHİLİ KANCA: KAPALI",
                              style: TextStyle(
                                color: _isActive
                                    ? const Color(0xFF1DE9B6)
                                    : Colors.white54,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _isActive
                                  ? "XAML yükseklik ve kavis kancası devrede."
                                  : "Windows orijinal ayarları devrede.",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),

                    // Sağ: Yükseklik ve Kavis Ayarları
                    Expanded(
                      flex: 7,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF122022),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "GÖREV ÇUBUĞU BOYUT VE KAVİS AYARI",
                              style: TextStyle(
                                color: Color(0xFF1DE9B6),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Yükseklik (Height) Slider
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Bar Yüksekliği (Height):",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  "${_height.toInt()} px",
                                  style: const TextStyle(
                                    color: Color(0xFF1DE9B6),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Slider(
                              value: _height,
                              min: 48,
                              max: 84,
                              activeColor: const Color(0xFF1DE9B6),
                              onChanged: (v) => _sync(height: v),
                            ),
                            const SizedBox(height: 12),

                            // Köşe Kavisi (Radius) Slider
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Köşe Kavisi (Radius):",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  "${_radius.toInt()} px",
                                  style: const TextStyle(
                                    color: Color(0xFF1DE9B6),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Slider(
                              value: _radius,
                              min: 4,
                              max: 32,
                              activeColor: const Color(0xFF1DE9B6),
                              onChanged: (v) => _sync(radius: v),
                            ),
                            const SizedBox(height: 12),

                            // Kenar Boşluğu (Margin) Slider
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Kenar Boşluğu (Margin):",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  "${_margin.toInt()} px",
                                  style: const TextStyle(
                                    color: Color(0xFF1DE9B6),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Slider(
                              value: _margin,
                              min: 0,
                              max: 160,
                              activeColor: const Color(0xFF1DE9B6),
                              onChanged: (v) => _sync(margin: v),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MacButton extends StatefulWidget {
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  const _MacButton({
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_MacButton> createState() => _MacButtonState();
}

class _MacButtonState extends State<_MacButton> {
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
