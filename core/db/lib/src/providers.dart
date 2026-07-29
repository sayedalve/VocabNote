/// core/db/lib/src/providers.dart
///
/// Riverpod ownership of the database lifecycle. Everything downstream
/// (repositories, controllers) watches this provider; tests override it with
/// an in-memory executor.
library;

import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'database.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase.open();
  ref.onDispose(db.close);
  return db;
}
