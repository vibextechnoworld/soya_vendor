import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:soya_app/core/services/navigation_service.dart';
import 'package:soya_app/routes/app_route_pages.dart';
import 'core/constants/app_theme.dart';
import 'core/controller/theme_controller.dart';
import 'routes/app_routes.dart';

class SoyaApp extends StatelessWidget {
  const SoyaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();

    return MaterialApp(
      navigatorKey: NavigationService.navigatorKey,
      title: 'SoyaApp',
      debugShowCheckedModeBanner: false,
      locale: const Locale('en', 'IN'),
      supportedLocales: const [
        Locale('en', 'IN'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeController.themeMode,
      initialRoute: AppRoutes.splash,
      routes: AppPages.routes,
    );
  }
}
