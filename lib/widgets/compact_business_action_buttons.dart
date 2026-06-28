import 'package:flutter/material.dart';

class CompactBusinessActionButtons extends StatelessWidget {
  final VoidCallback onAddTransaction;
  final VoidCallback onAddParty;
  final VoidCallback onAddItem;

  const CompactBusinessActionButtons({
    super.key,
    required this.onAddTransaction,
    required this.onAddParty,
    required this.onAddItem,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _CompactBusinessActionButton(
            label: 'Add Transaction',
            icon: Icons.add,
            color: theme.colorScheme.primary,
            onPressed: onAddTransaction,
          ),
          _CompactBusinessActionButton(
            label: 'Add Party',
            icon: Icons.person_add,
            color: Colors.green,
            onPressed: onAddParty,
          ),
          _CompactBusinessActionButton(
            label: 'Add Item',
            icon: Icons.inventory_2,
            color: Colors.orange,
            onPressed: onAddItem,
          ),
        ],
      ),
    );
  }
}

class _CompactBusinessActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _CompactBusinessActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}