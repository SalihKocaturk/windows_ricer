import 'package:equatable/equatable.dart';

class DashboardState extends Equatable {
  final bool isThemeActive;
  final double gapSize;
  final double borderRadius;
  final String selectedTheme;

  const DashboardState({
    this.isThemeActive = false,
    this.gapSize = 10.0,
    this.borderRadius = 12.0,
    this.selectedTheme = "Tiling Manager (Teal)",
  });

  DashboardState copyWith({
    bool? isThemeActive,
    double? gapSize,
    double? borderRadius,
    String? selectedTheme,
  }) {
    return DashboardState(
      isThemeActive: isThemeActive ?? this.isThemeActive,
      gapSize: gapSize ?? this.gapSize,
      borderRadius: borderRadius ?? this.borderRadius,
      selectedTheme: selectedTheme ?? this.selectedTheme,
    );
  }

  @override
  List<Object> get props => [
    isThemeActive,
    gapSize,
    borderRadius,
    selectedTheme,
  ];
}
