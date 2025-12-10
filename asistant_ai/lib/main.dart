import 'package:flutter/material.dart';
import 'screens/chat_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Глобальный контроллер темы
  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: 'AI Agent Chat',
          debugShowCheckedModeBanner: false,
          // Светлая тема
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            useMaterial3: true,
            brightness: Brightness.light,
          ),
          // Темная тема
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color.fromARGB(255, 92, 8, 2), 
              brightness: Brightness.dark
            ),
            useMaterial3: true,
            brightness: Brightness.dark,
          ),
          themeMode: currentMode, // Текущий режим
          home: const ChatScreen(),
        );
      },
    );
  }
}