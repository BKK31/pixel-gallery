import 'package:flutter/material.dart';
import 'package:lumina_gallery/screens/home_screen.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<bool> _materialYouFuture;

  @override
  void initState() {
    super.initState();
    _materialYouFuture = SettingsScreen.getMaterialYou();
  }

  void _refreshTheme() {
    setState(() {
      _materialYouFuture = SettingsScreen.getMaterialYou();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _materialYouFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }

        final bool useMaterialYou = snapshot.data!;

        return DynamicColorBuilder(
          builder: (lightDynamic, darkDynamic) {
            return MaterialApp(
              theme: ThemeData(
                colorScheme: (useMaterialYou && lightDynamic != null)
                    ? lightDynamic
                    : ColorScheme.fromSeed(seedColor: Colors.deepPurple),
                useMaterial3: useMaterialYou,
              ),
              darkTheme: ThemeData(
                colorScheme: (useMaterialYou && darkDynamic != null)
                    ? darkDynamic
                    : ColorScheme.fromSeed(
                        seedColor: Colors.deepPurple,
                        brightness: Brightness.dark,
                      ),
                useMaterial3: useMaterialYou,
              ),
              debugShowCheckedModeBanner: false,
              home: HomeScreen(onThemeRefresh: _refreshTheme),
            );
          },
        );
      },
    );
  }
}
