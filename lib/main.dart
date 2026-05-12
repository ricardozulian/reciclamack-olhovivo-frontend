import 'package:flutter/material.dart';

import 'src/home_page.dart';
import 'src/reciclamack_theme.dart';

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
      home: const HomePage(),
    );
  }
}