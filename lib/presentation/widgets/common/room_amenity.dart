import 'package:flutter/material.dart';

class RoomAmenity extends StatelessWidget {
  final IconData icon;
  final String? value;
  final String? unit;
  final Color color;
  const RoomAmenity({super.key, required this.icon, this.value, required this.color, this.unit});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 2),
        unit != null && value != null ? Text(
          '$value $unit',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ) : const SizedBox.shrink(),
      ],
    );
  }
}
