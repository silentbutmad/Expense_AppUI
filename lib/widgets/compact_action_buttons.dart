import 'package:flutter/material.dart';

class CompactActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const CompactActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CompactActionButtons extends StatelessWidget {
  final List<CompactActionButtonData> buttons;

  const CompactActionButtons({
    super.key,
    required this.buttons,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: buttons.asMap().entries.map((entry) {
        final index = entry.key;
        final button = entry.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index < buttons.length - 1 ? 6 : 0,
            ),
            child: CompactActionButton(
              label: button.label,
              icon: button.icon,
              color: button.color,
              onPressed: button.onPressed,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class CompactActionButtonData {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const CompactActionButtonData({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });
}