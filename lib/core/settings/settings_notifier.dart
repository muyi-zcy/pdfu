import 'package:flutter/material.dart';

import '../models/pdf_feature.dart';
import '../models/picked_pdf_file.dart';
import '../pdf/pdf_page_ref.dart';
import '../platform/cache_service.dart';
import 'export_name_formatter.dart';
import 'export_record.dart';
import 'saved_recipe.dart';
import 'settings_repository.dart';
import 'task_history_entry.dart';

class SettingsNotifier extends ChangeNotifier {
  SettingsNotifier({
    SettingsRepository? repository,
    CacheService? cacheService,
  })  : _repository = repository ?? SettingsRepository(),
        _cacheService = cacheService ?? CacheService();

  final SettingsRepository _repository;
  final CacheService _cacheService;

  ThemeMode _themeMode = ThemeMode.system;
  String _exportNameTemplate = defaultExportNameTemplate;
  List<TaskHistoryEntry> _history = [];
  List<ExportRecord> _exportRecords = [];
  List<SavedRecipe> _recipes = [];
  bool _loaded = false;

  ThemeMode get themeMode => _themeMode;
  String get exportNameTemplate => _exportNameTemplate;
  List<TaskHistoryEntry> get history => List.unmodifiable(_history);
  List<ExportRecord> get exportRecords => List.unmodifiable(_exportRecords);
  List<SavedRecipe> get recipes => List.unmodifiable(_recipes);
  bool get isLoaded => _loaded;

  Future<void> load() async {
    _themeMode = await _repository.loadThemeMode();
    _exportNameTemplate = await _repository.loadExportNameTemplate();
    _history = await _repository.loadHistory();
    _exportRecords = await _repository.loadExportRecords();
    _recipes = await _repository.loadRecipes();
    _loaded = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _repository.saveThemeMode(mode);
  }

  Future<void> setExportNameTemplate(String template) async {
    _exportNameTemplate = template.trim().isEmpty
        ? defaultExportNameTemplate
        : template.trim();
    notifyListeners();
    await _repository.saveExportNameTemplate(_exportNameTemplate);
  }

  String buildExportName({
    required String baseName,
    required PdfFeatureType featureType,
    required int pageCount,
  }) {
    return formatExportFileName(
      template: _exportNameTemplate,
      baseName: baseName,
      suffix: exportSuffixForFeature(featureType),
      pageCount: pageCount,
    );
  }

  Future<void> recordTask({
    required PdfFeatureType featureType,
    required List<PickedPdfFile> files,
    int? outputPageCount,
  }) async {
    final paths = files.map((file) => file.path).toList();
    final names = files.map((file) => file.name).toList();

    _history.removeWhere(
      (entry) =>
          entry.featureType == featureType &&
          _listEquals(entry.filePaths, paths),
    );

    _history.insert(
      0,
      TaskHistoryEntry(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        featureType: featureType,
        filePaths: paths,
        fileNames: names,
        lastUsedAt: DateTime.now(),
        outputPageCount: outputPageCount,
      ),
    );

    if (_history.length > SettingsRepository.maxHistoryEntries) {
      _history = _history.take(SettingsRepository.maxHistoryEntries).toList();
    }

    notifyListeners();
    await _repository.saveHistory(_history);
  }

  Future<void> clearHistory() async {
    _history = [];
    notifyListeners();
    await _repository.saveHistory(_history);
  }

  Future<void> removeHistoryEntry(String id) async {
    _history.removeWhere((entry) => entry.id == id);
    notifyListeners();
    await _repository.saveHistory(_history);
  }

  Future<void> recordExport({
    required PdfFeatureType featureType,
    required String outputPath,
    required int pageCount,
  }) async {
    _exportRecords.insert(
      0,
      ExportRecord(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        featureType: featureType,
        outputPath: outputPath,
        exportedAt: DateTime.now(),
        pageCount: pageCount,
      ),
    );

    if (_exportRecords.length > SettingsRepository.maxExportRecords) {
      _exportRecords =
          _exportRecords.take(SettingsRepository.maxExportRecords).toList();
    }

    notifyListeners();
    await _repository.saveExportRecords(_exportRecords);
  }

  Future<void> clearExportRecords() async {
    _exportRecords = [];
    notifyListeners();
    await _repository.saveExportRecords(_exportRecords);
  }

  Future<void> removeExportRecord(String id) async {
    _exportRecords.removeWhere((record) => record.id == id);
    notifyListeners();
    await _repository.saveExportRecords(_exportRecords);
  }

  Future<SavedRecipe> saveRecipe({
    required String name,
    required PdfFeatureType featureType,
    required List<PdfPageRef> schedule,
    required List<String> sourceLabels,
  }) async {
    final labelBySourceId = {
      for (var i = 0; i < sourceLabels.length; i++) sourceLabels[i]: sourceLabels[i],
    };

    final pages = [
      for (final ref in schedule)
        SavedRecipePage(
          sourceLabel: labelBySourceId[ref.sourceId] ?? ref.sourceId,
          pageIndex: ref.pageIndex,
          rotation: ref.rotation,
        ),
    ];

    final recipe = SavedRecipe(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.trim(),
      featureType: featureType,
      createdAt: DateTime.now(),
      schedule: pages,
    );

    _recipes.insert(0, recipe);
    if (_recipes.length > SettingsRepository.maxRecipes) {
      _recipes = _recipes.take(SettingsRepository.maxRecipes).toList();
    }

    notifyListeners();
    await _repository.saveRecipes(_recipes);
    return recipe;
  }

  Future<void> removeRecipe(String id) async {
    _recipes.removeWhere((recipe) => recipe.id == id);
    notifyListeners();
    await _repository.saveRecipes(_recipes);
  }

  Future<void> clearCacheAndData() async {
    await _repository.clearAllAppData();
    await _cacheService.clearCache();
    _exportNameTemplate = defaultExportNameTemplate;
    _history = [];
    _exportRecords = [];
    _recipes = [];
    notifyListeners();
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
