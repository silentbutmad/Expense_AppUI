import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/firebase_options.dart';
import 'package:myapp/models/expense_model.dart';
import 'package:myapp/providers/expense_provider.dart';
import 'package:myapp/providers/theme_provider.dart';
import 'package:myapp/screens/add_expense_screen.dart';
import 'package:myapp/screens/add_income_screen.dart';
import 'package:myapp/screens/expense_detail_screen.dart';
import 'package:myapp/screens/forgot_password_screen.dart';
import 'package:myapp/screens/home_screen.dart';
import 'package:myapp/screens/login_screen.dart';
import 'package:myapp/screens/ocr_screen.dart';
import 'package:myapp/screens/otp_screen.dart';
import 'package:myapp/screens/personal_tab_screen.dart' show PersonalTabContent;
import 'package:myapp/screens/profile_screen.dart';
import 'package:myapp/screens/register_screen.dart';
import 'package:myapp/screens/reports_screen.dart';
import 'package:myapp/screens/reset_password_screen.dart';
import 'package:myapp/screens/settings_screen.dart';
import 'package:myapp/screens/splash_screen.dart';
import 'package:myapp/screens/success_screen.dart';
import 'package:myapp/theme/app_theme.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = GoRouter(
      initialLocation: '/splash',
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/reports',
          builder: (context, state) => const ReportsScreen(),
        ),
        GoRoute(
          path: '/add-expense',
          builder: (context, state) {
            final extra = state.extra;
            if (extra is Map) {
              final isBusiness = extra['isBusiness'] as bool? ?? false;
              final transactionType = extra['transactionType'] as TransactionType?;
              final personName = extra['personName'] as String?;
              final transactionCategory = extra['transactionCategory'] as TransactionCategory?;
              return AddExpenseScreen(
                isBusiness: isBusiness,
                transactionType: transactionType,
                personName: personName,
                transactionCategory: transactionCategory,
              );
            }
            final isBusiness = extra as bool? ?? false;
            return AddExpenseScreen(isBusiness: isBusiness);
          },
        ),
        GoRoute(
          path: '/add-income',
          builder: (context, state) {
            final isBusiness = state.extra as bool? ?? false;
            return AddIncomeScreen(isBusiness: isBusiness);
          },
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/expense-details',
          builder: (context, state) => const ExpenseDetailScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/reset-password',
          builder: (context, state) {
            final email = (state.extra as Map)['email'];
            return ResetPasswordScreen(email: email);
          },
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/ocr',
          builder: (context, state) => const OcrScreen(),
        ),
        GoRoute(
          path: '/otp',
          builder: (context, state) {
            final email = (state.extra as Map)['email'];
            return OtpScreen(email: email);
          },
        ),
        GoRoute(
          path: '/personal',
          builder: (context, state) => const PersonalTabContent(),
        ),
        GoRoute(
          path: '/success',
          builder: (context, state) {
            final message = state.uri.queryParameters['message'] ?? 'Success!';
            final buttonText = state.uri.queryParameters['buttonText'] ?? 'Continue';
            final routeName = state.uri.queryParameters['routeName'] ?? '/';
            return SuccessScreen(
              message: message,
              buttonText: buttonText,
              routeName: routeName,
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp.router(
            title: 'Flutter Material AI App',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            routerConfig: _router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
