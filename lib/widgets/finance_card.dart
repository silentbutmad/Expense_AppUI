import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:myapp/models/finance_card_model.dart';
import 'package:myapp/theme/app_tokens.dart';
import 'package:myapp/widgets/mini_sparkline.dart';

class FinanceCard extends StatefulWidget {
  final FinanceCardModel card;
  final VoidCallback onTap;

  const FinanceCard({super.key, required this.card, required this.onTap});

  @override
  State<FinanceCard> createState() => _FinanceCardState();
}

class _FinanceCardState extends State<FinanceCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    // The Hero widget needs a Material widget ancestor for smooth transitions.
    // By wrapping the Card in a Material widget, we prevent visual glitches.
    return Hero(
      tag: 'finance_card_${widget.card.id}',
      child: Material(
        type: MaterialType.transparency,
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedContainer(
            duration: AppTokens.animationFast,
            transform: Matrix4.identity()..scale(_isHovered ? 1.05 : 1.0),
            transformAlignment: Alignment.center,
            child: Card(
              elevation: _isHovered ? AppTokens.elevation * 2 : AppTokens.elevation,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTokens.radius),
              ),
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(AppTokens.radius),
                child: Container(
                  padding: const EdgeInsets.all(AppTokens.padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.card.title,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: widget.card.value),
                        duration: AppTokens.animationMedium,
                        builder: (context, val, _) => Text(
                          '\u20b9${val.toStringAsFixed(2)}',
                          style: textTheme.headlineSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: MiniSparkline(
                          values: widget.card.history,
                          color: colorScheme.secondary,
                        ),
                      ),
                    ],                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ).animate().fade(duration: 500.ms).slideX(begin: 0.2, end: 0);
  }
}
