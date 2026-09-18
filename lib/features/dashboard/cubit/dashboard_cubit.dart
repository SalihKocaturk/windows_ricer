import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit() : super(const DashboardState()) {
    platform.setMethodCallHandler((call) async {
      if (call.method == 'onHotkeyPressed') {
        toggleTheme();
      }
    });
  }

  static const platform = MethodChannel('winricer/window_manager');

  Future<void> closeWindow() async => await platform.invokeMethod('closeApp');
  Future<void> minimizeWindow() async =>
      await platform.invokeMethod('minimizeApp');

  Future<void> _invoke() async {
    try {
      await platform.invokeMethod('updateWindows', {
        'isActive': state.isThemeActive,
        'gap': state.gapSize,
        'radius': state.borderRadius,
      });
    } on PlatformException catch (e) {
      print("WinRicer C++ Hatası: ${e.message}");
    }
  }

  Future<void> toggleTheme() async {
    emit(state.copyWith(isThemeActive: !state.isThemeActive));
    await _invoke();
  }

  void updateGapSize(double value) async {
    emit(state.copyWith(gapSize: value));
    if (state.isThemeActive) await _invoke();
  }

  void updateBorderRadius(double value) async {
    emit(state.copyWith(borderRadius: value));
    if (state.isThemeActive) await _invoke();
  }

  void selectTheme(String theme) => emit(state.copyWith(selectedTheme: theme));
}
