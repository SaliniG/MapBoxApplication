import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:map_box_application/bloc/map_bloc.dart';
import 'package:map_box_application/ui/mapscreen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<MyAppState>()!;

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  bool get isDark => _themeMode == ThemeMode.dark;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MapBloc(),
      child: MaterialApp(
        title: 'Map',
        theme: ThemeData(primarySwatch: Colors.blue, brightness: Brightness.light),
        darkTheme: ThemeData(primarySwatch: Colors.blue, brightness: Brightness.dark),
        themeMode: _themeMode,
        home: const MapScreen(),
      ),
    );
  }
}
