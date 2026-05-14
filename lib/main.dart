import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_links/app_links.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/main_screen.dart';
import 'screens/college/college_details_screen.dart';
import 'data/mock_data.dart';

import 'providers/user_score_provider.dart';
import 'providers/wishlist_provider.dart';
import 'providers/filter_provider.dart';
import 'providers/compare_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(prefs)),
        ChangeNotifierProvider(create: (_) => UserScoreProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
        ChangeNotifierProvider(create: (_) => FilterProvider()),
        ChangeNotifierProvider(create: (_) => CompareProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class ThemeProvider with ChangeNotifier {
  final SharedPreferences _prefs;
  static const String _themeKey = 'themeMode';
  
  late ThemeMode _themeMode;

  ThemeProvider(this._prefs) {
    final String? themeStr = _prefs.getString(_themeKey);
    if (themeStr == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (themeStr == 'light') {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.system;
    }
  }

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _prefs.setString(_themeKey, mode.toString().split('.').last);
    notifyListeners();
  }

  void toggleTheme() {
    if (_themeMode == ThemeMode.dark) {
      setThemeMode(ThemeMode.light);
    } else {
      setThemeMode(ThemeMode.dark);
    }
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  void _initDeepLinks() {
    _appLinks = AppLinks();

    // Check initial link if app was closed
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleLink(uri);
    });

    // Listen for incoming links while app is open
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleLink(uri);
    });
  }

  void _handleLink(Uri uri) {
    debugPrint('Received deep link: $uri');
    
    String? collegeId;

    // Handle https://cuetpredictor.app/college/id
    if (uri.scheme == 'https' && uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'college') {
      collegeId = uri.pathSegments[1];
    } 
    // Handle cuet://college/id
    else if (uri.scheme == 'cuet' && uri.host == 'college') {
      collegeId = uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : null;
    }
    // Handle cuet://college?id=...
    else if (uri.scheme == 'cuet' && uri.queryParameters.containsKey('id')) {
      collegeId = uri.queryParameters['id'];
    }

    if (collegeId != null) {
      debugPrint('Attempting to navigate to college: $collegeId');
      try {
        final college = MockData.colleges.firstWhere((c) => c.id == collegeId);
        
        // Use navigatorKey to navigate globally
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => CollegeDetailsScreen(college: college),
          ),
        );
      } catch (e) {
        debugPrint('College not found for ID: $collegeId');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'DU Cutoff Predictor',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          home: const SplashScreen(),
        );
      },
    );
  }
}
