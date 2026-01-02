import 'package:flutter/services.dart';
import 'package:lumina_gallery/screens/single_viewer_screen.dart';
import 'dart:io';
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
  static const platform = MethodChannel('com.pixel.gallery/open_file');
  static const eventChannel = EventChannel(
    'com.pixel.gallery/open_file_events',
  );
  String? _initialFilePath;

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    // Fetch user preference on startup (Material You enabled/disabled)
    _materialYouFuture = SettingsScreen.getMaterialYou();

    // Check initial file (cold start)
    _checkInitialFile();

    // Listen for new intent events while app is running (hot start)
    eventChannel.receiveBroadcastStream().listen(
      (event) {
        if (event is String) {
          debugPrint("Received new file intent: $event");
          // Directly navigate using the key, bypassing `setState` / `home` swap issues
          navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) =>
                  SingleViewerScreen(key: ValueKey(event), file: File(event)),
            ),
            (route) =>
                false, // Clear stack: Back button exits app or returns to Home?
            // Ideally we want Back -> Home? If so, push on top of Home.
            // But "getInitialFile" logic suggests SingleViewer is the ROOT if file exists.
            // Let's stick to "SingleViewer is the only screen" for this session to match standard gallery behavior.
          );
        }
      },
      onError: (dynamic error) {
        debugPrint('Received error: ${error.message}');
      },
    );
  }

  Future<void> _checkInitialFile() async {
    try {
      final String? filePath = await platform.invokeMethod('getInitialFile');
      if (filePath != null) {
        setState(() {
          _initialFilePath = filePath;
        });
      }
    } catch (e) {
      debugPrint("Error checking initial file: $e");
    }
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
          // Show loading screen while preferences are loading
          return const MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }

        final bool useMaterialYou = snapshot.data!;

        return DynamicColorBuilder(
          builder: (lightDynamic, darkDynamic) {
            return MaterialApp(
              navigatorKey: navigatorKey,
              title: 'Pixel Gallery',
              theme: ThemeData(
                // Use dynamic scheme if enabled and available, else fallback to deepPurple
                colorScheme: (useMaterialYou && lightDynamic != null)
                    ? lightDynamic
                    : ColorScheme.fromSeed(seedColor: Colors.deepPurple),
                useMaterial3: useMaterialYou,
              ),
              darkTheme: ThemeData(
                // Dark mode dynamic scheme
                colorScheme: (useMaterialYou && darkDynamic != null)
                    ? darkDynamic
                    : ColorScheme.fromSeed(
                        seedColor: Colors.deepPurple,
                        brightness: Brightness.dark,
                      ),
                useMaterial3: useMaterialYou,
              ),
              debugShowCheckedModeBanner: false,
              home: _initialFilePath != null
                  ? SingleViewerScreen(
                      key: ValueKey(
                        _initialFilePath,
                      ), // Force rebuild on new file
                      file: File(_initialFilePath!),
                    )
                  : HomeScreen(onThemeRefresh: _refreshTheme),
            );
          },
        );
      },
    );
  }
}
