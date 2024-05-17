import 'package:flutter/material.dart';
import 'package:map_box_application/ui/mapscreen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Map',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MapScreen(),
    );
  }
}
