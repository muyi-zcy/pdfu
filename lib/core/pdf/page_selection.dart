enum PageSelectionMode {
  all,
  range,
  specific,
}

/// 解析输出页码选择（1-based 页码，返回 0-based 索引）。
class PageSelection {
  const PageSelection._();

  static List<int> resolve({
    required int totalPages,
    required PageSelectionMode mode,
    int? rangeStart,
    int? rangeEnd,
    String? specific,
  }) {
    if (totalPages <= 0) return const [];

    final indices = switch (mode) {
      PageSelectionMode.all => List.generate(totalPages, (index) => index),
      PageSelectionMode.range => _resolveRange(
          totalPages: totalPages,
          rangeStart: rangeStart,
          rangeEnd: rangeEnd,
        ),
      PageSelectionMode.specific =>
        parseSpecificPages(specific ?? '', totalPages).toList()..sort(),
    };

    return indices.where((index) => index >= 0 && index < totalPages).toList();
  }

  static List<int> _resolveRange({
    required int totalPages,
    int? rangeStart,
    int? rangeEnd,
  }) {
    final start = (rangeStart ?? 1).clamp(1, totalPages);
    final end = (rangeEnd ?? totalPages).clamp(start, totalPages);
    return List.generate(end - start + 1, (offset) => start - 1 + offset);
  }

  static Set<int> parseSpecificPages(String input, int totalPages) {
    final result = <int>{};
    for (final part in input.split(',')) {
      final trimmed = part.trim();
      if (trimmed.isEmpty) continue;

      if (trimmed.contains('-')) {
        final rangeParts = trimmed.split('-');
        if (rangeParts.length != 2) continue;
        final start = int.tryParse(rangeParts[0].trim());
        final end = int.tryParse(rangeParts[1].trim());
        if (start == null || end == null) continue;
        final from = start <= end ? start : end;
        final to = start <= end ? end : start;
        for (var page = from; page <= to; page++) {
          if (page >= 1 && page <= totalPages) {
            result.add(page - 1);
          }
        }
        continue;
      }

      final page = int.tryParse(trimmed);
      if (page != null && page >= 1 && page <= totalPages) {
        result.add(page - 1);
      }
    }
    return result;
  }

  static String describeSelection({
    required int totalPages,
    required PageSelectionMode mode,
    int? rangeStart,
    int? rangeEnd,
    String? specific,
  }) {
    final count = resolve(
      totalPages: totalPages,
      mode: mode,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
      specific: specific,
    ).length;
    return '共 $count 页';
  }
}
