import 'package:flutter/material.dart';

class SettingsSlider extends StatelessWidget {
  final String label;
  final double value;
  final Function(double)? onChanged;

  const SettingsSlider({
    super.key,
    required this.label,
    required this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(flex: 2, child: Text(label)),
        Expanded(
          flex: 4,
          child: Slider(value: value, min: 0, max: 30, onChanged: onChanged),
        ),
        SizedBox(
          width: 30, // Sağa yaslanması ve sabit durması için genişlik verdik
          child: Text(value.toInt().toString()),
        ),
      ],
    );
  }
}
