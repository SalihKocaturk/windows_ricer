import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RiceSuiteScreen extends StatefulWidget {
  const RiceSuiteScreen({super.key});

  @override
  State<RiceSuiteScreen> createState() => _RiceSuiteScreenState();
}

class _RiceSuiteScreenState extends State<RiceSuiteScreen> {
  static const platform = MethodChannel('winricer/window_manager');

  bool _isThemeActive = false;
  double _radius = 18.0;
  double _margin = 90.0;

  void _syncTaskbar({bool? active, double? radius, double? margin}) async {
    final newActive = active ?? _isThemeActive;
    final newRadius = radius ?? _radius;
    final newMargin = margin ?? _margin;

    setState(() {
      _isThemeActive = newActive;
      _radius = newRadius;
      _margin = newMargin;
    });

    try {
      await platform.invokeMethod('updateRoundedTaskbar', {
        'isActive': newActive,
        'radius': newRadius,
        'margin': newMargin,
      });
    } catch (e) {
      print("Görev çubuğu güncellenemedi: $e");
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
            // 1. Üst Bar ve Pencere Kontrolleri
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  const Icon(
                    Icons.rounded_corner_rounded,
                    color: Color(0xFF1DE9B6),
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "WinRicer — RoundedTB Ada Görev Çubuğu",
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

            // 2. Ana Dashboard Alanı
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Row(
                  children: [
                    // Sol Taraf: Büyük Güç Butonu
                    Expanded(
                      flex: 5,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF122022),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () =>
                                  _syncTaskbar(active: !_isThemeActive),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                width: 125,
                                height: 125,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _isThemeActive
                                      ? const Color(
                                          0xFF1DE9B6,
                                        ).withValues(alpha: 0.18)
                                      : Colors.white.withValues(alpha: 0.04),
                                  border: Border.all(
                                    color: _isThemeActive
                                        ? const Color(0xFF1DE9B6)
                                        : Colors.white24,
                                    width: 3.2,
                                  ),
                                  boxShadow: _isThemeActive
                                      ? [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF1DE9B6,
                                            ).withValues(alpha: 0.4),
                                            blurRadius: 30,
                                            spreadRadius: 3,
                                          ),
                                        ]
                                      : [],
                                ),
                                child: Icon(
                                  Icons.power_settings_new_rounded,
                                  size: 64,
                                  color: _isThemeActive
                                      ? const Color(0xFF1DE9B6)
                                      : Colors.white30,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              _isThemeActive
                                  ? "ADA GÖREV ÇUBUĞU: AKTİF"
                                  : "ADA GÖREV ÇUBUĞU: KAPALI",
                              style: TextStyle(
                                color: _isThemeActive
                                    ? const Color(0xFF1DE9B6)
                                    : Colors.white54,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isThemeActive
                                  ? "Windows görev çubuğu kenarlardan kesilerek yüzen kavisli bir adaya dönüştürüldü."
                                  : "Windows orijinal tam ekran görev çubuğu devrede.",
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
                    const SizedBox(width: 24),

                    // Sağ Taraf: Kavis ve Ada Boyut Ayarları
                    Expanded(
                      flex: 6,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF122022),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "ADA ŞEKLİ & GEOMETRİ AYARLARI",
                              style: TextStyle(
                                color: Color(0xFF1DE9B6),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Radius Slider
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Köşe Kavisi (Radius):",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
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
                              max: 28,
                              activeColor: const Color(0xFF1DE9B6),
                              onChanged: (val) => _syncTaskbar(radius: val),
                            ),
                            const SizedBox(height: 16),

                            // Margin Slider (Sağdan ve Soldan Kırpma)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Kenar Boşluğu (Margin):",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
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
                              min: 20,
                              max: 300,
                              activeColor: const Color(0xFF1DE9B6),
                              onChanged: (val) => _syncTaskbar(margin: val),
                            ),
                            const SizedBox(height: 16),

                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.tips_and_updates_rounded,
                                    color: Color(0xFF1DE9B6),
                                    size: 16,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "Slider'ları hareket ettirdiğinde Windows görev çubuğu anlık olarak daralıp yuvarlanır.",
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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
          width: 13,
          height: 13,
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
