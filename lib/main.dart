import 'package:flutter/material.dart';

import 'features/home/visitor_home.dart';
import 'shared/wonderla_palette.dart';

void main() => runApp(const WonderlaApp());

class WonderlaApp extends StatelessWidget {
  const WonderlaApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Wonderla Park Guide',
    debugShowCheckedModeBanner: false,
    theme: buildWonderlaTheme(),
    builder: (context, child) => DefaultTextStyle.merge(
      style: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 15,
        height: 1.45,
        letterSpacing: 0.03,
      ),
      child: child ?? const SizedBox.shrink(),
    ),
    home: const VisitorHome(),
  );
}

/// Kept as an alias for the project's existing widget-test entry point.
class WonderlaMapApp extends WonderlaApp {
  const WonderlaMapApp({super.key});
}
