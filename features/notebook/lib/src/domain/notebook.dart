/// features/notebook/lib/src/domain/notebook.dart
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'notebook.freezed.dart';

@freezed
abstract class Notebook with _$Notebook {
  const factory Notebook({
    required int id,
    required String name,
    @Default(0) int position,
    @Default(false) bool isArchived,
    required DateTime createdAt,
  }) = _Notebook;
}
