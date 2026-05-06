import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        context.go('/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wallet_outlined,
              size: 100,
            )
                .animate()
                .fadeIn(duration: 1500.ms)
                .scale(begin: const Offset(0.8, 0.8)),
            const SizedBox(height: 24),
            Text(
              'Financier',
              style: GoogleFonts.oswald(
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            )
                .animate()
                .fadeIn(delay: 500.ms, duration: 1500.ms)
                .slideY(begin: 0.5),
          ],
        ),
      ),
    );
  }
}
 