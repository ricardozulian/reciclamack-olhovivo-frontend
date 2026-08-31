import 'package:flutter/material.dart';

import 'src/home_page.dart';
import 'src/reciclamack_theme.dart';
import 'src/totem_page.dart';

const String _appMode = String.fromEnvironment(
  'APP_MODE',
  defaultValue: 'web',
);

void main() {
  runApp(const ReciclaMackApp());
}

class ReciclaMackApp extends StatelessWidget {
  const ReciclaMackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReciclaMack',
      debugShowCheckedModeBanner: false,
      theme: buildReciclaMackTheme(),
      home: _appMode == 'totem' ? const TotemPage() : const HomePage(),
    );
  }
}
