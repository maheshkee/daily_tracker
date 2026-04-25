import 'package:flutter/material.dart';
import 'screens/main_layout.dart';

void main() {
  runApp(const DailySystemV2());
}

class DailySystemV2 extends StatelessWidget {
  const DailySystemV2({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily System V2',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        primaryColor: const Color(0xFFBB86FC),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFBB86FC),
          secondary: Color(0xFF03DAC6),
          surface: Color(0xFF1E1E1E),
        ),
        useMaterial3: true,
      ),
      home: const MainLayout(),
    );
  }
}
