import 'package:flutter/material.dart';

import 'theme/app_theme.dart';

import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const SmartBankAI(),
  );
}

class SmartBankAI extends StatelessWidget {
  const SmartBankAI({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'SmartBank AI',

      theme: AppTheme.lightTheme,

      darkTheme: ThemeData.dark(),

      themeMode: ThemeMode.system,

      home: const SplashScreen(),
    );
  }
}