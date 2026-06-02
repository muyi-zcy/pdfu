import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'export_name_formatter.dart';
import 'export_record.dart';
import 'saved_recipe.dart';
import 'task_history_entry.dart';

class SettingsRepository {
  static const _themeModeKey = 'theme_mode';
  static const _exportTemplateKey = 'export_name_template';
  static const _historyKey = 'task_history';
  static const _exportsKey = 'export_records';
  static const _recipesKey = 'saved_recipes';
  static const maxHistoryEntries = 12;
  static const maxExportRecords = 20;
  static const maxRecipes = 24;

  Future<ThemeMode> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_themeModeKey);
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await prefs.setString(_themeModeKey, value);
  }

  Future<String> loadExportNameTemplate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_exportTemplateKey) ?? defaultExportNameTemplate;
  }

  Future<void> saveExportNameTemplate(String template) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_exportTemplateKey, template);
  }

  Future<List<TaskHistoryEntry>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey);
    if (raw == null || raw.isEmpty) return [];

    final list = jsonDecode(raw) as List;
    return list
        .map((item) => TaskHistoryEntry.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveHistory(List<TaskHistoryEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = entries.take(maxHistoryEntries).toList();
    await prefs.setString(
      _historyKey,
      jsonEncode(trimmed.map((entry) => entry.toJson()).toList()),
    );
  }

  Future<List<ExportRecord>> loadExportRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_exportsKey);
    if (raw == null || raw.isEmpty) return [];

    final list = jsonDecode(raw) as List;
    return list
        .map((item) => ExportRecord.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveExportRecords(List<ExportRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = records.take(maxExportRecords).toList();
    await prefs.setString(
      _exportsKey,
      jsonEncode(trimmed.map((record) => record.toJson()).toList()),
    );
  }

  Future<List<SavedRecipe>> loadRecipes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_recipesKey);
    if (raw == null || raw.isEmpty) return [];

    final list = jsonDecode(raw) as List;
    return list
        .map((item) => SavedRecipe.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveRecipes(List<SavedRecipe> recipes) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = recipes.take(maxRecipes).toList();
    await prefs.setString(
      _recipesKey,
      jsonEncode(trimmed.map((recipe) => recipe.toJson()).toList()),
    );
  }

  Future<void> clearAllAppData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_exportTemplateKey);
    await prefs.remove(_historyKey);
    await prefs.remove(_exportsKey);
    await prefs.remove(_recipesKey);
  }
}
