import 'package:flutter/material.dart';

import 'core/app_branding.dart';
import 'core/settings/app_scope.dart';
import 'core/settings/settings_notifier.dart';
import 'core/theme/app_theme.dart';
import 'features/home/home_page.dart';

class PdfEditApp extends StatefulWidget {
  const PdfEditApp({super.key});

  @override
  State<PdfEditApp> createState() => _PdfEditAppState();
}

class _PdfEditAppState extends State<PdfEditApp> {
  final _settings = SettingsNotifier();

  @override
  void initState() {
    super.initState();
    _settings.load();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      settings: _settings,
      child: ListenableBuilder(
        listenable: _settings,
        builder: (context, _) {
          return MaterialApp(
            title: kAppName,
            debugShowCheckedModeBanner: false,
            themeMode: _settings.themeMode,
            theme: buildAppTheme(Brightness.light),
            darkTheme: buildAppTheme(Brightness.dark),
            home: const HomePage(),
          );
        },
      ),
    );
  }
}
