import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'features/dashboard/cubit/dashboard_cubit.dart';
// Yeni ekranımızın import'u:
import 'features/dashboard/presantation/screens/rice_suite_screen.dart';
// İstersen eski ekran da dursun:
// import 'features/dashboard/presantation/screens/dashboard_screen.dart';

void main() {
  runApp(const WindowsRicerApp());
}

class WindowsRicerApp extends StatelessWidget {
  const WindowsRicerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WinRicer',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF1DE9B6),
          surface: Color(0xFF121E1E),
        ),
        useMaterial3: true,
      ),
      home: BlocProvider(
        create: (context) => DashboardCubit(),
        // Doğrudan yeni Unixporn/Waybar ekranımızla başlatıyoruz:
        child: const RiceSuiteScreen(),
      ),
    );
  }
}
