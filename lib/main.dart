import 'package:audio_player/pages/HomePage.dart';
import 'package:audio_player/pages/audioPage.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Audio player',
      theme: ThemeData(
        fontFamily: 'Folks',
        useMaterial3: false,
      ),
      home: const HomePage(),
    );
  }
}
