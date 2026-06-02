import 'package:flutter/material.dart';

import 'settings_notifier.dart';

class AppScope extends InheritedNotifier<SettingsNotifier> {
  const AppScope({
    super.key,
    required SettingsNotifier settings,
    required super.child,
  }) : super(notifier: settings);

  static SettingsNotifier of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found');
    return scope!.notifier!;
  }

  static SettingsNotifier? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AppScope>()
        ?.notifier;
  }
}
