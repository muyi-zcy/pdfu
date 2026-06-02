import 'package:flutter/material.dart';

List<String> sourceLabelsForCount(int count) {
  if (count <= 1) {
    return const ['doc'];
  }
  return List.generate(count, (index) => String.fromCharCode(65 + index));
}

String sourceLabelForIndex(int index) => String.fromCharCode(65 + index);

const sourcePalette = <Color>[
  Color(0xFF2563EB),
  Color(0xFF059669),
  Color(0xFF7C3AED),
  Color(0xFFEA580C),
  Color(0xFFDB2777),
  Color(0xFF0891B2),
  Color(0xFFCA8A04),
  Color(0xFF4F46E5),
];

Map<String, Color> buildSourceColors(Iterable<String> sourceIds) {
  final colors = <String, Color>{};
  var index = 0;
  for (final id in sourceIds) {
    colors[id] = sourcePalette[index % sourcePalette.length];
    index++;
  }
  return colors;
}
