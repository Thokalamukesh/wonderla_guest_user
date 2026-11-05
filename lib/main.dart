import 'package:flutter/material.dart';

import 'features/home/visitor_home.dart';

void main() => runApp(const WonderlaApp());

class WonderlaApp extends StatelessWidget {
  const WonderlaApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Wonderla Park Guide',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xfff1f5fb),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xff1746a2),
        primary: const Color(0xff1746a2),
        secondary: const Color(0xffffcf20),
      ),
      fontFamily: 'Roboto',
    ),
    home: const VisitorHome(),
  );
}

/// Kept as an alias for the project's existing widget-test entry point.
class WonderlaMapApp extends WonderlaApp {
  const WonderlaMapApp({super.key});
}
