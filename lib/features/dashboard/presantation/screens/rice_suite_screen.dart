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
  int _glassType = 1; // 0: Şeffaf, 1: Buzlu Cam (Acrylic), 2: Bulanık (Blur)
  double _opacity = 0.35;
  bool _isIsland = true;
  double _radius = 16.0;
  double _margin = 40.0;
  double _bottomMargin = 4.0;

  void _sync({
    bool? active,
    int? glass,
    double? op,
    bool? island,
    double? rad,
    double? mar,
    double? bot,
  }) async {
    final nActive = active ?? _isActive;
    final nGlass = glass ?? _glassType;
    final nOp = op ?? _opacity;
    final nIsland = island ?? _isIsland;
    final nRad = rad ?? _radius;
    final nMar = mar ?? _margin;
    final nBot = bot ?? _bottomMargin;

    setState(() {
      _isActive = nActive;
      _glassType = nGlass;
      _opacity = nOp;
      _isIsland = nIsland;
      _radius = nRad;
      _margin = nMar;
      _bottomMargin = nBot;
    });

    try {
      await platform.invokeMethod('updateTaskbarStyle', {
        'isActive': nActive,
        'glassType': nGlass,
        'opacity': nOp,
        'isIsland': nIsland,
        'radius': nRad,
        'margin': nMar,
        'bottomMargin': nBot,
      });
    } catch (e) {
      print("Stil hatası: $e");
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
                    Icons.blur_linear_rounded,
                    color: Color(0xFF1DE9B6),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "WinRicer — Görev Çubuğu Cam & Ada Stüdyosu",
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
                                  ? "CAM EFEKTİ: AKTİF"
                                  : "CAM EFEKTİ: KAPALI",
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
                                  ? "Buzlu cam dokusu görev çubuğuna uygulandı."
                                  : "Windows mat görev çubuğu devrede.",
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
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "CAM EFEKTİ TÜRÜ",
                                style: TextStyle(
                                  color: Color(0xFF1DE9B6),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 10),

                              Row(
                                children: [
                                  Expanded(
                                    child: _GlassCard(
                                      title: "Buzlu Cam",
                                      sub: "Acrylic",
                                      isSelected: _glassType == 1,
                                      onTap: () => _sync(glass: 1),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _GlassCard(
                                      title: "Şeffaf",
                                      sub: "Clear",
                                      isSelected: _glassType == 0,
                                      onTap: () => _sync(glass: 0),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _GlassCard(
                                      title: "Bulanık",
                                      sub: "Blur",
                                      isSelected: _glassType == 2,
                                      onTap: () => _sync(glass: 2),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Cam Opaklığı (Koyuluk):",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    "%${(_opacity * 100).toInt()}",
                                    style: const TextStyle(
                                      color: Color(0xFF1DE9B6),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Slider(
                                value: _opacity,
                                min: 0.0,
                                max: 0.8,
                                activeColor: const Color(0xFF1DE9B6),
                                onChanged: (v) => _sync(op: v),
                              ),

                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                title: const Text(
                                  "Kavisli Ada Şekli (Rounded Island)",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: const Text(
                                  "Kapalıyken tam ekran şeffaf cam olur.",
                                  style: TextStyle(
                                    color: Colors.white38,
                                    fontSize: 10,
                                  ),
                                ),
                                value: _isIsland,
                                activeThumbColor: const Color(0xFF1DE9B6),
                                onChanged: (v) => _sync(island: v),
                              ),

                              if (_isIsland) ...[
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "Köşe Kavisi:",
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
                                  max: 24,
                                  activeColor: const Color(0xFF1DE9B6),
                                  onChanged: (v) => _sync(rad: v),
                                ),

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
                                  max: 120,
                                  activeColor: const Color(0xFF1DE9B6),
                                  onChanged: (v) => _sync(mar: v),
                                ),
                              ],
                            ],
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

class _GlassCard extends StatelessWidget {
  final String title;
  final String sub;
  final bool isSelected;
  final VoidCallback onTap;
  const _GlassCard({
    required this.title,
    required this.sub,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1DE9B6).withValues(alpha: 0.2)
              : Colors.black26,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF1DE9B6) : Colors.white12,
            width: 1.2,
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected ? const Color(0xFF1DE9B6) : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              style: const TextStyle(color: Colors.white38, fontSize: 9),
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
