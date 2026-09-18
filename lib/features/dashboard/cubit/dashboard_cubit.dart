import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit() : super(const DashboardState());

  static const platform = MethodChannel('winricer/window_manager');

  Future<void> closeWindow() async {
    try {
      await platform.invokeMethod('closeApp');
    } catch (_) {}
  }

  Future<void> minimizeWindow() async {
    try {
      await platform.invokeMethod('minimizeApp');
    } catch (_) {}
  }

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

  void updateGapSize(double value) {
    emit(state.copyWith(gapSize: value));
  }

  void updateBorderRadius(double value) {
    emit(state.copyWith(borderRadius: value));
  }

  void selectTheme(String theme) => emit(state.copyWith(selectedTheme: theme));
}
