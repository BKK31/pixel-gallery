import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:lumina_gallery/screens/home_screen.dart';
import 'package:lumina_gallery/screens/single_viewer_screen.dart';
import 'screens/settings_screen.dart';
import 'services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Settings
  await SettingsService().init();

  // Increase image cache size for broad gallery scrolling (512MB, 3000 items)
  PaintingBinding.instance.imageCache.maximumSizeBytes = 512 << 20;
  PaintingBinding.instance.imageCache.maximumSize = 3000;
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<bool> _materialYouFuture;

  static const MethodChannel platform = MethodChannel(
    'com.pixel.gallery/open_file',
  );
  static const EventChannel eventChannel = EventChannel(
    'com.pixel.gallery/open_file_events',
  );

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  String? _initialFilePath;

  /// Default fallback seed color when Material You is OFF
  static const Color _defaultSeedColor = Color(0xFFB2C5FF);

  @override
  void initState() {
    super.initState();

    _materialYouFuture = SettingsScreen.getMaterialYou();

    _checkInitialFile();

    eventChannel.receiveBroadcastStream().listen(
      (event) {
        if (event is String) {
          navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) =>
                  SingleViewerScreen(key: ValueKey(event), file: File(event)),
            ),
            (route) => false,
          );
        }
      },
      onError: (error) {
        debugPrint('Event channel error: $error');
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

  /// Locks switch visuals so Material You only changes colors
  SwitchThemeData _buildSwitchTheme(ColorScheme scheme) {
    return SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return scheme.primary;
        }
        return scheme.outline;
      }),
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return scheme.primary.withOpacity(0.5);
        }
        return scheme.surfaceVariant;
      }),
      overlayColor: MaterialStateProperty.all(Colors.transparent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _materialYouFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }

        final bool useMaterialYou = snapshot.data!;

        return DynamicColorBuilder(
          builder: (lightDynamic, darkDynamic) {
            final ColorScheme lightScheme =
                (useMaterialYou && lightDynamic != null)
                ? lightDynamic
                : ColorScheme.fromSeed(seedColor: _defaultSeedColor);

            final ColorScheme darkScheme =
                (useMaterialYou && darkDynamic != null)
                ? darkDynamic
                : ColorScheme.fromSeed(
                    seedColor: _defaultSeedColor,
                    brightness: Brightness.dark,
                  );

            return MaterialApp(
              navigatorKey: navigatorKey,
              debugShowCheckedModeBanner: false,
              title: 'Pixel Gallery',

              /// 🌞 LIGHT THEME
              theme: ThemeData(
                useMaterial3: true,
                colorScheme: lightScheme,
                switchTheme: _buildSwitchTheme(lightScheme),
              ),

              /// 🌙 DARK THEME
              darkTheme: ThemeData(
                useMaterial3: true,
                colorScheme: darkScheme,
                switchTheme: _buildSwitchTheme(darkScheme),
              ),

              home: _initialFilePath != null
                  ? SingleViewerScreen(
                      key: ValueKey(_initialFilePath),
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
