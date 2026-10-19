import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/constants/app_strings.dart';
import 'core/services/firebase_service.dart';
import 'core/services/storage_service.dart';
import 'core/services/analytics_service.dart';
import 'core/localization/language_provider.dart';
import 'core/localization/app_localizations.dart';
import 'core/localization/app_language.dart';
import 'repositories/auth_repository.dart';
import 'repositories/story_repository.dart';
import 'repositories/activity_repository.dart';
import 'providers/auth_provider.dart';
import 'providers/story_feed_provider.dart';
import 'providers/story_player_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/activity_provider.dart';
import 'views/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style for dark immersive experience
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Concurrently initialize essential local storage and Firebase engine
  final storageFuture = StorageService.init();
  final firebaseFuture = FirebaseService.initialize();

  final storageService = await storageFuture;
  await firebaseFuture;

  final analyticsService = AnalyticsService(FirebaseService.analytics);

  // Initialize Repositories
  final authRepository = AuthRepository(storageService);
  final storyRepository = StoryRepository(storageService, enableSampleFallback: false);
  final activityRepository = ActivityRepository(storageService: storageService, enableSampleFallback: false);

  runApp(
    TwistApp(
      storageService: storageService,
      analyticsService: analyticsService,
      authRepository: authRepository,
      storyRepository: storyRepository,
      activityRepository: activityRepository,
    ),
  );

  // Defer non-critical analytics until after the first frame is rendered
  WidgetsBinding.instance.addPostFrameCallback((_) {
    analyticsService.logAppOpen();
  });
}

class TwistApp extends StatelessWidget {
  final StorageService storageService;
  final AnalyticsService analyticsService;
  final AuthRepository authRepository;
  final StoryRepository storyRepository;
  final ActivityRepository activityRepository;

  const TwistApp({
    super.key,
    required this.storageService,
    required this.analyticsService,
    required this.authRepository,
    required this.storyRepository,
    required this.activityRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Services & Repositories
        Provider<StorageService>.value(value: storageService),
        Provider<AnalyticsService>.value(value: analyticsService),
        Provider<StoryRepository>.value(value: storyRepository),
        Provider<ActivityRepository>.value(value: activityRepository),

        // State Providers
        ChangeNotifierProvider<LanguageProvider>(
          create: (_) => LanguageProvider(storageService),
        ),
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(authRepository),
        ),
        ChangeNotifierProvider<StoryFeedProvider>(
          create: (_) => StoryFeedProvider(storyRepository, analyticsService),
        ),
        ChangeNotifierProvider<StoryPlayerProvider>(
          create: (_) => StoryPlayerProvider(storyRepository, analyticsService),
        ),
        ChangeNotifierProvider<ProfileProvider>(
          create: (_) => ProfileProvider(storyRepository, storageService),
        ),
        ChangeNotifierProvider<ActivityProvider>(
          create: (_) => ActivityProvider(activityRepository, storageService: storageService),
        ),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, langProv, _) {
          return MaterialApp(
            title: AppStrings.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            locale: const Locale('en', ''),
            supportedLocales: const [
              Locale('en', ''),
            ],
            localizationsDelegates: AppLocalizations.localizationsDelegates(AppLanguage.en),
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
