/// VocabNote persistence core.
///
/// Exposes the Drift database, DAOs, normalization rules, and the Riverpod
/// provider that owns the database lifecycle. Feature packages depend on this
/// package; they never open SQLite connections themselves.
library;

export 'src/daos/enrichment_dao.dart';
export 'src/daos/notebook_dao.dart';
export 'src/daos/quiz_dao.dart';
export 'src/daos/tag_dao.dart';
export 'src/daos/word_dao.dart';
export 'src/database.dart';
export 'src/providers.dart';
export 'src/tables.dart';
export 'src/text_normalization.dart';
