import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; 
import 'screens/chat_screen.dart';


// Добавляем async, так как загрузка файла - асинхронная операция
Future<void> main() async {
  // Гарантируем инициализацию движка Flutter
  WidgetsFlutterBinding.ensureInitialized();
  
  // Загружаем ключи из файла .env
  // Если файла нет, создаем пустой map, чтобы приложение не упало
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Внимание: Файл .env не найден. Используются пустые ключи.");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: 'AI Agent Chat',
          debugShowCheckedModeBanner: false,
          
          // --- СВЕТЛАЯ ТЕМА ---
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent, // Убираем оттенок при скролле
            ),
          ),

          // --- ТЕМНАЯ ТЕМА ---
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.red,
              brightness: Brightness.dark,
              surface: const Color(0xFF1E1E1E), // Цвет поверхностей (карточек)
            ),
            scaffoldBackgroundColor: const Color(0xFF121212), // Основной фон (темно-серый)
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF121212),
              surfaceTintColor: Colors.transparent,
            ),
          ),
          
          themeMode: currentMode,
          home: const ChatScreen(),
        );
      },
    );
  }
}