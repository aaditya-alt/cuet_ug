import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_links/app_links.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/main_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/college/college_details_screen.dart';
import 'screens/wishlist/shared_wishlist_screen.dart';
import 'data/mock_data.dart';

import 'providers/user_score_provider.dart';
import 'providers/wishlist_provider.dart';
import 'providers/filter_provider.dart';
import 'providers/compare_provider.dart';
import 'providers/cutoff_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/auth_service.dart';
import 'providers/notification_service.dart';
import 'providers/du_wishlist_provider.dart';
import 'providers/app_settings_provider.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://fvrmbifeikpleuwblgqw.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ2cm1iaWZlaWtwbGV1d2JsZ3F3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg5MDE3NTAsImV4cCI6MjA5NDQ3Nzc1MH0.uJ0jRqD0Kb1tXrMqX8OlvgQpOfvow5lCMBwZFu7reHY',
  );

  final prefs = await SharedPreferences.getInstance();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(prefs)),
        ChangeNotifierProvider(create: (_) => UserScoreProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
        ChangeNotifierProvider(create: (_) => FilterProvider()),
        ChangeNotifierProvider(create: (_) => CompareProvider()),
        ChangeNotifierProvider(create: (_) => CutoffProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => NotificationService()),
        ChangeNotifierProvider(create: (_) => DuWishlistProvider()),
        ChangeNotifierProvider(create: (_) => AppSettingsProvider()),
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

  static Uri? pendingDeepLink;

  static void handleRawLink(Uri uri) {
    debugPrint('Processing deep link: $uri');
    
    String? collegeId;

    // Handle https://cuet.collegemitra.net.in/wishlist?ids=... or cuet://wishlist?ids=...
    if ((uri.pathSegments.isNotEmpty && uri.pathSegments[0] == 'wishlist') ||
        (uri.scheme == 'cuet' && uri.host == 'wishlist')) {
      final idsStr = uri.queryParameters['ids'];
      if (idsStr != null) {
        final ids = idsStr.split(',').where((id) => id.trim().isNotEmpty).toList();
        debugPrint('Received shared wishlist with IDs: $ids');
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => SharedWishlistScreen(collegeIds: ids),
            ),
          );
        });
        return;
      }
    }

    // Handle https://cuet.collegemitra.net.in/college/id
    if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'college') {
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

    // Handle password reset: cuet://reset-password#access_token=...
    if (uri.host == 'reset-password') {
      debugPrint('Detected password reset link');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => const ResetPasswordScreen(),
          ),
        );
      });
      return;
    }

    if (collegeId != null) {
      debugPrint('Attempting to navigate to college: $collegeId');
      try {
        final college = MockData.colleges.firstWhere((c) => c.id == collegeId);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => CollegeDetailsScreen(college: college),
            ),
          );
        });
      } catch (e) {
        debugPrint('College not found for ID: $collegeId');
      }
    }
  }

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
      if (uri != null) {
        debugPrint('Stored initial deep link: $uri');
        MyApp.pendingDeepLink = uri;
      }
    });

    // Listen for incoming links while app is open
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      MyApp.handleRawLink(uri);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'DUVerse',
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
