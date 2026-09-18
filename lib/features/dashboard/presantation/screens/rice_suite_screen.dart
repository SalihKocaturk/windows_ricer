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
  double _radius = 18.0;
  double _margin = 40.0;
  double _bottomMargin = 4.0;
  bool _searchButtonOnly = true;

  void _sync({bool? active, double? rad, double? mar, double? bot}) async {
    final nActive = active ?? _isActive;
    final nRad = rad ?? _radius;
    final nMar = mar ?? _margin;
    final nBot = bot ?? _bottomMargin;

    setState(() {
      _isActive = nActive;
      _radius = nRad;
      _margin = nMar;
      _bottomMargin = nBot;
    });

    try {
      await platform.invokeMethod('updateTaskbarGeometry', {
        'isActive': nActive,
        'radius': nRad,
        'margin': nMar,
        'bottomMargin': nBot,
      });
    } catch (_) {}
  }

  void _toggleSearch(bool val) async {
    setState(() => _searchButtonOnly = val);
    try {
      await platform.invokeMethod('setSearchButton', {'iconOnly': val});
    } catch (_) {}
  }

  void _restartExplorer() async {
    try {
      await platform.invokeMethod('restartExplorer');
    } catch (_) {}
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
                    Icons.rounded_corner_rounded,
                    color: Color(0xFF1DE9B6),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "WinRicer — Ada Görev Çubuğu & Arama Yöneticisi",
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
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    // Sol: Güç Butonu
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
                                width: 105,
                                height: 105,
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
                                  size: 54,
                                  color: _isActive
                                      ? const Color(0xFF1DE9B6)
                                      : Colors.white30,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _isActive
                                  ? "ADA MODU: AKTİF"
                                  : "ADA MODU: KAPALI",
                              style: TextStyle(
                                color: _isActive
                                    ? const Color(0xFF1DE9B6)
                                    : Colors.white54,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: _restartExplorer,
                              icon: const Icon(
                                Icons.refresh_rounded,
                                size: 14,
                                color: Color(0xFF1DE9B6),
                              ),
                              label: const Text(
                                "Explorer'ı Yenile",
                                style: TextStyle(
                                  color: Color(0xFF1DE9B6),
                                  fontSize: 11,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: const Color(
                                    0xFF1DE9B6,
                                  ).withValues(alpha: 0.4),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),

                    // Sağ: Ayarlar
                    Expanded(
                      flex: 7,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF122022),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Material(
                          type: MaterialType.transparency,
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "GÖREV ÇUBUĞU ÖZELLEŞTİRMELERİ",
                                  style: TextStyle(
                                    color: Color(0xFF1DE9B6),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Arama Butonu Anahtarı
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                  title: const Text(
                                    "Kompakt Arama Butonu",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: const Text(
                                    "Uzun arama çubuğunu tek bir büyüteç butonuna çevirir.",
                                    style: TextStyle(
                                      color: Colors.white38,
                                      fontSize: 10,
                                    ),
                                  ),
                                  value: _searchButtonOnly,
                                  activeThumbColor: const Color(0xFF1DE9B6),
                                  onChanged: _toggleSearch,
                                ),

                                const Divider(
                                  color: Colors.white12,
                                  height: 16,
                                ),
                                const Text(
                                  "KAVİS VE ADA GEOMETRİSİ",
                                  style: TextStyle(
                                    color: Color(0xFF1DE9B6),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Radius Slider
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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
                                  max: 26,
                                  activeColor: const Color(0xFF1DE9B6),
                                  onChanged: (v) => _sync(rad: v),
                                ),

                                // Margin Slider
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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
                                  onChanged: (v) => _sync(mar: v),
                                ),

                                // Bottom Margin (Yerden Yükseklik)
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "Yerden Yükseklik (Float):",
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      "${_bottomMargin.toInt()} px",
                                      style: const TextStyle(
                                        color: Color(0xFF1DE9B6),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Slider(
                                  value: _bottomMargin,
                                  min: 0,
                                  max: 12,
                                  activeColor: const Color(0xFF1DE9B6),
                                  onChanged: (v) => _sync(bot: v),
                                ),
                              ],
                            ),
                          ),
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
