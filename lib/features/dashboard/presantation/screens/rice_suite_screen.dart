import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubit/dashboard_cubit.dart';
import '../../cubit/dashboard_state.dart';

class RiceSuiteScreen extends StatefulWidget {
  const RiceSuiteScreen({super.key});

  @override
  State<RiceSuiteScreen> createState() => _RiceSuiteScreenState();
}

class _RiceSuiteScreenState extends State<RiceSuiteScreen> {
  String _currentTime = "";
  int _selectedWorkspace = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        final cubit = context.read<DashboardCubit>();

        return Scaffold(
          backgroundColor: const Color(0xFF0C1414).withValues(alpha: 0.95),
          body: Column(
            children: [
              // 1. Waybar Style Top Status Bar
              Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF112020),
                  border: Border(
                    bottom: BorderSide(
                      color: const Color(0xFF1de9b6).withValues(alpha: 0.12),
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
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF1de9b6)
                                  : Colors.black38,
                              borderRadius: BorderRadius.circular(10),
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
                    // Media & Clock Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.music_note_rounded,
                            color: Color(0xFF1de9b6),
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            "Lyn - No More What Ifs",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _currentTime,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Sağ: macOS Butonları
                    Row(
                      children: [
                        _macDot(const Color(0xFFFF5F56), cubit.closeWindow),
                        const SizedBox(width: 8),
                        _macDot(const Color(0xFFFFBD2E), cubit.minimizeWindow),
                        const SizedBox(width: 8),
                        _macDot(const Color(0xFF27C93F), cubit.toggleTheme),
                      ],
                    ),
                  ],
                ),
              ),

              // 2. Main Control Grid
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      // Tiling Control Card
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF132222),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(
                                0xFF1de9b6,
                              ).withValues(alpha: 0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "TILING ENGINE",
                                style: TextStyle(
                                  color: Color(0xFF1de9b6),
                                  fontSize: 11,
                                  letterSpacing: 1.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Center(
                                child: IconButton(
                                  iconSize: 68,
                                  icon: Icon(
                                    Icons.power_settings_new_rounded,
                                    color: state.isThemeActive
                                        ? const Color(0xFF1de9b6)
                                        : Colors.white24,
                                  ),
                                  onPressed: cubit.toggleTheme,
                                ),
                              ),
                              Center(
                                child: Text(
                                  state.isThemeActive ? "Aktif" : "Devre Dışı",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.black26,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.keyboard_command_key_rounded,
                                      color: Color(0xFF1de9b6),
                                      size: 16,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      "Alt + Shift + T",
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Geometry & Metrics Card
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF132222),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(
                                0xFF1de9b6,
                              ).withValues(alpha: 0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "GEOMETRY METRICS",
                                style: TextStyle(
                                  color: Color(0xFF1de9b6),
                                  fontSize: 11,
                                  letterSpacing: 1.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                "Boşluk (Gaps): ${state.gapSize.toInt()}px",
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                              Slider(
                                value: state.gapSize,
                                min: 0,
                                max: 40,
                                activeColor: const Color(0xFF1de9b6),
                                onChanged: cubit.updateGapSize,
                              ),
                              const SizedBox(height: 14),
                              Text(
                                "Köşe (Radius): ${state.borderRadius.toInt()}px",
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                              Slider(
                                value: state.borderRadius,
                                min: 0,
                                max: 24,
                                activeColor: const Color(0xFF1de9b6),
                                onChanged: cubit.updateBorderRadius,
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
        );
      },
    );
  }

  Widget _macDot(Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
