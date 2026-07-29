// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $NotebooksTable extends Notebooks
    with TableInfo<$NotebooksTable, NotebookRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotebooksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name =
      GeneratedColumn<String>('name', aliasedName, false,
          additionalChecks: GeneratedColumn.checkTextLength(
            minTextLength: 1,
          ),
          type: DriftSqlType.string,
          requiredDuringInsert: true);
  static const VerificationMeta _positionMeta =
      const VerificationMeta('position');
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
      'position', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _isArchivedMeta =
      const VerificationMeta('isArchived');
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
      'is_archived', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_archived" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, position, isArchived, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notebooks';
  @override
  VerificationContext validateIntegrity(Insertable<NotebookRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('position')) {
      context.handle(_positionMeta,
          position.isAcceptableOrUnknown(data['position']!, _positionMeta));
    }
    if (data.containsKey('is_archived')) {
      context.handle(
          _isArchivedMeta,
          isArchived.isAcceptableOrUnknown(
              data['is_archived']!, _isArchivedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NotebookRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NotebookRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      position: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}position'])!,
      isArchived: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_archived'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $NotebooksTable createAlias(String alias) {
    return $NotebooksTable(attachedDatabase, alias);
  }
}

class NotebookRow extends DataClass implements Insertable<NotebookRow> {
  final int id;

  /// Display name, validated by [normalizeNotebookName] before insert.
  final String name;

  /// Manual sort order in the sidebar.
  final int position;
  final bool isArchived;
  final DateTime createdAt;
  const NotebookRow(
      {required this.id,
      required this.name,
      required this.position,
      required this.isArchived,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['position'] = Variable<int>(position);
    map['is_archived'] = Variable<bool>(isArchived);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  NotebooksCompanion toCompanion(bool nullToAbsent) {
    return NotebooksCompanion(
      id: Value(id),
      name: Value(name),
      position: Value(position),
      isArchived: Value(isArchived),
      createdAt: Value(createdAt),
    );
  }

  factory NotebookRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NotebookRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      position: serializer.fromJson<int>(json['position']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'position': serializer.toJson<int>(position),
      'isArchived': serializer.toJson<bool>(isArchived),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  NotebookRow copyWith(
          {int? id,
          String? name,
          int? position,
          bool? isArchived,
          DateTime? createdAt}) =>
      NotebookRow(
        id: id ?? this.id,
        name: name ?? this.name,
        position: position ?? this.position,
        isArchived: isArchived ?? this.isArchived,
        createdAt: createdAt ?? this.createdAt,
      );
  NotebookRow copyWithCompanion(NotebooksCompanion data) {
    return NotebookRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      position: data.position.present ? data.position.value : this.position,
      isArchived:
          data.isArchived.present ? data.isArchived.value : this.isArchived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NotebookRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('position: $position, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, position, isArchived, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NotebookRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.position == this.position &&
          other.isArchived == this.isArchived &&
          other.createdAt == this.createdAt);
}

class NotebooksCompanion extends UpdateCompanion<NotebookRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> position;
  final Value<bool> isArchived;
  final Value<DateTime> createdAt;
  const NotebooksCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.position = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  NotebooksCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.position = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<NotebookRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? position,
    Expression<bool>? isArchived,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (position != null) 'position': position,
      if (isArchived != null) 'is_archived': isArchived,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  NotebooksCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<int>? position,
      Value<bool>? isArchived,
      Value<DateTime>? createdAt}) {
    return NotebooksCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      position: position ?? this.position,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotebooksCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('position: $position, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $WordsTable extends Words with TableInfo<$WordsTable, WordRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _notebookIdMeta =
      const VerificationMeta('notebookId');
  @override
  late final GeneratedColumn<int> notebookId = GeneratedColumn<int>(
      'notebook_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES notebooks (id) ON DELETE CASCADE'));
  static const VerificationMeta _headwordNormMeta =
      const VerificationMeta('headwordNorm');
  @override
  late final GeneratedColumn<String> headwordNorm =
      GeneratedColumn<String>('headword_norm', aliasedName, false,
          additionalChecks: GeneratedColumn.checkTextLength(
            minTextLength: 1,
          ),
          type: DriftSqlType.string,
          requiredDuringInsert: true);
  static const VerificationMeta _headwordDisplayMeta =
      const VerificationMeta('headwordDisplay');
  @override
  late final GeneratedColumn<String> headwordDisplay =
      GeneratedColumn<String>('headword_display', aliasedName, false,
          additionalChecks: GeneratedColumn.checkTextLength(
            minTextLength: 1,
          ),
          type: DriftSqlType.string,
          requiredDuringInsert: true);
  static const VerificationMeta _partOfSpeechMeta =
      const VerificationMeta('partOfSpeech');
  @override
  late final GeneratedColumn<String> partOfSpeech = GeneratedColumn<String>(
      'part_of_speech', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _ipaMeta = const VerificationMeta('ipa');
  @override
  late final GeneratedColumn<String> ipa = GeneratedColumn<String>(
      'ipa', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _meaningMeta =
      const VerificationMeta('meaning');
  @override
  late final GeneratedColumn<String> meaning = GeneratedColumn<String>(
      'meaning', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _exampleSentenceMeta =
      const VerificationMeta('exampleSentence');
  @override
  late final GeneratedColumn<String> exampleSentence = GeneratedColumn<String>(
      'example_sentence', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _synonymsMeta =
      const VerificationMeta('synonyms');
  @override
  late final GeneratedColumn<String> synonyms = GeneratedColumn<String>(
      'synonyms', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _antonymsMeta =
      const VerificationMeta('antonyms');
  @override
  late final GeneratedColumn<String> antonyms = GeneratedColumn<String>(
      'antonyms', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _importantSynonymsMeta =
      const VerificationMeta('importantSynonyms');
  @override
  late final GeneratedColumn<String> importantSynonyms =
      GeneratedColumn<String>('important_synonyms', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant(''));
  static const VerificationMeta _importantAntonymsMeta =
      const VerificationMeta('importantAntonyms');
  @override
  late final GeneratedColumn<String> importantAntonyms =
      GeneratedColumn<String>('important_antonyms', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant(''));
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _isFavoriteMeta =
      const VerificationMeta('isFavorite');
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
      'is_favorite', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_favorite" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        notebookId,
        headwordNorm,
        headwordDisplay,
        partOfSpeech,
        ipa,
        meaning,
        exampleSentence,
        synonyms,
        antonyms,
        importantSynonyms,
        importantAntonyms,
        notes,
        isFavorite,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'words';
  @override
  VerificationContext validateIntegrity(Insertable<WordRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('notebook_id')) {
      context.handle(
          _notebookIdMeta,
          notebookId.isAcceptableOrUnknown(
              data['notebook_id']!, _notebookIdMeta));
    } else if (isInserting) {
      context.missing(_notebookIdMeta);
    }
    if (data.containsKey('headword_norm')) {
      context.handle(
          _headwordNormMeta,
          headwordNorm.isAcceptableOrUnknown(
              data['headword_norm']!, _headwordNormMeta));
    } else if (isInserting) {
      context.missing(_headwordNormMeta);
    }
    if (data.containsKey('headword_display')) {
      context.handle(
          _headwordDisplayMeta,
          headwordDisplay.isAcceptableOrUnknown(
              data['headword_display']!, _headwordDisplayMeta));
    } else if (isInserting) {
      context.missing(_headwordDisplayMeta);
    }
    if (data.containsKey('part_of_speech')) {
      context.handle(
          _partOfSpeechMeta,
          partOfSpeech.isAcceptableOrUnknown(
              data['part_of_speech']!, _partOfSpeechMeta));
    }
    if (data.containsKey('ipa')) {
      context.handle(
          _ipaMeta, ipa.isAcceptableOrUnknown(data['ipa']!, _ipaMeta));
    }
    if (data.containsKey('meaning')) {
      context.handle(_meaningMeta,
          meaning.isAcceptableOrUnknown(data['meaning']!, _meaningMeta));
    }
    if (data.containsKey('example_sentence')) {
      context.handle(
          _exampleSentenceMeta,
          exampleSentence.isAcceptableOrUnknown(
              data['example_sentence']!, _exampleSentenceMeta));
    }
    if (data.containsKey('synonyms')) {
      context.handle(_synonymsMeta,
          synonyms.isAcceptableOrUnknown(data['synonyms']!, _synonymsMeta));
    }
    if (data.containsKey('antonyms')) {
      context.handle(_antonymsMeta,
          antonyms.isAcceptableOrUnknown(data['antonyms']!, _antonymsMeta));
    }
    if (data.containsKey('important_synonyms')) {
      context.handle(
          _importantSynonymsMeta,
          importantSynonyms.isAcceptableOrUnknown(
              data['important_synonyms']!, _importantSynonymsMeta));
    }
    if (data.containsKey('important_antonyms')) {
      context.handle(
          _importantAntonymsMeta,
          importantAntonyms.isAcceptableOrUnknown(
              data['important_antonyms']!, _importantAntonymsMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
          _isFavoriteMeta,
          isFavorite.isAcceptableOrUnknown(
              data['is_favorite']!, _isFavoriteMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {notebookId, headwordNorm},
      ];
  @override
  WordRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WordRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      notebookId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}notebook_id'])!,
      headwordNorm: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}headword_norm'])!,
      headwordDisplay: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}headword_display'])!,
      partOfSpeech: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}part_of_speech'])!,
      ipa: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ipa'])!,
      meaning: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}meaning'])!,
      exampleSentence: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}example_sentence'])!,
      synonyms: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}synonyms'])!,
      antonyms: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}antonyms'])!,
      importantSynonyms: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}important_synonyms'])!,
      importantAntonyms: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}important_antonyms'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes'])!,
      isFavorite: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_favorite'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $WordsTable createAlias(String alias) {
    return $WordsTable(attachedDatabase, alias);
  }
}

class WordRow extends DataClass implements Insertable<WordRow> {
  final int id;
  final int notebookId;

  /// Normalized lookup key (lowercased, whitespace-collapsed). Uniqueness is
  /// per notebook — see [uniqueKeys].
  final String headwordNorm;

  /// The exact casing the user typed (legacy `display_word`).
  final String headwordDisplay;
  final String partOfSpeech;
  final String ipa;
  final String meaning;
  final String exampleSentence;

  /// Comma-joined for now to keep import from legacy v5 lossless; the
  /// relational split is scheduled with the tags feature work.
  final String synonyms;
  final String antonyms;
  final String importantSynonyms;
  final String importantAntonyms;
  final String notes;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;
  const WordRow(
      {required this.id,
      required this.notebookId,
      required this.headwordNorm,
      required this.headwordDisplay,
      required this.partOfSpeech,
      required this.ipa,
      required this.meaning,
      required this.exampleSentence,
      required this.synonyms,
      required this.antonyms,
      required this.importantSynonyms,
      required this.importantAntonyms,
      required this.notes,
      required this.isFavorite,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['notebook_id'] = Variable<int>(notebookId);
    map['headword_norm'] = Variable<String>(headwordNorm);
    map['headword_display'] = Variable<String>(headwordDisplay);
    map['part_of_speech'] = Variable<String>(partOfSpeech);
    map['ipa'] = Variable<String>(ipa);
    map['meaning'] = Variable<String>(meaning);
    map['example_sentence'] = Variable<String>(exampleSentence);
    map['synonyms'] = Variable<String>(synonyms);
    map['antonyms'] = Variable<String>(antonyms);
    map['important_synonyms'] = Variable<String>(importantSynonyms);
    map['important_antonyms'] = Variable<String>(importantAntonyms);
    map['notes'] = Variable<String>(notes);
    map['is_favorite'] = Variable<bool>(isFavorite);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  WordsCompanion toCompanion(bool nullToAbsent) {
    return WordsCompanion(
      id: Value(id),
      notebookId: Value(notebookId),
      headwordNorm: Value(headwordNorm),
      headwordDisplay: Value(headwordDisplay),
      partOfSpeech: Value(partOfSpeech),
      ipa: Value(ipa),
      meaning: Value(meaning),
      exampleSentence: Value(exampleSentence),
      synonyms: Value(synonyms),
      antonyms: Value(antonyms),
      importantSynonyms: Value(importantSynonyms),
      importantAntonyms: Value(importantAntonyms),
      notes: Value(notes),
      isFavorite: Value(isFavorite),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory WordRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WordRow(
      id: serializer.fromJson<int>(json['id']),
      notebookId: serializer.fromJson<int>(json['notebookId']),
      headwordNorm: serializer.fromJson<String>(json['headwordNorm']),
      headwordDisplay: serializer.fromJson<String>(json['headwordDisplay']),
      partOfSpeech: serializer.fromJson<String>(json['partOfSpeech']),
      ipa: serializer.fromJson<String>(json['ipa']),
      meaning: serializer.fromJson<String>(json['meaning']),
      exampleSentence: serializer.fromJson<String>(json['exampleSentence']),
      synonyms: serializer.fromJson<String>(json['synonyms']),
      antonyms: serializer.fromJson<String>(json['antonyms']),
      importantSynonyms: serializer.fromJson<String>(json['importantSynonyms']),
      importantAntonyms: serializer.fromJson<String>(json['importantAntonyms']),
      notes: serializer.fromJson<String>(json['notes']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'notebookId': serializer.toJson<int>(notebookId),
      'headwordNorm': serializer.toJson<String>(headwordNorm),
      'headwordDisplay': serializer.toJson<String>(headwordDisplay),
      'partOfSpeech': serializer.toJson<String>(partOfSpeech),
      'ipa': serializer.toJson<String>(ipa),
      'meaning': serializer.toJson<String>(meaning),
      'exampleSentence': serializer.toJson<String>(exampleSentence),
      'synonyms': serializer.toJson<String>(synonyms),
      'antonyms': serializer.toJson<String>(antonyms),
      'importantSynonyms': serializer.toJson<String>(importantSynonyms),
      'importantAntonyms': serializer.toJson<String>(importantAntonyms),
      'notes': serializer.toJson<String>(notes),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  WordRow copyWith(
          {int? id,
          int? notebookId,
          String? headwordNorm,
          String? headwordDisplay,
          String? partOfSpeech,
          String? ipa,
          String? meaning,
          String? exampleSentence,
          String? synonyms,
          String? antonyms,
          String? importantSynonyms,
          String? importantAntonyms,
          String? notes,
          bool? isFavorite,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      WordRow(
        id: id ?? this.id,
        notebookId: notebookId ?? this.notebookId,
        headwordNorm: headwordNorm ?? this.headwordNorm,
        headwordDisplay: headwordDisplay ?? this.headwordDisplay,
        partOfSpeech: partOfSpeech ?? this.partOfSpeech,
        ipa: ipa ?? this.ipa,
        meaning: meaning ?? this.meaning,
        exampleSentence: exampleSentence ?? this.exampleSentence,
        synonyms: synonyms ?? this.synonyms,
        antonyms: antonyms ?? this.antonyms,
        importantSynonyms: importantSynonyms ?? this.importantSynonyms,
        importantAntonyms: importantAntonyms ?? this.importantAntonyms,
        notes: notes ?? this.notes,
        isFavorite: isFavorite ?? this.isFavorite,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  WordRow copyWithCompanion(WordsCompanion data) {
    return WordRow(
      id: data.id.present ? data.id.value : this.id,
      notebookId:
          data.notebookId.present ? data.notebookId.value : this.notebookId,
      headwordNorm: data.headwordNorm.present
          ? data.headwordNorm.value
          : this.headwordNorm,
      headwordDisplay: data.headwordDisplay.present
          ? data.headwordDisplay.value
          : this.headwordDisplay,
      partOfSpeech: data.partOfSpeech.present
          ? data.partOfSpeech.value
          : this.partOfSpeech,
      ipa: data.ipa.present ? data.ipa.value : this.ipa,
      meaning: data.meaning.present ? data.meaning.value : this.meaning,
      exampleSentence: data.exampleSentence.present
          ? data.exampleSentence.value
          : this.exampleSentence,
      synonyms: data.synonyms.present ? data.synonyms.value : this.synonyms,
      antonyms: data.antonyms.present ? data.antonyms.value : this.antonyms,
      importantSynonyms: data.importantSynonyms.present
          ? data.importantSynonyms.value
          : this.importantSynonyms,
      importantAntonyms: data.importantAntonyms.present
          ? data.importantAntonyms.value
          : this.importantAntonyms,
      notes: data.notes.present ? data.notes.value : this.notes,
      isFavorite:
          data.isFavorite.present ? data.isFavorite.value : this.isFavorite,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WordRow(')
          ..write('id: $id, ')
          ..write('notebookId: $notebookId, ')
          ..write('headwordNorm: $headwordNorm, ')
          ..write('headwordDisplay: $headwordDisplay, ')
          ..write('partOfSpeech: $partOfSpeech, ')
          ..write('ipa: $ipa, ')
          ..write('meaning: $meaning, ')
          ..write('exampleSentence: $exampleSentence, ')
          ..write('synonyms: $synonyms, ')
          ..write('antonyms: $antonyms, ')
          ..write('importantSynonyms: $importantSynonyms, ')
          ..write('importantAntonyms: $importantAntonyms, ')
          ..write('notes: $notes, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      notebookId,
      headwordNorm,
      headwordDisplay,
      partOfSpeech,
      ipa,
      meaning,
      exampleSentence,
      synonyms,
      antonyms,
      importantSynonyms,
      importantAntonyms,
      notes,
      isFavorite,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WordRow &&
          other.id == this.id &&
          other.notebookId == this.notebookId &&
          other.headwordNorm == this.headwordNorm &&
          other.headwordDisplay == this.headwordDisplay &&
          other.partOfSpeech == this.partOfSpeech &&
          other.ipa == this.ipa &&
          other.meaning == this.meaning &&
          other.exampleSentence == this.exampleSentence &&
          other.synonyms == this.synonyms &&
          other.antonyms == this.antonyms &&
          other.importantSynonyms == this.importantSynonyms &&
          other.importantAntonyms == this.importantAntonyms &&
          other.notes == this.notes &&
          other.isFavorite == this.isFavorite &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class WordsCompanion extends UpdateCompanion<WordRow> {
  final Value<int> id;
  final Value<int> notebookId;
  final Value<String> headwordNorm;
  final Value<String> headwordDisplay;
  final Value<String> partOfSpeech;
  final Value<String> ipa;
  final Value<String> meaning;
  final Value<String> exampleSentence;
  final Value<String> synonyms;
  final Value<String> antonyms;
  final Value<String> importantSynonyms;
  final Value<String> importantAntonyms;
  final Value<String> notes;
  final Value<bool> isFavorite;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const WordsCompanion({
    this.id = const Value.absent(),
    this.notebookId = const Value.absent(),
    this.headwordNorm = const Value.absent(),
    this.headwordDisplay = const Value.absent(),
    this.partOfSpeech = const Value.absent(),
    this.ipa = const Value.absent(),
    this.meaning = const Value.absent(),
    this.exampleSentence = const Value.absent(),
    this.synonyms = const Value.absent(),
    this.antonyms = const Value.absent(),
    this.importantSynonyms = const Value.absent(),
    this.importantAntonyms = const Value.absent(),
    this.notes = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  WordsCompanion.insert({
    this.id = const Value.absent(),
    required int notebookId,
    required String headwordNorm,
    required String headwordDisplay,
    this.partOfSpeech = const Value.absent(),
    this.ipa = const Value.absent(),
    this.meaning = const Value.absent(),
    this.exampleSentence = const Value.absent(),
    this.synonyms = const Value.absent(),
    this.antonyms = const Value.absent(),
    this.importantSynonyms = const Value.absent(),
    this.importantAntonyms = const Value.absent(),
    this.notes = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : notebookId = Value(notebookId),
        headwordNorm = Value(headwordNorm),
        headwordDisplay = Value(headwordDisplay);
  static Insertable<WordRow> custom({
    Expression<int>? id,
    Expression<int>? notebookId,
    Expression<String>? headwordNorm,
    Expression<String>? headwordDisplay,
    Expression<String>? partOfSpeech,
    Expression<String>? ipa,
    Expression<String>? meaning,
    Expression<String>? exampleSentence,
    Expression<String>? synonyms,
    Expression<String>? antonyms,
    Expression<String>? importantSynonyms,
    Expression<String>? importantAntonyms,
    Expression<String>? notes,
    Expression<bool>? isFavorite,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (notebookId != null) 'notebook_id': notebookId,
      if (headwordNorm != null) 'headword_norm': headwordNorm,
      if (headwordDisplay != null) 'headword_display': headwordDisplay,
      if (partOfSpeech != null) 'part_of_speech': partOfSpeech,
      if (ipa != null) 'ipa': ipa,
      if (meaning != null) 'meaning': meaning,
      if (exampleSentence != null) 'example_sentence': exampleSentence,
      if (synonyms != null) 'synonyms': synonyms,
      if (antonyms != null) 'antonyms': antonyms,
      if (importantSynonyms != null) 'important_synonyms': importantSynonyms,
      if (importantAntonyms != null) 'important_antonyms': importantAntonyms,
      if (notes != null) 'notes': notes,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  WordsCompanion copyWith(
      {Value<int>? id,
      Value<int>? notebookId,
      Value<String>? headwordNorm,
      Value<String>? headwordDisplay,
      Value<String>? partOfSpeech,
      Value<String>? ipa,
      Value<String>? meaning,
      Value<String>? exampleSentence,
      Value<String>? synonyms,
      Value<String>? antonyms,
      Value<String>? importantSynonyms,
      Value<String>? importantAntonyms,
      Value<String>? notes,
      Value<bool>? isFavorite,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return WordsCompanion(
      id: id ?? this.id,
      notebookId: notebookId ?? this.notebookId,
      headwordNorm: headwordNorm ?? this.headwordNorm,
      headwordDisplay: headwordDisplay ?? this.headwordDisplay,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      ipa: ipa ?? this.ipa,
      meaning: meaning ?? this.meaning,
      exampleSentence: exampleSentence ?? this.exampleSentence,
      synonyms: synonyms ?? this.synonyms,
      antonyms: antonyms ?? this.antonyms,
      importantSynonyms: importantSynonyms ?? this.importantSynonyms,
      importantAntonyms: importantAntonyms ?? this.importantAntonyms,
      notes: notes ?? this.notes,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (notebookId.present) {
      map['notebook_id'] = Variable<int>(notebookId.value);
    }
    if (headwordNorm.present) {
      map['headword_norm'] = Variable<String>(headwordNorm.value);
    }
    if (headwordDisplay.present) {
      map['headword_display'] = Variable<String>(headwordDisplay.value);
    }
    if (partOfSpeech.present) {
      map['part_of_speech'] = Variable<String>(partOfSpeech.value);
    }
    if (ipa.present) {
      map['ipa'] = Variable<String>(ipa.value);
    }
    if (meaning.present) {
      map['meaning'] = Variable<String>(meaning.value);
    }
    if (exampleSentence.present) {
      map['example_sentence'] = Variable<String>(exampleSentence.value);
    }
    if (synonyms.present) {
      map['synonyms'] = Variable<String>(synonyms.value);
    }
    if (antonyms.present) {
      map['antonyms'] = Variable<String>(antonyms.value);
    }
    if (importantSynonyms.present) {
      map['important_synonyms'] = Variable<String>(importantSynonyms.value);
    }
    if (importantAntonyms.present) {
      map['important_antonyms'] = Variable<String>(importantAntonyms.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WordsCompanion(')
          ..write('id: $id, ')
          ..write('notebookId: $notebookId, ')
          ..write('headwordNorm: $headwordNorm, ')
          ..write('headwordDisplay: $headwordDisplay, ')
          ..write('partOfSpeech: $partOfSpeech, ')
          ..write('ipa: $ipa, ')
          ..write('meaning: $meaning, ')
          ..write('exampleSentence: $exampleSentence, ')
          ..write('synonyms: $synonyms, ')
          ..write('antonyms: $antonyms, ')
          ..write('importantSynonyms: $importantSynonyms, ')
          ..write('importantAntonyms: $importantAntonyms, ')
          ..write('notes: $notes, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $WordTranslationsTable extends WordTranslations
    with TableInfo<$WordTranslationsTable, WordTranslationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WordTranslationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _wordIdMeta = const VerificationMeta('wordId');
  @override
  late final GeneratedColumn<int> wordId = GeneratedColumn<int>(
      'word_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES words (id) ON DELETE CASCADE'));
  static const VerificationMeta _langCodeMeta =
      const VerificationMeta('langCode');
  @override
  late final GeneratedColumn<String> langCode = GeneratedColumn<String>(
      'lang_code', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 2, maxTextLength: 12),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _translationMeta =
      const VerificationMeta('translation');
  @override
  late final GeneratedColumn<String> translation = GeneratedColumn<String>(
      'translation', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [wordId, langCode, translation];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'word_translations';
  @override
  VerificationContext validateIntegrity(Insertable<WordTranslationRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('word_id')) {
      context.handle(_wordIdMeta,
          wordId.isAcceptableOrUnknown(data['word_id']!, _wordIdMeta));
    } else if (isInserting) {
      context.missing(_wordIdMeta);
    }
    if (data.containsKey('lang_code')) {
      context.handle(_langCodeMeta,
          langCode.isAcceptableOrUnknown(data['lang_code']!, _langCodeMeta));
    } else if (isInserting) {
      context.missing(_langCodeMeta);
    }
    if (data.containsKey('translation')) {
      context.handle(
          _translationMeta,
          translation.isAcceptableOrUnknown(
              data['translation']!, _translationMeta));
    } else if (isInserting) {
      context.missing(_translationMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {wordId, langCode};
  @override
  WordTranslationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WordTranslationRow(
      wordId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}word_id'])!,
      langCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}lang_code'])!,
      translation: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}translation'])!,
    );
  }

  @override
  $WordTranslationsTable createAlias(String alias) {
    return $WordTranslationsTable(attachedDatabase, alias);
  }
}

class WordTranslationRow extends DataClass
    implements Insertable<WordTranslationRow> {
  final int wordId;
  final String langCode;
  final String translation;
  const WordTranslationRow(
      {required this.wordId,
      required this.langCode,
      required this.translation});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['word_id'] = Variable<int>(wordId);
    map['lang_code'] = Variable<String>(langCode);
    map['translation'] = Variable<String>(translation);
    return map;
  }

  WordTranslationsCompanion toCompanion(bool nullToAbsent) {
    return WordTranslationsCompanion(
      wordId: Value(wordId),
      langCode: Value(langCode),
      translation: Value(translation),
    );
  }

  factory WordTranslationRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WordTranslationRow(
      wordId: serializer.fromJson<int>(json['wordId']),
      langCode: serializer.fromJson<String>(json['langCode']),
      translation: serializer.fromJson<String>(json['translation']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'wordId': serializer.toJson<int>(wordId),
      'langCode': serializer.toJson<String>(langCode),
      'translation': serializer.toJson<String>(translation),
    };
  }

  WordTranslationRow copyWith(
          {int? wordId, String? langCode, String? translation}) =>
      WordTranslationRow(
        wordId: wordId ?? this.wordId,
        langCode: langCode ?? this.langCode,
        translation: translation ?? this.translation,
      );
  WordTranslationRow copyWithCompanion(WordTranslationsCompanion data) {
    return WordTranslationRow(
      wordId: data.wordId.present ? data.wordId.value : this.wordId,
      langCode: data.langCode.present ? data.langCode.value : this.langCode,
      translation:
          data.translation.present ? data.translation.value : this.translation,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WordTranslationRow(')
          ..write('wordId: $wordId, ')
          ..write('langCode: $langCode, ')
          ..write('translation: $translation')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(wordId, langCode, translation);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WordTranslationRow &&
          other.wordId == this.wordId &&
          other.langCode == this.langCode &&
          other.translation == this.translation);
}

class WordTranslationsCompanion extends UpdateCompanion<WordTranslationRow> {
  final Value<int> wordId;
  final Value<String> langCode;
  final Value<String> translation;
  final Value<int> rowid;
  const WordTranslationsCompanion({
    this.wordId = const Value.absent(),
    this.langCode = const Value.absent(),
    this.translation = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WordTranslationsCompanion.insert({
    required int wordId,
    required String langCode,
    required String translation,
    this.rowid = const Value.absent(),
  })  : wordId = Value(wordId),
        langCode = Value(langCode),
        translation = Value(translation);
  static Insertable<WordTranslationRow> custom({
    Expression<int>? wordId,
    Expression<String>? langCode,
    Expression<String>? translation,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (wordId != null) 'word_id': wordId,
      if (langCode != null) 'lang_code': langCode,
      if (translation != null) 'translation': translation,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WordTranslationsCompanion copyWith(
      {Value<int>? wordId,
      Value<String>? langCode,
      Value<String>? translation,
      Value<int>? rowid}) {
    return WordTranslationsCompanion(
      wordId: wordId ?? this.wordId,
      langCode: langCode ?? this.langCode,
      translation: translation ?? this.translation,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (wordId.present) {
      map['word_id'] = Variable<int>(wordId.value);
    }
    if (langCode.present) {
      map['lang_code'] = Variable<String>(langCode.value);
    }
    if (translation.present) {
      map['translation'] = Variable<String>(translation.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WordTranslationsCompanion(')
          ..write('wordId: $wordId, ')
          ..write('langCode: $langCode, ')
          ..write('translation: $translation, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TagsTable extends Tags with TableInfo<$TagsTable, TagRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL COLLATE NOCASE UNIQUE');
  @override
  List<GeneratedColumn> get $columns => [id, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tags';
  @override
  VerificationContext validateIntegrity(Insertable<TagRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TagRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TagRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
    );
  }

  @override
  $TagsTable createAlias(String alias) {
    return $TagsTable(attachedDatabase, alias);
  }
}

class TagRow extends DataClass implements Insertable<TagRow> {
  final int id;

  /// Case-insensitive unique tag label.
  final String name;
  const TagRow({required this.id, required this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    return map;
  }

  TagsCompanion toCompanion(bool nullToAbsent) {
    return TagsCompanion(
      id: Value(id),
      name: Value(name),
    );
  }

  factory TagRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TagRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
    };
  }

  TagRow copyWith({int? id, String? name}) => TagRow(
        id: id ?? this.id,
        name: name ?? this.name,
      );
  TagRow copyWithCompanion(TagsCompanion data) {
    return TagRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TagRow(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TagRow && other.id == this.id && other.name == this.name);
}

class TagsCompanion extends UpdateCompanion<TagRow> {
  final Value<int> id;
  final Value<String> name;
  const TagsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
  });
  TagsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
  }) : name = Value(name);
  static Insertable<TagRow> custom({
    Expression<int>? id,
    Expression<String>? name,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
    });
  }

  TagsCompanion copyWith({Value<int>? id, Value<String>? name}) {
    return TagsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }
}

class $WordTagsTable extends WordTags
    with TableInfo<$WordTagsTable, WordTagRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WordTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _wordIdMeta = const VerificationMeta('wordId');
  @override
  late final GeneratedColumn<int> wordId = GeneratedColumn<int>(
      'word_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES words (id) ON DELETE CASCADE'));
  static const VerificationMeta _tagIdMeta = const VerificationMeta('tagId');
  @override
  late final GeneratedColumn<int> tagId = GeneratedColumn<int>(
      'tag_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES tags (id) ON DELETE CASCADE'));
  @override
  List<GeneratedColumn> get $columns => [wordId, tagId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'word_tags';
  @override
  VerificationContext validateIntegrity(Insertable<WordTagRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('word_id')) {
      context.handle(_wordIdMeta,
          wordId.isAcceptableOrUnknown(data['word_id']!, _wordIdMeta));
    } else if (isInserting) {
      context.missing(_wordIdMeta);
    }
    if (data.containsKey('tag_id')) {
      context.handle(
          _tagIdMeta, tagId.isAcceptableOrUnknown(data['tag_id']!, _tagIdMeta));
    } else if (isInserting) {
      context.missing(_tagIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {wordId, tagId};
  @override
  WordTagRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WordTagRow(
      wordId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}word_id'])!,
      tagId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}tag_id'])!,
    );
  }

  @override
  $WordTagsTable createAlias(String alias) {
    return $WordTagsTable(attachedDatabase, alias);
  }
}

class WordTagRow extends DataClass implements Insertable<WordTagRow> {
  final int wordId;
  final int tagId;
  const WordTagRow({required this.wordId, required this.tagId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['word_id'] = Variable<int>(wordId);
    map['tag_id'] = Variable<int>(tagId);
    return map;
  }

  WordTagsCompanion toCompanion(bool nullToAbsent) {
    return WordTagsCompanion(
      wordId: Value(wordId),
      tagId: Value(tagId),
    );
  }

  factory WordTagRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WordTagRow(
      wordId: serializer.fromJson<int>(json['wordId']),
      tagId: serializer.fromJson<int>(json['tagId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'wordId': serializer.toJson<int>(wordId),
      'tagId': serializer.toJson<int>(tagId),
    };
  }

  WordTagRow copyWith({int? wordId, int? tagId}) => WordTagRow(
        wordId: wordId ?? this.wordId,
        tagId: tagId ?? this.tagId,
      );
  WordTagRow copyWithCompanion(WordTagsCompanion data) {
    return WordTagRow(
      wordId: data.wordId.present ? data.wordId.value : this.wordId,
      tagId: data.tagId.present ? data.tagId.value : this.tagId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WordTagRow(')
          ..write('wordId: $wordId, ')
          ..write('tagId: $tagId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(wordId, tagId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WordTagRow &&
          other.wordId == this.wordId &&
          other.tagId == this.tagId);
}

class WordTagsCompanion extends UpdateCompanion<WordTagRow> {
  final Value<int> wordId;
  final Value<int> tagId;
  final Value<int> rowid;
  const WordTagsCompanion({
    this.wordId = const Value.absent(),
    this.tagId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WordTagsCompanion.insert({
    required int wordId,
    required int tagId,
    this.rowid = const Value.absent(),
  })  : wordId = Value(wordId),
        tagId = Value(tagId);
  static Insertable<WordTagRow> custom({
    Expression<int>? wordId,
    Expression<int>? tagId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (wordId != null) 'word_id': wordId,
      if (tagId != null) 'tag_id': tagId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WordTagsCompanion copyWith(
      {Value<int>? wordId, Value<int>? tagId, Value<int>? rowid}) {
    return WordTagsCompanion(
      wordId: wordId ?? this.wordId,
      tagId: tagId ?? this.tagId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (wordId.present) {
      map['word_id'] = Variable<int>(wordId.value);
    }
    if (tagId.present) {
      map['tag_id'] = Variable<int>(tagId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WordTagsCompanion(')
          ..write('wordId: $wordId, ')
          ..write('tagId: $tagId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PendingEnrichmentsTable extends PendingEnrichments
    with TableInfo<$PendingEnrichmentsTable, PendingEnrichmentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingEnrichmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _wordIdMeta = const VerificationMeta('wordId');
  @override
  late final GeneratedColumn<int> wordId = GeneratedColumn<int>(
      'word_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'UNIQUE REFERENCES words (id) ON DELETE CASCADE'));
  static const VerificationMeta _attemptsMeta =
      const VerificationMeta('attempts');
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
      'attempts', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastErrorMeta =
      const VerificationMeta('lastError');
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
      'last_error', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _nextAttemptAtMeta =
      const VerificationMeta('nextAttemptAt');
  @override
  late final GeneratedColumn<DateTime> nextAttemptAt =
      GeneratedColumn<DateTime>('next_attempt_at', aliasedName, false,
          type: DriftSqlType.dateTime,
          requiredDuringInsert: false,
          defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, wordId, attempts, lastError, createdAt, nextAttemptAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_enrichments';
  @override
  VerificationContext validateIntegrity(
      Insertable<PendingEnrichmentRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('word_id')) {
      context.handle(_wordIdMeta,
          wordId.isAcceptableOrUnknown(data['word_id']!, _wordIdMeta));
    } else if (isInserting) {
      context.missing(_wordIdMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(_attemptsMeta,
          attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta));
    }
    if (data.containsKey('last_error')) {
      context.handle(_lastErrorMeta,
          lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(
          _nextAttemptAtMeta,
          nextAttemptAt.isAcceptableOrUnknown(
              data['next_attempt_at']!, _nextAttemptAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PendingEnrichmentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingEnrichmentRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      wordId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}word_id'])!,
      attempts: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}attempts'])!,
      lastError: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_error']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      nextAttemptAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}next_attempt_at'])!,
    );
  }

  @override
  $PendingEnrichmentsTable createAlias(String alias) {
    return $PendingEnrichmentsTable(attachedDatabase, alias);
  }
}

class PendingEnrichmentRow extends DataClass
    implements Insertable<PendingEnrichmentRow> {
  final int id;
  final int wordId;
  final int attempts;
  final String? lastError;
  final DateTime createdAt;

  /// Earliest time the queue processor may retry this row (backoff schedule).
  final DateTime nextAttemptAt;
  const PendingEnrichmentRow(
      {required this.id,
      required this.wordId,
      required this.attempts,
      this.lastError,
      required this.createdAt,
      required this.nextAttemptAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['word_id'] = Variable<int>(wordId);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt);
    return map;
  }

  PendingEnrichmentsCompanion toCompanion(bool nullToAbsent) {
    return PendingEnrichmentsCompanion(
      id: Value(id),
      wordId: Value(wordId),
      attempts: Value(attempts),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      createdAt: Value(createdAt),
      nextAttemptAt: Value(nextAttemptAt),
    );
  }

  factory PendingEnrichmentRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingEnrichmentRow(
      id: serializer.fromJson<int>(json['id']),
      wordId: serializer.fromJson<int>(json['wordId']),
      attempts: serializer.fromJson<int>(json['attempts']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      nextAttemptAt: serializer.fromJson<DateTime>(json['nextAttemptAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'wordId': serializer.toJson<int>(wordId),
      'attempts': serializer.toJson<int>(attempts),
      'lastError': serializer.toJson<String?>(lastError),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'nextAttemptAt': serializer.toJson<DateTime>(nextAttemptAt),
    };
  }

  PendingEnrichmentRow copyWith(
          {int? id,
          int? wordId,
          int? attempts,
          Value<String?> lastError = const Value.absent(),
          DateTime? createdAt,
          DateTime? nextAttemptAt}) =>
      PendingEnrichmentRow(
        id: id ?? this.id,
        wordId: wordId ?? this.wordId,
        attempts: attempts ?? this.attempts,
        lastError: lastError.present ? lastError.value : this.lastError,
        createdAt: createdAt ?? this.createdAt,
        nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      );
  PendingEnrichmentRow copyWithCompanion(PendingEnrichmentsCompanion data) {
    return PendingEnrichmentRow(
      id: data.id.present ? data.id.value : this.id,
      wordId: data.wordId.present ? data.wordId.value : this.wordId,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingEnrichmentRow(')
          ..write('id: $id, ')
          ..write('wordId: $wordId, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('nextAttemptAt: $nextAttemptAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, wordId, attempts, lastError, createdAt, nextAttemptAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingEnrichmentRow &&
          other.id == this.id &&
          other.wordId == this.wordId &&
          other.attempts == this.attempts &&
          other.lastError == this.lastError &&
          other.createdAt == this.createdAt &&
          other.nextAttemptAt == this.nextAttemptAt);
}

class PendingEnrichmentsCompanion
    extends UpdateCompanion<PendingEnrichmentRow> {
  final Value<int> id;
  final Value<int> wordId;
  final Value<int> attempts;
  final Value<String?> lastError;
  final Value<DateTime> createdAt;
  final Value<DateTime> nextAttemptAt;
  const PendingEnrichmentsCompanion({
    this.id = const Value.absent(),
    this.wordId = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
  });
  PendingEnrichmentsCompanion.insert({
    this.id = const Value.absent(),
    required int wordId,
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
  }) : wordId = Value(wordId);
  static Insertable<PendingEnrichmentRow> custom({
    Expression<int>? id,
    Expression<int>? wordId,
    Expression<int>? attempts,
    Expression<String>? lastError,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? nextAttemptAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (wordId != null) 'word_id': wordId,
      if (attempts != null) 'attempts': attempts,
      if (lastError != null) 'last_error': lastError,
      if (createdAt != null) 'created_at': createdAt,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
    });
  }

  PendingEnrichmentsCompanion copyWith(
      {Value<int>? id,
      Value<int>? wordId,
      Value<int>? attempts,
      Value<String?>? lastError,
      Value<DateTime>? createdAt,
      Value<DateTime>? nextAttemptAt}) {
    return PendingEnrichmentsCompanion(
      id: id ?? this.id,
      wordId: wordId ?? this.wordId,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (wordId.present) {
      map['word_id'] = Variable<int>(wordId.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingEnrichmentsCompanion(')
          ..write('id: $id, ')
          ..write('wordId: $wordId, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('nextAttemptAt: $nextAttemptAt')
          ..write(')'))
        .toString();
  }
}

class $QuizAttemptsTable extends QuizAttempts
    with TableInfo<$QuizAttemptsTable, QuizAttemptRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuizAttemptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _notebookIdMeta =
      const VerificationMeta('notebookId');
  @override
  late final GeneratedColumn<int> notebookId = GeneratedColumn<int>(
      'notebook_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES notebooks (id) ON DELETE SET NULL'));
  static const VerificationMeta _totalQuestionsMeta =
      const VerificationMeta('totalQuestions');
  @override
  late final GeneratedColumn<int> totalQuestions = GeneratedColumn<int>(
      'total_questions', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _correctCountMeta =
      const VerificationMeta('correctCount');
  @override
  late final GeneratedColumn<int> correctCount = GeneratedColumn<int>(
      'correct_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _questionTypeMeta =
      const VerificationMeta('questionType');
  @override
  late final GeneratedColumn<String> questionType = GeneratedColumn<String>(
      'question_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('mixed'));
  static const VerificationMeta _sourceLabelMeta =
      const VerificationMeta('sourceLabel');
  @override
  late final GeneratedColumn<String> sourceLabel = GeneratedColumn<String>(
      'source_label', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _providerMeta =
      const VerificationMeta('provider');
  @override
  late final GeneratedColumn<String> provider = GeneratedColumn<String>(
      'provider', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _timeTakenSecsMeta =
      const VerificationMeta('timeTakenSecs');
  @override
  late final GeneratedColumn<int> timeTakenSecs = GeneratedColumn<int>(
      'time_taken_secs', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _startedAtMeta =
      const VerificationMeta('startedAt');
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
      'started_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _finishedAtMeta =
      const VerificationMeta('finishedAt');
  @override
  late final GeneratedColumn<DateTime> finishedAt = GeneratedColumn<DateTime>(
      'finished_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        notebookId,
        totalQuestions,
        correctCount,
        questionType,
        sourceLabel,
        provider,
        timeTakenSecs,
        startedAt,
        finishedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'quiz_attempts';
  @override
  VerificationContext validateIntegrity(Insertable<QuizAttemptRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('notebook_id')) {
      context.handle(
          _notebookIdMeta,
          notebookId.isAcceptableOrUnknown(
              data['notebook_id']!, _notebookIdMeta));
    }
    if (data.containsKey('total_questions')) {
      context.handle(
          _totalQuestionsMeta,
          totalQuestions.isAcceptableOrUnknown(
              data['total_questions']!, _totalQuestionsMeta));
    } else if (isInserting) {
      context.missing(_totalQuestionsMeta);
    }
    if (data.containsKey('correct_count')) {
      context.handle(
          _correctCountMeta,
          correctCount.isAcceptableOrUnknown(
              data['correct_count']!, _correctCountMeta));
    }
    if (data.containsKey('question_type')) {
      context.handle(
          _questionTypeMeta,
          questionType.isAcceptableOrUnknown(
              data['question_type']!, _questionTypeMeta));
    }
    if (data.containsKey('source_label')) {
      context.handle(
          _sourceLabelMeta,
          sourceLabel.isAcceptableOrUnknown(
              data['source_label']!, _sourceLabelMeta));
    }
    if (data.containsKey('provider')) {
      context.handle(_providerMeta,
          provider.isAcceptableOrUnknown(data['provider']!, _providerMeta));
    }
    if (data.containsKey('time_taken_secs')) {
      context.handle(
          _timeTakenSecsMeta,
          timeTakenSecs.isAcceptableOrUnknown(
              data['time_taken_secs']!, _timeTakenSecsMeta));
    }
    if (data.containsKey('started_at')) {
      context.handle(_startedAtMeta,
          startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta));
    }
    if (data.containsKey('finished_at')) {
      context.handle(
          _finishedAtMeta,
          finishedAt.isAcceptableOrUnknown(
              data['finished_at']!, _finishedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QuizAttemptRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuizAttemptRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      notebookId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}notebook_id']),
      totalQuestions: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_questions'])!,
      correctCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}correct_count'])!,
      questionType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}question_type'])!,
      sourceLabel: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source_label'])!,
      provider: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}provider'])!,
      timeTakenSecs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}time_taken_secs'])!,
      startedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}started_at'])!,
      finishedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}finished_at']),
    );
  }

  @override
  $QuizAttemptsTable createAlias(String alias) {
    return $QuizAttemptsTable(attachedDatabase, alias);
  }
}

class QuizAttemptRow extends DataClass implements Insertable<QuizAttemptRow> {
  final int id;
  final int? notebookId;
  final int totalQuestions;
  final int correctCount;

  /// `mixed`, `meaning`, `synonym`, or `antonym` (legacy `question_type`).
  final String questionType;

  /// Human-readable word source, e.g. "All Words" or a notebook name
  /// (legacy `word_source_label`).
  final String sourceLabel;

  /// Provider label used to generate the quiz, or `On-device` for the
  /// offline generator (legacy `provider_name`).
  final String provider;

  /// Wall-clock duration of the attempt (legacy `time_taken_secs`).
  final int timeTakenSecs;
  final DateTime startedAt;
  final DateTime? finishedAt;
  const QuizAttemptRow(
      {required this.id,
      this.notebookId,
      required this.totalQuestions,
      required this.correctCount,
      required this.questionType,
      required this.sourceLabel,
      required this.provider,
      required this.timeTakenSecs,
      required this.startedAt,
      this.finishedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || notebookId != null) {
      map['notebook_id'] = Variable<int>(notebookId);
    }
    map['total_questions'] = Variable<int>(totalQuestions);
    map['correct_count'] = Variable<int>(correctCount);
    map['question_type'] = Variable<String>(questionType);
    map['source_label'] = Variable<String>(sourceLabel);
    map['provider'] = Variable<String>(provider);
    map['time_taken_secs'] = Variable<int>(timeTakenSecs);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || finishedAt != null) {
      map['finished_at'] = Variable<DateTime>(finishedAt);
    }
    return map;
  }

  QuizAttemptsCompanion toCompanion(bool nullToAbsent) {
    return QuizAttemptsCompanion(
      id: Value(id),
      notebookId: notebookId == null && nullToAbsent
          ? const Value.absent()
          : Value(notebookId),
      totalQuestions: Value(totalQuestions),
      correctCount: Value(correctCount),
      questionType: Value(questionType),
      sourceLabel: Value(sourceLabel),
      provider: Value(provider),
      timeTakenSecs: Value(timeTakenSecs),
      startedAt: Value(startedAt),
      finishedAt: finishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(finishedAt),
    );
  }

  factory QuizAttemptRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuizAttemptRow(
      id: serializer.fromJson<int>(json['id']),
      notebookId: serializer.fromJson<int?>(json['notebookId']),
      totalQuestions: serializer.fromJson<int>(json['totalQuestions']),
      correctCount: serializer.fromJson<int>(json['correctCount']),
      questionType: serializer.fromJson<String>(json['questionType']),
      sourceLabel: serializer.fromJson<String>(json['sourceLabel']),
      provider: serializer.fromJson<String>(json['provider']),
      timeTakenSecs: serializer.fromJson<int>(json['timeTakenSecs']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      finishedAt: serializer.fromJson<DateTime?>(json['finishedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'notebookId': serializer.toJson<int?>(notebookId),
      'totalQuestions': serializer.toJson<int>(totalQuestions),
      'correctCount': serializer.toJson<int>(correctCount),
      'questionType': serializer.toJson<String>(questionType),
      'sourceLabel': serializer.toJson<String>(sourceLabel),
      'provider': serializer.toJson<String>(provider),
      'timeTakenSecs': serializer.toJson<int>(timeTakenSecs),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'finishedAt': serializer.toJson<DateTime?>(finishedAt),
    };
  }

  QuizAttemptRow copyWith(
          {int? id,
          Value<int?> notebookId = const Value.absent(),
          int? totalQuestions,
          int? correctCount,
          String? questionType,
          String? sourceLabel,
          String? provider,
          int? timeTakenSecs,
          DateTime? startedAt,
          Value<DateTime?> finishedAt = const Value.absent()}) =>
      QuizAttemptRow(
        id: id ?? this.id,
        notebookId: notebookId.present ? notebookId.value : this.notebookId,
        totalQuestions: totalQuestions ?? this.totalQuestions,
        correctCount: correctCount ?? this.correctCount,
        questionType: questionType ?? this.questionType,
        sourceLabel: sourceLabel ?? this.sourceLabel,
        provider: provider ?? this.provider,
        timeTakenSecs: timeTakenSecs ?? this.timeTakenSecs,
        startedAt: startedAt ?? this.startedAt,
        finishedAt: finishedAt.present ? finishedAt.value : this.finishedAt,
      );
  QuizAttemptRow copyWithCompanion(QuizAttemptsCompanion data) {
    return QuizAttemptRow(
      id: data.id.present ? data.id.value : this.id,
      notebookId:
          data.notebookId.present ? data.notebookId.value : this.notebookId,
      totalQuestions: data.totalQuestions.present
          ? data.totalQuestions.value
          : this.totalQuestions,
      correctCount: data.correctCount.present
          ? data.correctCount.value
          : this.correctCount,
      questionType: data.questionType.present
          ? data.questionType.value
          : this.questionType,
      sourceLabel:
          data.sourceLabel.present ? data.sourceLabel.value : this.sourceLabel,
      provider: data.provider.present ? data.provider.value : this.provider,
      timeTakenSecs: data.timeTakenSecs.present
          ? data.timeTakenSecs.value
          : this.timeTakenSecs,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      finishedAt:
          data.finishedAt.present ? data.finishedAt.value : this.finishedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuizAttemptRow(')
          ..write('id: $id, ')
          ..write('notebookId: $notebookId, ')
          ..write('totalQuestions: $totalQuestions, ')
          ..write('correctCount: $correctCount, ')
          ..write('questionType: $questionType, ')
          ..write('sourceLabel: $sourceLabel, ')
          ..write('provider: $provider, ')
          ..write('timeTakenSecs: $timeTakenSecs, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      notebookId,
      totalQuestions,
      correctCount,
      questionType,
      sourceLabel,
      provider,
      timeTakenSecs,
      startedAt,
      finishedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuizAttemptRow &&
          other.id == this.id &&
          other.notebookId == this.notebookId &&
          other.totalQuestions == this.totalQuestions &&
          other.correctCount == this.correctCount &&
          other.questionType == this.questionType &&
          other.sourceLabel == this.sourceLabel &&
          other.provider == this.provider &&
          other.timeTakenSecs == this.timeTakenSecs &&
          other.startedAt == this.startedAt &&
          other.finishedAt == this.finishedAt);
}

class QuizAttemptsCompanion extends UpdateCompanion<QuizAttemptRow> {
  final Value<int> id;
  final Value<int?> notebookId;
  final Value<int> totalQuestions;
  final Value<int> correctCount;
  final Value<String> questionType;
  final Value<String> sourceLabel;
  final Value<String> provider;
  final Value<int> timeTakenSecs;
  final Value<DateTime> startedAt;
  final Value<DateTime?> finishedAt;
  const QuizAttemptsCompanion({
    this.id = const Value.absent(),
    this.notebookId = const Value.absent(),
    this.totalQuestions = const Value.absent(),
    this.correctCount = const Value.absent(),
    this.questionType = const Value.absent(),
    this.sourceLabel = const Value.absent(),
    this.provider = const Value.absent(),
    this.timeTakenSecs = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
  });
  QuizAttemptsCompanion.insert({
    this.id = const Value.absent(),
    this.notebookId = const Value.absent(),
    required int totalQuestions,
    this.correctCount = const Value.absent(),
    this.questionType = const Value.absent(),
    this.sourceLabel = const Value.absent(),
    this.provider = const Value.absent(),
    this.timeTakenSecs = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
  }) : totalQuestions = Value(totalQuestions);
  static Insertable<QuizAttemptRow> custom({
    Expression<int>? id,
    Expression<int>? notebookId,
    Expression<int>? totalQuestions,
    Expression<int>? correctCount,
    Expression<String>? questionType,
    Expression<String>? sourceLabel,
    Expression<String>? provider,
    Expression<int>? timeTakenSecs,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? finishedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (notebookId != null) 'notebook_id': notebookId,
      if (totalQuestions != null) 'total_questions': totalQuestions,
      if (correctCount != null) 'correct_count': correctCount,
      if (questionType != null) 'question_type': questionType,
      if (sourceLabel != null) 'source_label': sourceLabel,
      if (provider != null) 'provider': provider,
      if (timeTakenSecs != null) 'time_taken_secs': timeTakenSecs,
      if (startedAt != null) 'started_at': startedAt,
      if (finishedAt != null) 'finished_at': finishedAt,
    });
  }

  QuizAttemptsCompanion copyWith(
      {Value<int>? id,
      Value<int?>? notebookId,
      Value<int>? totalQuestions,
      Value<int>? correctCount,
      Value<String>? questionType,
      Value<String>? sourceLabel,
      Value<String>? provider,
      Value<int>? timeTakenSecs,
      Value<DateTime>? startedAt,
      Value<DateTime?>? finishedAt}) {
    return QuizAttemptsCompanion(
      id: id ?? this.id,
      notebookId: notebookId ?? this.notebookId,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      correctCount: correctCount ?? this.correctCount,
      questionType: questionType ?? this.questionType,
      sourceLabel: sourceLabel ?? this.sourceLabel,
      provider: provider ?? this.provider,
      timeTakenSecs: timeTakenSecs ?? this.timeTakenSecs,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (notebookId.present) {
      map['notebook_id'] = Variable<int>(notebookId.value);
    }
    if (totalQuestions.present) {
      map['total_questions'] = Variable<int>(totalQuestions.value);
    }
    if (correctCount.present) {
      map['correct_count'] = Variable<int>(correctCount.value);
    }
    if (questionType.present) {
      map['question_type'] = Variable<String>(questionType.value);
    }
    if (sourceLabel.present) {
      map['source_label'] = Variable<String>(sourceLabel.value);
    }
    if (provider.present) {
      map['provider'] = Variable<String>(provider.value);
    }
    if (timeTakenSecs.present) {
      map['time_taken_secs'] = Variable<int>(timeTakenSecs.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (finishedAt.present) {
      map['finished_at'] = Variable<DateTime>(finishedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuizAttemptsCompanion(')
          ..write('id: $id, ')
          ..write('notebookId: $notebookId, ')
          ..write('totalQuestions: $totalQuestions, ')
          ..write('correctCount: $correctCount, ')
          ..write('questionType: $questionType, ')
          ..write('sourceLabel: $sourceLabel, ')
          ..write('provider: $provider, ')
          ..write('timeTakenSecs: $timeTakenSecs, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt')
          ..write(')'))
        .toString();
  }
}

class $QuizQuestionsTable extends QuizQuestions
    with TableInfo<$QuizQuestionsTable, QuizQuestionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuizQuestionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _attemptIdMeta =
      const VerificationMeta('attemptId');
  @override
  late final GeneratedColumn<int> attemptId = GeneratedColumn<int>(
      'attempt_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES quiz_attempts (id) ON DELETE CASCADE'));
  static const VerificationMeta _wordIdMeta = const VerificationMeta('wordId');
  @override
  late final GeneratedColumn<int> wordId = GeneratedColumn<int>(
      'word_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES words (id) ON DELETE CASCADE'));
  static const VerificationMeta _promptMeta = const VerificationMeta('prompt');
  @override
  late final GeneratedColumn<String> prompt = GeneratedColumn<String>(
      'prompt', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _questionTextMeta =
      const VerificationMeta('questionText');
  @override
  late final GeneratedColumn<String> questionText = GeneratedColumn<String>(
      'question_text', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _questionTypeMeta =
      const VerificationMeta('questionType');
  @override
  late final GeneratedColumn<String> questionType = GeneratedColumn<String>(
      'question_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('meaning'));
  static const VerificationMeta _explanationMeta =
      const VerificationMeta('explanation');
  @override
  late final GeneratedColumn<String> explanation = GeneratedColumn<String>(
      'explanation', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _correctAnswerMeta =
      const VerificationMeta('correctAnswer');
  @override
  late final GeneratedColumn<String> correctAnswer = GeneratedColumn<String>(
      'correct_answer', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _optionsJsonMeta =
      const VerificationMeta('optionsJson');
  @override
  late final GeneratedColumn<String> optionsJson = GeneratedColumn<String>(
      'options_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _chosenAnswerMeta =
      const VerificationMeta('chosenAnswer');
  @override
  late final GeneratedColumn<String> chosenAnswer = GeneratedColumn<String>(
      'chosen_answer', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _wasCorrectMeta =
      const VerificationMeta('wasCorrect');
  @override
  late final GeneratedColumn<bool> wasCorrect = GeneratedColumn<bool>(
      'was_correct', aliasedName, true,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("was_correct" IN (0, 1))'));
  static const VerificationMeta _answeredAtMeta =
      const VerificationMeta('answeredAt');
  @override
  late final GeneratedColumn<DateTime> answeredAt = GeneratedColumn<DateTime>(
      'answered_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        attemptId,
        wordId,
        prompt,
        questionText,
        questionType,
        explanation,
        correctAnswer,
        optionsJson,
        chosenAnswer,
        wasCorrect,
        answeredAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'quiz_questions';
  @override
  VerificationContext validateIntegrity(Insertable<QuizQuestionRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('attempt_id')) {
      context.handle(_attemptIdMeta,
          attemptId.isAcceptableOrUnknown(data['attempt_id']!, _attemptIdMeta));
    } else if (isInserting) {
      context.missing(_attemptIdMeta);
    }
    if (data.containsKey('word_id')) {
      context.handle(_wordIdMeta,
          wordId.isAcceptableOrUnknown(data['word_id']!, _wordIdMeta));
    } else if (isInserting) {
      context.missing(_wordIdMeta);
    }
    if (data.containsKey('prompt')) {
      context.handle(_promptMeta,
          prompt.isAcceptableOrUnknown(data['prompt']!, _promptMeta));
    } else if (isInserting) {
      context.missing(_promptMeta);
    }
    if (data.containsKey('question_text')) {
      context.handle(
          _questionTextMeta,
          questionText.isAcceptableOrUnknown(
              data['question_text']!, _questionTextMeta));
    }
    if (data.containsKey('question_type')) {
      context.handle(
          _questionTypeMeta,
          questionType.isAcceptableOrUnknown(
              data['question_type']!, _questionTypeMeta));
    }
    if (data.containsKey('explanation')) {
      context.handle(
          _explanationMeta,
          explanation.isAcceptableOrUnknown(
              data['explanation']!, _explanationMeta));
    }
    if (data.containsKey('correct_answer')) {
      context.handle(
          _correctAnswerMeta,
          correctAnswer.isAcceptableOrUnknown(
              data['correct_answer']!, _correctAnswerMeta));
    } else if (isInserting) {
      context.missing(_correctAnswerMeta);
    }
    if (data.containsKey('options_json')) {
      context.handle(
          _optionsJsonMeta,
          optionsJson.isAcceptableOrUnknown(
              data['options_json']!, _optionsJsonMeta));
    } else if (isInserting) {
      context.missing(_optionsJsonMeta);
    }
    if (data.containsKey('chosen_answer')) {
      context.handle(
          _chosenAnswerMeta,
          chosenAnswer.isAcceptableOrUnknown(
              data['chosen_answer']!, _chosenAnswerMeta));
    }
    if (data.containsKey('was_correct')) {
      context.handle(
          _wasCorrectMeta,
          wasCorrect.isAcceptableOrUnknown(
              data['was_correct']!, _wasCorrectMeta));
    }
    if (data.containsKey('answered_at')) {
      context.handle(
          _answeredAtMeta,
          answeredAt.isAcceptableOrUnknown(
              data['answered_at']!, _answeredAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QuizQuestionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuizQuestionRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      attemptId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}attempt_id'])!,
      wordId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}word_id'])!,
      prompt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}prompt'])!,
      questionText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}question_text'])!,
      questionType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}question_type'])!,
      explanation: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}explanation'])!,
      correctAnswer: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}correct_answer'])!,
      optionsJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}options_json'])!,
      chosenAnswer: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}chosen_answer']),
      wasCorrect: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}was_correct']),
      answeredAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}answered_at']),
    );
  }

  @override
  $QuizQuestionsTable createAlias(String alias) {
    return $QuizQuestionsTable(attachedDatabase, alias);
  }
}

class QuizQuestionRow extends DataClass implements Insertable<QuizQuestionRow> {
  final int id;
  final int attemptId;
  final int wordId;

  /// The headword this question is about.
  final String prompt;

  /// The full question text shown to the user (legacy `question_text`).
  /// Empty for pre-v3 rows; the UI falls back to a meaning-style question.
  final String questionText;

  /// `meaning`, `synonym`, or `antonym` (legacy `question_type`).
  final String questionType;

  /// One-line explanation of the correct answer (legacy `explanation`).
  final String explanation;
  final String correctAnswer;

  /// JSON-encoded array of the four shuffled options.
  final String optionsJson;
  final String? chosenAnswer;
  final bool? wasCorrect;
  final DateTime? answeredAt;
  const QuizQuestionRow(
      {required this.id,
      required this.attemptId,
      required this.wordId,
      required this.prompt,
      required this.questionText,
      required this.questionType,
      required this.explanation,
      required this.correctAnswer,
      required this.optionsJson,
      this.chosenAnswer,
      this.wasCorrect,
      this.answeredAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['attempt_id'] = Variable<int>(attemptId);
    map['word_id'] = Variable<int>(wordId);
    map['prompt'] = Variable<String>(prompt);
    map['question_text'] = Variable<String>(questionText);
    map['question_type'] = Variable<String>(questionType);
    map['explanation'] = Variable<String>(explanation);
    map['correct_answer'] = Variable<String>(correctAnswer);
    map['options_json'] = Variable<String>(optionsJson);
    if (!nullToAbsent || chosenAnswer != null) {
      map['chosen_answer'] = Variable<String>(chosenAnswer);
    }
    if (!nullToAbsent || wasCorrect != null) {
      map['was_correct'] = Variable<bool>(wasCorrect);
    }
    if (!nullToAbsent || answeredAt != null) {
      map['answered_at'] = Variable<DateTime>(answeredAt);
    }
    return map;
  }

  QuizQuestionsCompanion toCompanion(bool nullToAbsent) {
    return QuizQuestionsCompanion(
      id: Value(id),
      attemptId: Value(attemptId),
      wordId: Value(wordId),
      prompt: Value(prompt),
      questionText: Value(questionText),
      questionType: Value(questionType),
      explanation: Value(explanation),
      correctAnswer: Value(correctAnswer),
      optionsJson: Value(optionsJson),
      chosenAnswer: chosenAnswer == null && nullToAbsent
          ? const Value.absent()
          : Value(chosenAnswer),
      wasCorrect: wasCorrect == null && nullToAbsent
          ? const Value.absent()
          : Value(wasCorrect),
      answeredAt: answeredAt == null && nullToAbsent
          ? const Value.absent()
          : Value(answeredAt),
    );
  }

  factory QuizQuestionRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuizQuestionRow(
      id: serializer.fromJson<int>(json['id']),
      attemptId: serializer.fromJson<int>(json['attemptId']),
      wordId: serializer.fromJson<int>(json['wordId']),
      prompt: serializer.fromJson<String>(json['prompt']),
      questionText: serializer.fromJson<String>(json['questionText']),
      questionType: serializer.fromJson<String>(json['questionType']),
      explanation: serializer.fromJson<String>(json['explanation']),
      correctAnswer: serializer.fromJson<String>(json['correctAnswer']),
      optionsJson: serializer.fromJson<String>(json['optionsJson']),
      chosenAnswer: serializer.fromJson<String?>(json['chosenAnswer']),
      wasCorrect: serializer.fromJson<bool?>(json['wasCorrect']),
      answeredAt: serializer.fromJson<DateTime?>(json['answeredAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'attemptId': serializer.toJson<int>(attemptId),
      'wordId': serializer.toJson<int>(wordId),
      'prompt': serializer.toJson<String>(prompt),
      'questionText': serializer.toJson<String>(questionText),
      'questionType': serializer.toJson<String>(questionType),
      'explanation': serializer.toJson<String>(explanation),
      'correctAnswer': serializer.toJson<String>(correctAnswer),
      'optionsJson': serializer.toJson<String>(optionsJson),
      'chosenAnswer': serializer.toJson<String?>(chosenAnswer),
      'wasCorrect': serializer.toJson<bool?>(wasCorrect),
      'answeredAt': serializer.toJson<DateTime?>(answeredAt),
    };
  }

  QuizQuestionRow copyWith(
          {int? id,
          int? attemptId,
          int? wordId,
          String? prompt,
          String? questionText,
          String? questionType,
          String? explanation,
          String? correctAnswer,
          String? optionsJson,
          Value<String?> chosenAnswer = const Value.absent(),
          Value<bool?> wasCorrect = const Value.absent(),
          Value<DateTime?> answeredAt = const Value.absent()}) =>
      QuizQuestionRow(
        id: id ?? this.id,
        attemptId: attemptId ?? this.attemptId,
        wordId: wordId ?? this.wordId,
        prompt: prompt ?? this.prompt,
        questionText: questionText ?? this.questionText,
        questionType: questionType ?? this.questionType,
        explanation: explanation ?? this.explanation,
        correctAnswer: correctAnswer ?? this.correctAnswer,
        optionsJson: optionsJson ?? this.optionsJson,
        chosenAnswer:
            chosenAnswer.present ? chosenAnswer.value : this.chosenAnswer,
        wasCorrect: wasCorrect.present ? wasCorrect.value : this.wasCorrect,
        answeredAt: answeredAt.present ? answeredAt.value : this.answeredAt,
      );
  QuizQuestionRow copyWithCompanion(QuizQuestionsCompanion data) {
    return QuizQuestionRow(
      id: data.id.present ? data.id.value : this.id,
      attemptId: data.attemptId.present ? data.attemptId.value : this.attemptId,
      wordId: data.wordId.present ? data.wordId.value : this.wordId,
      prompt: data.prompt.present ? data.prompt.value : this.prompt,
      questionText: data.questionText.present
          ? data.questionText.value
          : this.questionText,
      questionType: data.questionType.present
          ? data.questionType.value
          : this.questionType,
      explanation:
          data.explanation.present ? data.explanation.value : this.explanation,
      correctAnswer: data.correctAnswer.present
          ? data.correctAnswer.value
          : this.correctAnswer,
      optionsJson:
          data.optionsJson.present ? data.optionsJson.value : this.optionsJson,
      chosenAnswer: data.chosenAnswer.present
          ? data.chosenAnswer.value
          : this.chosenAnswer,
      wasCorrect:
          data.wasCorrect.present ? data.wasCorrect.value : this.wasCorrect,
      answeredAt:
          data.answeredAt.present ? data.answeredAt.value : this.answeredAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuizQuestionRow(')
          ..write('id: $id, ')
          ..write('attemptId: $attemptId, ')
          ..write('wordId: $wordId, ')
          ..write('prompt: $prompt, ')
          ..write('questionText: $questionText, ')
          ..write('questionType: $questionType, ')
          ..write('explanation: $explanation, ')
          ..write('correctAnswer: $correctAnswer, ')
          ..write('optionsJson: $optionsJson, ')
          ..write('chosenAnswer: $chosenAnswer, ')
          ..write('wasCorrect: $wasCorrect, ')
          ..write('answeredAt: $answeredAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      attemptId,
      wordId,
      prompt,
      questionText,
      questionType,
      explanation,
      correctAnswer,
      optionsJson,
      chosenAnswer,
      wasCorrect,
      answeredAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuizQuestionRow &&
          other.id == this.id &&
          other.attemptId == this.attemptId &&
          other.wordId == this.wordId &&
          other.prompt == this.prompt &&
          other.questionText == this.questionText &&
          other.questionType == this.questionType &&
          other.explanation == this.explanation &&
          other.correctAnswer == this.correctAnswer &&
          other.optionsJson == this.optionsJson &&
          other.chosenAnswer == this.chosenAnswer &&
          other.wasCorrect == this.wasCorrect &&
          other.answeredAt == this.answeredAt);
}

class QuizQuestionsCompanion extends UpdateCompanion<QuizQuestionRow> {
  final Value<int> id;
  final Value<int> attemptId;
  final Value<int> wordId;
  final Value<String> prompt;
  final Value<String> questionText;
  final Value<String> questionType;
  final Value<String> explanation;
  final Value<String> correctAnswer;
  final Value<String> optionsJson;
  final Value<String?> chosenAnswer;
  final Value<bool?> wasCorrect;
  final Value<DateTime?> answeredAt;
  const QuizQuestionsCompanion({
    this.id = const Value.absent(),
    this.attemptId = const Value.absent(),
    this.wordId = const Value.absent(),
    this.prompt = const Value.absent(),
    this.questionText = const Value.absent(),
    this.questionType = const Value.absent(),
    this.explanation = const Value.absent(),
    this.correctAnswer = const Value.absent(),
    this.optionsJson = const Value.absent(),
    this.chosenAnswer = const Value.absent(),
    this.wasCorrect = const Value.absent(),
    this.answeredAt = const Value.absent(),
  });
  QuizQuestionsCompanion.insert({
    this.id = const Value.absent(),
    required int attemptId,
    required int wordId,
    required String prompt,
    this.questionText = const Value.absent(),
    this.questionType = const Value.absent(),
    this.explanation = const Value.absent(),
    required String correctAnswer,
    required String optionsJson,
    this.chosenAnswer = const Value.absent(),
    this.wasCorrect = const Value.absent(),
    this.answeredAt = const Value.absent(),
  })  : attemptId = Value(attemptId),
        wordId = Value(wordId),
        prompt = Value(prompt),
        correctAnswer = Value(correctAnswer),
        optionsJson = Value(optionsJson);
  static Insertable<QuizQuestionRow> custom({
    Expression<int>? id,
    Expression<int>? attemptId,
    Expression<int>? wordId,
    Expression<String>? prompt,
    Expression<String>? questionText,
    Expression<String>? questionType,
    Expression<String>? explanation,
    Expression<String>? correctAnswer,
    Expression<String>? optionsJson,
    Expression<String>? chosenAnswer,
    Expression<bool>? wasCorrect,
    Expression<DateTime>? answeredAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (attemptId != null) 'attempt_id': attemptId,
      if (wordId != null) 'word_id': wordId,
      if (prompt != null) 'prompt': prompt,
      if (questionText != null) 'question_text': questionText,
      if (questionType != null) 'question_type': questionType,
      if (explanation != null) 'explanation': explanation,
      if (correctAnswer != null) 'correct_answer': correctAnswer,
      if (optionsJson != null) 'options_json': optionsJson,
      if (chosenAnswer != null) 'chosen_answer': chosenAnswer,
      if (wasCorrect != null) 'was_correct': wasCorrect,
      if (answeredAt != null) 'answered_at': answeredAt,
    });
  }

  QuizQuestionsCompanion copyWith(
      {Value<int>? id,
      Value<int>? attemptId,
      Value<int>? wordId,
      Value<String>? prompt,
      Value<String>? questionText,
      Value<String>? questionType,
      Value<String>? explanation,
      Value<String>? correctAnswer,
      Value<String>? optionsJson,
      Value<String?>? chosenAnswer,
      Value<bool?>? wasCorrect,
      Value<DateTime?>? answeredAt}) {
    return QuizQuestionsCompanion(
      id: id ?? this.id,
      attemptId: attemptId ?? this.attemptId,
      wordId: wordId ?? this.wordId,
      prompt: prompt ?? this.prompt,
      questionText: questionText ?? this.questionText,
      questionType: questionType ?? this.questionType,
      explanation: explanation ?? this.explanation,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      optionsJson: optionsJson ?? this.optionsJson,
      chosenAnswer: chosenAnswer ?? this.chosenAnswer,
      wasCorrect: wasCorrect ?? this.wasCorrect,
      answeredAt: answeredAt ?? this.answeredAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (attemptId.present) {
      map['attempt_id'] = Variable<int>(attemptId.value);
    }
    if (wordId.present) {
      map['word_id'] = Variable<int>(wordId.value);
    }
    if (prompt.present) {
      map['prompt'] = Variable<String>(prompt.value);
    }
    if (questionText.present) {
      map['question_text'] = Variable<String>(questionText.value);
    }
    if (questionType.present) {
      map['question_type'] = Variable<String>(questionType.value);
    }
    if (explanation.present) {
      map['explanation'] = Variable<String>(explanation.value);
    }
    if (correctAnswer.present) {
      map['correct_answer'] = Variable<String>(correctAnswer.value);
    }
    if (optionsJson.present) {
      map['options_json'] = Variable<String>(optionsJson.value);
    }
    if (chosenAnswer.present) {
      map['chosen_answer'] = Variable<String>(chosenAnswer.value);
    }
    if (wasCorrect.present) {
      map['was_correct'] = Variable<bool>(wasCorrect.value);
    }
    if (answeredAt.present) {
      map['answered_at'] = Variable<DateTime>(answeredAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuizQuestionsCompanion(')
          ..write('id: $id, ')
          ..write('attemptId: $attemptId, ')
          ..write('wordId: $wordId, ')
          ..write('prompt: $prompt, ')
          ..write('questionText: $questionText, ')
          ..write('questionType: $questionType, ')
          ..write('explanation: $explanation, ')
          ..write('correctAnswer: $correctAnswer, ')
          ..write('optionsJson: $optionsJson, ')
          ..write('chosenAnswer: $chosenAnswer, ')
          ..write('wasCorrect: $wasCorrect, ')
          ..write('answeredAt: $answeredAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $NotebooksTable notebooks = $NotebooksTable(this);
  late final $WordsTable words = $WordsTable(this);
  late final $WordTranslationsTable wordTranslations =
      $WordTranslationsTable(this);
  late final $TagsTable tags = $TagsTable(this);
  late final $WordTagsTable wordTags = $WordTagsTable(this);
  late final $PendingEnrichmentsTable pendingEnrichments =
      $PendingEnrichmentsTable(this);
  late final $QuizAttemptsTable quizAttempts = $QuizAttemptsTable(this);
  late final $QuizQuestionsTable quizQuestions = $QuizQuestionsTable(this);
  late final Index idxWordsNotebook = Index('idx_words_notebook',
      'CREATE INDEX idx_words_notebook ON words (notebook_id)');
  late final Index idxWordsFavorite = Index('idx_words_favorite',
      'CREATE INDEX idx_words_favorite ON words (is_favorite)');
  late final Index idxWordsNorm = Index(
      'idx_words_norm', 'CREATE INDEX idx_words_norm ON words (headword_norm)');
  late final Index idxPendingNextAttempt = Index('idx_pending_next_attempt',
      'CREATE INDEX idx_pending_next_attempt ON pending_enrichments (next_attempt_at)');
  late final Index idxQuizQuestionsAttempt = Index('idx_quiz_questions_attempt',
      'CREATE INDEX idx_quiz_questions_attempt ON quiz_questions (attempt_id)');
  late final WordDao wordDao = WordDao(this as AppDatabase);
  late final NotebookDao notebookDao = NotebookDao(this as AppDatabase);
  late final EnrichmentDao enrichmentDao = EnrichmentDao(this as AppDatabase);
  late final QuizDao quizDao = QuizDao(this as AppDatabase);
  late final TagDao tagDao = TagDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        notebooks,
        words,
        wordTranslations,
        tags,
        wordTags,
        pendingEnrichments,
        quizAttempts,
        quizQuestions,
        idxWordsNotebook,
        idxWordsFavorite,
        idxWordsNorm,
        idxPendingNextAttempt,
        idxQuizQuestionsAttempt
      ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('notebooks',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('words', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('words',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('word_translations', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('words',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('word_tags', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('tags',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('word_tags', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('words',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('pending_enrichments', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('notebooks',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('quiz_attempts', kind: UpdateKind.update),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('quiz_attempts',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('quiz_questions', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('words',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('quiz_questions', kind: UpdateKind.delete),
            ],
          ),
        ],
      );
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$NotebooksTableCreateCompanionBuilder = NotebooksCompanion Function({
  Value<int> id,
  required String name,
  Value<int> position,
  Value<bool> isArchived,
  Value<DateTime> createdAt,
});
typedef $$NotebooksTableUpdateCompanionBuilder = NotebooksCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<int> position,
  Value<bool> isArchived,
  Value<DateTime> createdAt,
});

final class $$NotebooksTableReferences
    extends BaseReferences<_$AppDatabase, $NotebooksTable, NotebookRow> {
  $$NotebooksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$WordsTable, List<WordRow>> _wordsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.words,
          aliasName: 'notebooks__id__words__notebook_id');

  $$WordsTableProcessedTableManager get wordsRefs {
    final manager = $$WordsTableTableManager($_db, $_db.words)
        .filter((f) => f.notebookId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_wordsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$QuizAttemptsTable, List<QuizAttemptRow>>
      _quizAttemptsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.quizAttempts,
              aliasName: 'notebooks__id__quiz_attempts__notebook_id');

  $$QuizAttemptsTableProcessedTableManager get quizAttemptsRefs {
    final manager = $$QuizAttemptsTableTableManager($_db, $_db.quizAttempts)
        .filter((f) => f.notebookId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_quizAttemptsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$NotebooksTableFilterComposer
    extends Composer<_$AppDatabase, $NotebooksTable> {
  $$NotebooksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  Expression<bool> wordsRefs(
      Expression<bool> Function($$WordsTableFilterComposer f) f) {
    final $$WordsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.words,
        getReferencedColumn: (t) => t.notebookId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WordsTableFilterComposer(
              $db: $db,
              $table: $db.words,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> quizAttemptsRefs(
      Expression<bool> Function($$QuizAttemptsTableFilterComposer f) f) {
    final $$QuizAttemptsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.quizAttempts,
        getReferencedColumn: (t) => t.notebookId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$QuizAttemptsTableFilterComposer(
              $db: $db,
              $table: $db.quizAttempts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$NotebooksTableOrderingComposer
    extends Composer<_$AppDatabase, $NotebooksTable> {
  $$NotebooksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$NotebooksTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotebooksTable> {
  $$NotebooksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> wordsRefs<T extends Object>(
      Expression<T> Function($$WordsTableAnnotationComposer a) f) {
    final $$WordsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.words,
        getReferencedColumn: (t) => t.notebookId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WordsTableAnnotationComposer(
              $db: $db,
              $table: $db.words,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> quizAttemptsRefs<T extends Object>(
      Expression<T> Function($$QuizAttemptsTableAnnotationComposer a) f) {
    final $$QuizAttemptsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.quizAttempts,
        getReferencedColumn: (t) => t.notebookId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$QuizAttemptsTableAnnotationComposer(
              $db: $db,
              $table: $db.quizAttempts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$NotebooksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $NotebooksTable,
    NotebookRow,
    $$NotebooksTableFilterComposer,
    $$NotebooksTableOrderingComposer,
    $$NotebooksTableAnnotationComposer,
    $$NotebooksTableCreateCompanionBuilder,
    $$NotebooksTableUpdateCompanionBuilder,
    (NotebookRow, $$NotebooksTableReferences),
    NotebookRow,
    PrefetchHooks Function({bool wordsRefs, bool quizAttemptsRefs})> {
  $$NotebooksTableTableManager(_$AppDatabase db, $NotebooksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotebooksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotebooksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotebooksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> position = const Value.absent(),
            Value<bool> isArchived = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              NotebooksCompanion(
            id: id,
            name: name,
            position: position,
            isArchived: isArchived,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<int> position = const Value.absent(),
            Value<bool> isArchived = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              NotebooksCompanion.insert(
            id: id,
            name: name,
            position: position,
            isArchived: isArchived,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$NotebooksTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {wordsRefs = false, quizAttemptsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (wordsRefs) db.words,
                if (quizAttemptsRefs) db.quizAttempts
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (wordsRefs)
                    await $_getPrefetchedData<NotebookRow, $NotebooksTable,
                            WordRow>(
                        currentTable: table,
                        referencedTable:
                            $$NotebooksTableReferences._wordsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$NotebooksTableReferences(db, table, p0).wordsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.notebookId == item.id),
                        typedResults: items),
                  if (quizAttemptsRefs)
                    await $_getPrefetchedData<NotebookRow, $NotebooksTable,
                            QuizAttemptRow>(
                        currentTable: table,
                        referencedTable: $$NotebooksTableReferences
                            ._quizAttemptsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$NotebooksTableReferences(db, table, p0)
                                .quizAttemptsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.notebookId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$NotebooksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $NotebooksTable,
    NotebookRow,
    $$NotebooksTableFilterComposer,
    $$NotebooksTableOrderingComposer,
    $$NotebooksTableAnnotationComposer,
    $$NotebooksTableCreateCompanionBuilder,
    $$NotebooksTableUpdateCompanionBuilder,
    (NotebookRow, $$NotebooksTableReferences),
    NotebookRow,
    PrefetchHooks Function({bool wordsRefs, bool quizAttemptsRefs})>;
typedef $$WordsTableCreateCompanionBuilder = WordsCompanion Function({
  Value<int> id,
  required int notebookId,
  required String headwordNorm,
  required String headwordDisplay,
  Value<String> partOfSpeech,
  Value<String> ipa,
  Value<String> meaning,
  Value<String> exampleSentence,
  Value<String> synonyms,
  Value<String> antonyms,
  Value<String> importantSynonyms,
  Value<String> importantAntonyms,
  Value<String> notes,
  Value<bool> isFavorite,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$WordsTableUpdateCompanionBuilder = WordsCompanion Function({
  Value<int> id,
  Value<int> notebookId,
  Value<String> headwordNorm,
  Value<String> headwordDisplay,
  Value<String> partOfSpeech,
  Value<String> ipa,
  Value<String> meaning,
  Value<String> exampleSentence,
  Value<String> synonyms,
  Value<String> antonyms,
  Value<String> importantSynonyms,
  Value<String> importantAntonyms,
  Value<String> notes,
  Value<bool> isFavorite,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

final class $$WordsTableReferences
    extends BaseReferences<_$AppDatabase, $WordsTable, WordRow> {
  $$WordsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $NotebooksTable _notebookIdTable(_$AppDatabase db) =>
      db.notebooks.createAlias('words__notebook_id__notebooks__id');

  $$NotebooksTableProcessedTableManager get notebookId {
    final $_column = $_itemColumn<int>('notebook_id')!;

    final manager = $$NotebooksTableTableManager($_db, $_db.notebooks)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_notebookIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$WordTranslationsTable, List<WordTranslationRow>>
      _wordTranslationsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.wordTranslations,
              aliasName: 'words__id__word_translations__word_id');

  $$WordTranslationsTableProcessedTableManager get wordTranslationsRefs {
    final manager =
        $$WordTranslationsTableTableManager($_db, $_db.wordTranslations)
            .filter((f) => f.wordId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_wordTranslationsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$WordTagsTable, List<WordTagRow>>
      _wordTagsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.wordTags,
              aliasName: 'words__id__word_tags__word_id');

  $$WordTagsTableProcessedTableManager get wordTagsRefs {
    final manager = $$WordTagsTableTableManager($_db, $_db.wordTags)
        .filter((f) => f.wordId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_wordTagsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$PendingEnrichmentsTable,
      List<PendingEnrichmentRow>> _pendingEnrichmentsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.pendingEnrichments,
          aliasName: 'words__id__pending_enrichments__word_id');

  $$PendingEnrichmentsTableProcessedTableManager get pendingEnrichmentsRefs {
    final manager =
        $$PendingEnrichmentsTableTableManager($_db, $_db.pendingEnrichments)
            .filter((f) => f.wordId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_pendingEnrichmentsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$QuizQuestionsTable, List<QuizQuestionRow>>
      _quizQuestionsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.quizQuestions,
              aliasName: 'words__id__quiz_questions__word_id');

  $$QuizQuestionsTableProcessedTableManager get quizQuestionsRefs {
    final manager = $$QuizQuestionsTableTableManager($_db, $_db.quizQuestions)
        .filter((f) => f.wordId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_quizQuestionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$WordsTableFilterComposer extends Composer<_$AppDatabase, $WordsTable> {
  $$WordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get headwordNorm => $composableBuilder(
      column: $table.headwordNorm, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get headwordDisplay => $composableBuilder(
      column: $table.headwordDisplay,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get partOfSpeech => $composableBuilder(
      column: $table.partOfSpeech, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ipa => $composableBuilder(
      column: $table.ipa, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get meaning => $composableBuilder(
      column: $table.meaning, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get exampleSentence => $composableBuilder(
      column: $table.exampleSentence,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get synonyms => $composableBuilder(
      column: $table.synonyms, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get antonyms => $composableBuilder(
      column: $table.antonyms, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get importantSynonyms => $composableBuilder(
      column: $table.importantSynonyms,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get importantAntonyms => $composableBuilder(
      column: $table.importantAntonyms,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  $$NotebooksTableFilterComposer get notebookId {
    final $$NotebooksTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.notebookId,
        referencedTable: $db.notebooks,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$NotebooksTableFilterComposer(
              $db: $db,
              $table: $db.notebooks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> wordTranslationsRefs(
      Expression<bool> Function($$WordTranslationsTableFilterComposer f) f) {
    final $$WordTranslationsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.wordTranslations,
        getReferencedColumn: (t) => t.wordId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WordTranslationsTableFilterComposer(
              $db: $db,
              $table: $db.wordTranslations,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> wordTagsRefs(
      Expression<bool> Function($$WordTagsTableFilterComposer f) f) {
    final $$WordTagsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.wordTags,
        getReferencedColumn: (t) => t.wordId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WordTagsTableFilterComposer(
              $db: $db,
              $table: $db.wordTags,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> pendingEnrichmentsRefs(
      Expression<bool> Function($$PendingEnrichmentsTableFilterComposer f) f) {
    final $$PendingEnrichmentsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.pendingEnrichments,
        getReferencedColumn: (t) => t.wordId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PendingEnrichmentsTableFilterComposer(
              $db: $db,
              $table: $db.pendingEnrichments,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> quizQuestionsRefs(
      Expression<bool> Function($$QuizQuestionsTableFilterComposer f) f) {
    final $$QuizQuestionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.quizQuestions,
        getReferencedColumn: (t) => t.wordId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$QuizQuestionsTableFilterComposer(
              $db: $db,
              $table: $db.quizQuestions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$WordsTableOrderingComposer
    extends Composer<_$AppDatabase, $WordsTable> {
  $$WordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get headwordNorm => $composableBuilder(
      column: $table.headwordNorm,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get headwordDisplay => $composableBuilder(
      column: $table.headwordDisplay,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get partOfSpeech => $composableBuilder(
      column: $table.partOfSpeech,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ipa => $composableBuilder(
      column: $table.ipa, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get meaning => $composableBuilder(
      column: $table.meaning, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get exampleSentence => $composableBuilder(
      column: $table.exampleSentence,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get synonyms => $composableBuilder(
      column: $table.synonyms, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get antonyms => $composableBuilder(
      column: $table.antonyms, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get importantSynonyms => $composableBuilder(
      column: $table.importantSynonyms,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get importantAntonyms => $composableBuilder(
      column: $table.importantAntonyms,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  $$NotebooksTableOrderingComposer get notebookId {
    final $$NotebooksTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.notebookId,
        referencedTable: $db.notebooks,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$NotebooksTableOrderingComposer(
              $db: $db,
              $table: $db.notebooks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$WordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WordsTable> {
  $$WordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get headwordNorm => $composableBuilder(
      column: $table.headwordNorm, builder: (column) => column);

  GeneratedColumn<String> get headwordDisplay => $composableBuilder(
      column: $table.headwordDisplay, builder: (column) => column);

  GeneratedColumn<String> get partOfSpeech => $composableBuilder(
      column: $table.partOfSpeech, builder: (column) => column);

  GeneratedColumn<String> get ipa =>
      $composableBuilder(column: $table.ipa, builder: (column) => column);

  GeneratedColumn<String> get meaning =>
      $composableBuilder(column: $table.meaning, builder: (column) => column);

  GeneratedColumn<String> get exampleSentence => $composableBuilder(
      column: $table.exampleSentence, builder: (column) => column);

  GeneratedColumn<String> get synonyms =>
      $composableBuilder(column: $table.synonyms, builder: (column) => column);

  GeneratedColumn<String> get antonyms =>
      $composableBuilder(column: $table.antonyms, builder: (column) => column);

  GeneratedColumn<String> get importantSynonyms => $composableBuilder(
      column: $table.importantSynonyms, builder: (column) => column);

  GeneratedColumn<String> get importantAntonyms => $composableBuilder(
      column: $table.importantAntonyms, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$NotebooksTableAnnotationComposer get notebookId {
    final $$NotebooksTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.notebookId,
        referencedTable: $db.notebooks,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$NotebooksTableAnnotationComposer(
              $db: $db,
              $table: $db.notebooks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> wordTranslationsRefs<T extends Object>(
      Expression<T> Function($$WordTranslationsTableAnnotationComposer a) f) {
    final $$WordTranslationsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.wordTranslations,
        getReferencedColumn: (t) => t.wordId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WordTranslationsTableAnnotationComposer(
              $db: $db,
              $table: $db.wordTranslations,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> wordTagsRefs<T extends Object>(
      Expression<T> Function($$WordTagsTableAnnotationComposer a) f) {
    final $$WordTagsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.wordTags,
        getReferencedColumn: (t) => t.wordId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WordTagsTableAnnotationComposer(
              $db: $db,
              $table: $db.wordTags,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> pendingEnrichmentsRefs<T extends Object>(
      Expression<T> Function($$PendingEnrichmentsTableAnnotationComposer a) f) {
    final $$PendingEnrichmentsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.pendingEnrichments,
            getReferencedColumn: (t) => t.wordId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$PendingEnrichmentsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.pendingEnrichments,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> quizQuestionsRefs<T extends Object>(
      Expression<T> Function($$QuizQuestionsTableAnnotationComposer a) f) {
    final $$QuizQuestionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.quizQuestions,
        getReferencedColumn: (t) => t.wordId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$QuizQuestionsTableAnnotationComposer(
              $db: $db,
              $table: $db.quizQuestions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$WordsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $WordsTable,
    WordRow,
    $$WordsTableFilterComposer,
    $$WordsTableOrderingComposer,
    $$WordsTableAnnotationComposer,
    $$WordsTableCreateCompanionBuilder,
    $$WordsTableUpdateCompanionBuilder,
    (WordRow, $$WordsTableReferences),
    WordRow,
    PrefetchHooks Function(
        {bool notebookId,
        bool wordTranslationsRefs,
        bool wordTagsRefs,
        bool pendingEnrichmentsRefs,
        bool quizQuestionsRefs})> {
  $$WordsTableTableManager(_$AppDatabase db, $WordsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> notebookId = const Value.absent(),
            Value<String> headwordNorm = const Value.absent(),
            Value<String> headwordDisplay = const Value.absent(),
            Value<String> partOfSpeech = const Value.absent(),
            Value<String> ipa = const Value.absent(),
            Value<String> meaning = const Value.absent(),
            Value<String> exampleSentence = const Value.absent(),
            Value<String> synonyms = const Value.absent(),
            Value<String> antonyms = const Value.absent(),
            Value<String> importantSynonyms = const Value.absent(),
            Value<String> importantAntonyms = const Value.absent(),
            Value<String> notes = const Value.absent(),
            Value<bool> isFavorite = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              WordsCompanion(
            id: id,
            notebookId: notebookId,
            headwordNorm: headwordNorm,
            headwordDisplay: headwordDisplay,
            partOfSpeech: partOfSpeech,
            ipa: ipa,
            meaning: meaning,
            exampleSentence: exampleSentence,
            synonyms: synonyms,
            antonyms: antonyms,
            importantSynonyms: importantSynonyms,
            importantAntonyms: importantAntonyms,
            notes: notes,
            isFavorite: isFavorite,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int notebookId,
            required String headwordNorm,
            required String headwordDisplay,
            Value<String> partOfSpeech = const Value.absent(),
            Value<String> ipa = const Value.absent(),
            Value<String> meaning = const Value.absent(),
            Value<String> exampleSentence = const Value.absent(),
            Value<String> synonyms = const Value.absent(),
            Value<String> antonyms = const Value.absent(),
            Value<String> importantSynonyms = const Value.absent(),
            Value<String> importantAntonyms = const Value.absent(),
            Value<String> notes = const Value.absent(),
            Value<bool> isFavorite = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              WordsCompanion.insert(
            id: id,
            notebookId: notebookId,
            headwordNorm: headwordNorm,
            headwordDisplay: headwordDisplay,
            partOfSpeech: partOfSpeech,
            ipa: ipa,
            meaning: meaning,
            exampleSentence: exampleSentence,
            synonyms: synonyms,
            antonyms: antonyms,
            importantSynonyms: importantSynonyms,
            importantAntonyms: importantAntonyms,
            notes: notes,
            isFavorite: isFavorite,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$WordsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {notebookId = false,
              wordTranslationsRefs = false,
              wordTagsRefs = false,
              pendingEnrichmentsRefs = false,
              quizQuestionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (wordTranslationsRefs) db.wordTranslations,
                if (wordTagsRefs) db.wordTags,
                if (pendingEnrichmentsRefs) db.pendingEnrichments,
                if (quizQuestionsRefs) db.quizQuestions
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (notebookId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.notebookId,
                    referencedTable:
                        $$WordsTableReferences._notebookIdTable(db),
                    referencedColumn:
                        $$WordsTableReferences._notebookIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (wordTranslationsRefs)
                    await $_getPrefetchedData<WordRow, $WordsTable,
                            WordTranslationRow>(
                        currentTable: table,
                        referencedTable: $$WordsTableReferences
                            ._wordTranslationsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$WordsTableReferences(db, table, p0)
                                .wordTranslationsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.wordId == item.id),
                        typedResults: items),
                  if (wordTagsRefs)
                    await $_getPrefetchedData<WordRow, $WordsTable, WordTagRow>(
                        currentTable: table,
                        referencedTable:
                            $$WordsTableReferences._wordTagsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$WordsTableReferences(db, table, p0).wordTagsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.wordId == item.id),
                        typedResults: items),
                  if (pendingEnrichmentsRefs)
                    await $_getPrefetchedData<WordRow, $WordsTable,
                            PendingEnrichmentRow>(
                        currentTable: table,
                        referencedTable: $$WordsTableReferences
                            ._pendingEnrichmentsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$WordsTableReferences(db, table, p0)
                                .pendingEnrichmentsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.wordId == item.id),
                        typedResults: items),
                  if (quizQuestionsRefs)
                    await $_getPrefetchedData<WordRow, $WordsTable,
                            QuizQuestionRow>(
                        currentTable: table,
                        referencedTable:
                            $$WordsTableReferences._quizQuestionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$WordsTableReferences(db, table, p0)
                                .quizQuestionsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.wordId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$WordsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $WordsTable,
    WordRow,
    $$WordsTableFilterComposer,
    $$WordsTableOrderingComposer,
    $$WordsTableAnnotationComposer,
    $$WordsTableCreateCompanionBuilder,
    $$WordsTableUpdateCompanionBuilder,
    (WordRow, $$WordsTableReferences),
    WordRow,
    PrefetchHooks Function(
        {bool notebookId,
        bool wordTranslationsRefs,
        bool wordTagsRefs,
        bool pendingEnrichmentsRefs,
        bool quizQuestionsRefs})>;
typedef $$WordTranslationsTableCreateCompanionBuilder
    = WordTranslationsCompanion Function({
  required int wordId,
  required String langCode,
  required String translation,
  Value<int> rowid,
});
typedef $$WordTranslationsTableUpdateCompanionBuilder
    = WordTranslationsCompanion Function({
  Value<int> wordId,
  Value<String> langCode,
  Value<String> translation,
  Value<int> rowid,
});

final class $$WordTranslationsTableReferences extends BaseReferences<
    _$AppDatabase, $WordTranslationsTable, WordTranslationRow> {
  $$WordTranslationsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $WordsTable _wordIdTable(_$AppDatabase db) =>
      db.words.createAlias('word_translations__word_id__words__id');

  $$WordsTableProcessedTableManager get wordId {
    final $_column = $_itemColumn<int>('word_id')!;

    final manager = $$WordsTableTableManager($_db, $_db.words)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_wordIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$WordTranslationsTableFilterComposer
    extends Composer<_$AppDatabase, $WordTranslationsTable> {
  $$WordTranslationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get langCode => $composableBuilder(
      column: $table.langCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get translation => $composableBuilder(
      column: $table.translation, builder: (column) => ColumnFilters(column));

  $$WordsTableFilterComposer get wordId {
    final $$WordsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.wordId,
        referencedTable: $db.words,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WordsTableFilterComposer(
              $db: $db,
              $table: $db.words,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$WordTranslationsTableOrderingComposer
    extends Composer<_$AppDatabase, $WordTranslationsTable> {
  $$WordTranslationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get langCode => $composableBuilder(
      column: $table.langCode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get translation => $composableBuilder(
      column: $table.translation, builder: (column) => ColumnOrderings(column));

  $$WordsTableOrderingComposer get wordId {
    final $$WordsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.wordId,
        referencedTable: $db.words,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WordsTableOrderingComposer(
              $db: $db,
              $table: $db.words,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$WordTranslationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WordTranslationsTable> {
  $$WordTranslationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get langCode =>
      $composableBuilder(column: $table.langCode, builder: (column) => column);

  GeneratedColumn<String> get translation => $composableBuilder(
      column: $table.translation, builder: (column) => column);

  $$WordsTableAnnotationComposer get wordId {
    final $$WordsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.wordId,
        referencedTable: $db.words,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WordsTableAnnotationComposer(
              $db: $db,
              $table: $db.words,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$WordTranslationsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $WordTranslationsTable,
    WordTranslationRow,
    $$WordTranslationsTableFilterComposer,
    $$WordTranslationsTableOrderingComposer,
    $$WordTranslationsTableAnnotationComposer,
    $$WordTranslationsTableCreateCompanionBuilder,
    $$WordTranslationsTableUpdateCompanionBuilder,
    (WordTranslationRow, $$WordTranslationsTableReferences),
    WordTranslationRow,
    PrefetchHooks Function({bool wordId})> {
  $$WordTranslationsTableTableManager(
      _$AppDatabase db, $WordTranslationsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WordTranslationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WordTranslationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WordTranslationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> wordId = const Value.absent(),
            Value<String> langCode = const Value.absent(),
            Value<String> translation = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              WordTranslationsCompanion(
            wordId: wordId,
            langCode: langCode,
            translation: translation,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int wordId,
            required String langCode,
            required String translation,
            Value<int> rowid = const Value.absent(),
          }) =>
              WordTranslationsCompanion.insert(
            wordId: wordId,
            langCode: langCode,
            translation: translation,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$WordTranslationsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({wordId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (wordId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.wordId,
                    referencedTable:
                        $$WordTranslationsTableReferences._wordIdTable(db),
                    referencedColumn:
                        $$WordTranslationsTableReferences._wordIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$WordTranslationsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $WordTranslationsTable,
    WordTranslationRow,
    $$WordTranslationsTableFilterComposer,
    $$WordTranslationsTableOrderingComposer,
    $$WordTranslationsTableAnnotationComposer,
    $$WordTranslationsTableCreateCompanionBuilder,
    $$WordTranslationsTableUpdateCompanionBuilder,
    (WordTranslationRow, $$WordTranslationsTableReferences),
    WordTranslationRow,
    PrefetchHooks Function({bool wordId})>;
typedef $$TagsTableCreateCompanionBuilder = TagsCompanion Function({
  Value<int> id,
  required String name,
});
typedef $$TagsTableUpdateCompanionBuilder = TagsCompanion Function({
  Value<int> id,
  Value<String> name,
});

final class $$TagsTableReferences
    extends BaseReferences<_$AppDatabase, $TagsTable, TagRow> {
  $$TagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$WordTagsTable, List<WordTagRow>>
      _wordTagsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.wordTags,
              aliasName: 'tags__id__word_tags__tag_id');

  $$WordTagsTableProcessedTableManager get wordTagsRefs {
    final manager = $$WordTagsTableTableManager($_db, $_db.wordTags)
        .filter((f) => f.tagId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_wordTagsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$TagsTableFilterComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  Expression<bool> wordTagsRefs(
      Expression<bool> Function($$WordTagsTableFilterComposer f) f) {
    final $$WordTagsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.wordTags,
        getReferencedColumn: (t) => t.tagId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WordTagsTableFilterComposer(
              $db: $db,
              $table: $db.wordTags,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$TagsTableOrderingComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));
}

class $$TagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  Expression<T> wordTagsRefs<T extends Object>(
      Expression<T> Function($$WordTagsTableAnnotationComposer a) f) {
    final $$WordTagsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.wordTags,
        getReferencedColumn: (t) => t.tagId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WordTagsTableAnnotationComposer(
              $db: $db,
              $table: $db.wordTags,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$TagsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TagsTable,
    TagRow,
    $$TagsTableFilterComposer,
    $$TagsTableOrderingComposer,
    $$TagsTableAnnotationComposer,
    $$TagsTableCreateCompanionBuilder,
    $$TagsTableUpdateCompanionBuilder,
    (TagRow, $$TagsTableReferences),
    TagRow,
    PrefetchHooks Function({bool wordTagsRefs})> {
  $$TagsTableTableManager(_$AppDatabase db, $TagsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
          }) =>
              TagsCompanion(
            id: id,
            name: name,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
          }) =>
              TagsCompanion.insert(
            id: id,
            name: name,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$TagsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({wordTagsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (wordTagsRefs) db.wordTags],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (wordTagsRefs)
                    await $_getPrefetchedData<TagRow, $TagsTable, WordTagRow>(
                        currentTable: table,
                        referencedTable:
                            $$TagsTableReferences._wordTagsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$TagsTableReferences(db, table, p0).wordTagsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.tagId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$TagsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TagsTable,
    TagRow,
    $$TagsTableFilterComposer,
    $$TagsTableOrderingComposer,
    $$TagsTableAnnotationComposer,
    $$TagsTableCreateCompanionBuilder,
    $$TagsTableUpdateCompanionBuilder,
    (TagRow, $$TagsTableReferences),
    TagRow,
    PrefetchHooks Function({bool wordTagsRefs})>;
typedef $$WordTagsTableCreateCompanionBuilder = WordTagsCompanion Function({
  required int wordId,
  required int tagId,
  Value<int> rowid,
});
typedef $$WordTagsTableUpdateCompanionBuilder = WordTagsCompanion Function({
  Value<int> wordId,
  Value<int> tagId,
  Value<int> rowid,
});

final class $$WordTagsTableReferences
    extends BaseReferences<_$AppDatabase, $WordTagsTable, WordTagRow> {
  $$WordTagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WordsTable _wordIdTable(_$AppDatabase db) =>
      db.words.createAlias('word_tags__word_id__words__id');

  $$WordsTableProcessedTableManager get wordId {
    final $_column = $_itemColumn<int>('word_id')!;

    final manager = $$WordsTableTableManager($_db, $_db.words)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_wordIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $TagsTable _tagIdTable(_$AppDatabase db) =>
      db.tags.createAlias('word_tags__tag_id__tags__id');

  $$TagsTableProcessedTableManager get tagId {
    final $_column = $_itemColumn<int>('tag_id')!;

    final manager = $$TagsTableTableManager($_db, $_db.tags)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tagIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$WordTagsTableFilterComposer
    extends Composer<_$AppDatabase, $WordTagsTable> {
  $$WordTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$WordsTableFilterComposer get wordId {
    final $$WordsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.wordId,
        referencedTable: $db.words,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WordsTableFilterComposer(
              $db: $db,
              $table: $db.words,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$TagsTableFilterComposer get tagId {
    final $$TagsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.tagId,
        referencedTable: $db.tags,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TagsTableFilterComposer(
              $db: $db,
              $table: $db.tags,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$WordTagsTableOrderingComposer
    extends Composer<_$AppDatabase, $WordTagsTable> {
  $$WordTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$WordsTableOrderingComposer get wordId {
    final $$WordsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.wordId,
        referencedTable: $db.words,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WordsTableOrderingComposer(
              $db: $db,
              $table: $db.words,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$TagsTableOrderingComposer get tagId {
    final $$TagsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.tagId,
        referencedTable: $db.tags,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TagsTableOrderingComposer(
              $db: $db,
              $table: $db.tags,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$WordTagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WordTagsTable> {
  $$WordTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$WordsTableAnnotationComposer get wordId {
    final $$WordsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.wordId,
        referencedTable: $db.words,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WordsTableAnnotationComposer(
              $db: $db,
              $table: $db.words,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$TagsTableAnnotationComposer get tagId {
    final $$TagsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.tagId,
        referencedTable: $db.tags,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TagsTableAnnotationComposer(
              $db: $db,
              $table: $db.tags,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$WordTagsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $WordTagsTable,
    WordTagRow,
    $$WordTagsTableFilterComposer,
    $$WordTagsTableOrderingComposer,
    $$WordTagsTableAnnotationComposer,
    $$WordTagsTableCreateCompanionBuilder,
    $$WordTagsTableUpdateCompanionBuilder,
    (WordTagRow, $$WordTagsTableReferences),
    WordTagRow,
    PrefetchHooks Function({bool wordId, bool tagId})> {
  $$WordTagsTableTableManager(_$AppDatabase db, $WordTagsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WordTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WordTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WordTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> wordId = const Value.absent(),
            Value<int> tagId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              WordTagsCompanion(
            wordId: wordId,
            tagId: tagId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int wordId,
            required int tagId,
            Value<int> rowid = const Value.absent(),
          }) =>
              WordTagsCompanion.insert(
            wordId: wordId,
            tagId: tagId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$WordTagsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({wordId = false, tagId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (wordId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.wordId,
                    referencedTable: $$WordTagsTableReferences._wordIdTable(db),
                    referencedColumn:
                        $$WordTagsTableReferences._wordIdTable(db).id,
                  ) as T;
                }
                if (tagId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.tagId,
                    referencedTable: $$WordTagsTableReferences._tagIdTable(db),
                    referencedColumn:
                        $$WordTagsTableReferences._tagIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$WordTagsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $WordTagsTable,
    WordTagRow,
    $$WordTagsTableFilterComposer,
    $$WordTagsTableOrderingComposer,
    $$WordTagsTableAnnotationComposer,
    $$WordTagsTableCreateCompanionBuilder,
    $$WordTagsTableUpdateCompanionBuilder,
    (WordTagRow, $$WordTagsTableReferences),
    WordTagRow,
    PrefetchHooks Function({bool wordId, bool tagId})>;
typedef $$PendingEnrichmentsTableCreateCompanionBuilder
    = PendingEnrichmentsCompanion Function({
  Value<int> id,
  required int wordId,
  Value<int> attempts,
  Value<String?> lastError,
  Value<DateTime> createdAt,
  Value<DateTime> nextAttemptAt,
});
typedef $$PendingEnrichmentsTableUpdateCompanionBuilder
    = PendingEnrichmentsCompanion Function({
  Value<int> id,
  Value<int> wordId,
  Value<int> attempts,
  Value<String?> lastError,
  Value<DateTime> createdAt,
  Value<DateTime> nextAttemptAt,
});

final class $$PendingEnrichmentsTableReferences extends BaseReferences<
    _$AppDatabase, $PendingEnrichmentsTable, PendingEnrichmentRow> {
  $$PendingEnrichmentsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $WordsTable _wordIdTable(_$AppDatabase db) =>
      db.words.createAlias('pending_enrichments__word_id__words__id');

  $$WordsTableProcessedTableManager get wordId {
    final $_column = $_itemColumn<int>('word_id')!;

    final manager = $$WordsTableTableManager($_db, $_db.words)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_wordIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$PendingEnrichmentsTableFilterComposer
    extends Composer<_$AppDatabase, $PendingEnrichmentsTable> {
  $$PendingEnrichmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get attempts => $composableBuilder(
      column: $table.attempts, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get nextAttemptAt => $composableBuilder(
      column: $table.nextAttemptAt, builder: (column) => ColumnFilters(column));

  $$WordsTableFilterComposer get wordId {
    final $$WordsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.wordId,
        referencedTable: $db.words,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WordsTableFilterComposer(
              $db: $db,
              $table: $db.words,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PendingEnrichmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingEnrichmentsTable> {
  $$PendingEnrichmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get attempts => $composableBuilder(
      column: $table.attempts, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get nextAttemptAt => $composableBuilder(
      column: $table.nextAttemptAt,
      builder: (column) => ColumnOrderings(column));

  $$WordsTableOrderingComposer get wordId {
    final $$WordsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.wordId,
        referencedTable: $db.words,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WordsTableOrderingComposer(
              $db: $db,
              $table: $db.words,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PendingEnrichmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingEnrichmentsTable> {
  $$PendingEnrichmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get nextAttemptAt => $composableBuilder(
      column: $table.nextAttemptAt, builder: (column) => column);

  $$WordsTableAnnotationComposer get wordId {
    final $$WordsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.wordId,
        referencedTable: $db.words,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WordsTableAnnotationComposer(
              $db: $db,
              $table: $db.words,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PendingEnrichmentsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PendingEnrichmentsTable,
    PendingEnrichmentRow,
    $$PendingEnrichmentsTableFilterComposer,
    $$PendingEnrichmentsTableOrderingComposer,
    $$PendingEnrichmentsTableAnnotationComposer,
    $$PendingEnrichmentsTableCreateCompanionBuilder,
    $$PendingEnrichmentsTableUpdateCompanionBuilder,
    (PendingEnrichmentRow, $$PendingEnrichmentsTableReferences),
    PendingEnrichmentRow,
    PrefetchHooks Function({bool wordId})> {
  $$PendingEnrichmentsTableTableManager(
      _$AppDatabase db, $PendingEnrichmentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingEnrichmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingEnrichmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingEnrichmentsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> wordId = const Value.absent(),
            Value<int> attempts = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> nextAttemptAt = const Value.absent(),
          }) =>
              PendingEnrichmentsCompanion(
            id: id,
            wordId: wordId,
            attempts: attempts,
            lastError: lastError,
            createdAt: createdAt,
            nextAttemptAt: nextAttemptAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int wordId,
            Value<int> attempts = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> nextAttemptAt = const Value.absent(),
          }) =>
              PendingEnrichmentsCompanion.insert(
            id: id,
            wordId: wordId,
            attempts: attempts,
            lastError: lastError,
            createdAt: createdAt,
            nextAttemptAt: nextAttemptAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$PendingEnrichmentsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({wordId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (wordId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.wordId,
                    referencedTable:
                        $$PendingEnrichmentsTableReferences._wordIdTable(db),
                    referencedColumn:
                        $$PendingEnrichmentsTableReferences._wordIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$PendingEnrichmentsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PendingEnrichmentsTable,
    PendingEnrichmentRow,
    $$PendingEnrichmentsTableFilterComposer,
    $$PendingEnrichmentsTableOrderingComposer,
    $$PendingEnrichmentsTableAnnotationComposer,
    $$PendingEnrichmentsTableCreateCompanionBuilder,
    $$PendingEnrichmentsTableUpdateCompanionBuilder,
    (PendingEnrichmentRow, $$PendingEnrichmentsTableReferences),
    PendingEnrichmentRow,
    PrefetchHooks Function({bool wordId})>;
typedef $$QuizAttemptsTableCreateCompanionBuilder = QuizAttemptsCompanion
    Function({
  Value<int> id,
  Value<int?> notebookId,
  required int totalQuestions,
  Value<int> correctCount,
  Value<String> questionType,
  Value<String> sourceLabel,
  Value<String> provider,
  Value<int> timeTakenSecs,
  Value<DateTime> startedAt,
  Value<DateTime?> finishedAt,
});
typedef $$QuizAttemptsTableUpdateCompanionBuilder = QuizAttemptsCompanion
    Function({
  Value<int> id,
  Value<int?> notebookId,
  Value<int> totalQuestions,
  Value<int> correctCount,
  Value<String> questionType,
  Value<String> sourceLabel,
  Value<String> provider,
  Value<int> timeTakenSecs,
  Value<DateTime> startedAt,
  Value<DateTime?> finishedAt,
});

final class $$QuizAttemptsTableReferences
    extends BaseReferences<_$AppDatabase, $QuizAttemptsTable, QuizAttemptRow> {
  $$QuizAttemptsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $NotebooksTable _notebookIdTable(_$AppDatabase db) =>
      db.notebooks.createAlias('quiz_attempts__notebook_id__notebooks__id');

  $$NotebooksTableProcessedTableManager? get notebookId {
    final $_column = $_itemColumn<int>('notebook_id');
    if ($_column == null) return null;
    final manager = $$NotebooksTableTableManager($_db, $_db.notebooks)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_notebookIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$QuizQuestionsTable, List<QuizQuestionRow>>
      _quizQuestionsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.quizQuestions,
              aliasName: 'quiz_attempts__id__quiz_questions__attempt_id');

  $$QuizQuestionsTableProcessedTableManager get quizQuestionsRefs {
    final manager = $$QuizQuestionsTableTableManager($_db, $_db.quizQuestions)
        .filter((f) => f.attemptId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_quizQuestionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$QuizAttemptsTableFilterComposer
    extends Composer<_$AppDatabase, $QuizAttemptsTable> {
  $$QuizAttemptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalQuestions => $composableBuilder(
      column: $table.totalQuestions,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get correctCount => $composableBuilder(
      column: $table.correctCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get questionType => $composableBuilder(
      column: $table.questionType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceLabel => $composableBuilder(
      column: $table.sourceLabel, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get provider => $composableBuilder(
      column: $table.provider, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get timeTakenSecs => $composableBuilder(
      column: $table.timeTakenSecs, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get finishedAt => $composableBuilder(
      column: $table.finishedAt, builder: (column) => ColumnFilters(column));

  $$NotebooksTableFilterComposer get notebookId {
    final $$NotebooksTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.notebookId,
        referencedTable: $db.notebooks,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$NotebooksTableFilterComposer(
              $db: $db,
              $table: $db.notebooks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> quizQuestionsRefs(
      Expression<bool> Function($$QuizQuestionsTableFilterComposer f) f) {
    final $$QuizQuestionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.quizQuestions,
        getReferencedColumn: (t) => t.attemptId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$QuizQuestionsTableFilterComposer(
              $db: $db,
              $table: $db.quizQuestions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$QuizAttemptsTableOrderingComposer
    extends Composer<_$AppDatabase, $QuizAttemptsTable> {
  $$QuizAttemptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalQuestions => $composableBuilder(
      column: $table.totalQuestions,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get correctCount => $composableBuilder(
      column: $table.correctCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get questionType => $composableBuilder(
      column: $table.questionType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceLabel => $composableBuilder(
      column: $table.sourceLabel, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get provider => $composableBuilder(
      column: $table.provider, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get timeTakenSecs => $composableBuilder(
      column: $table.timeTakenSecs,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get finishedAt => $composableBuilder(
      column: $table.finishedAt, builder: (column) => ColumnOrderings(column));

  $$NotebooksTableOrderingComposer get notebookId {
    final $$NotebooksTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.notebookId,
        referencedTable: $db.notebooks,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$NotebooksTableOrderingComposer(
              $db: $db,
              $table: $db.notebooks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$QuizAttemptsTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuizAttemptsTable> {
  $$QuizAttemptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get totalQuestions => $composableBuilder(
      column: $table.totalQuestions, builder: (column) => column);

  GeneratedColumn<int> get correctCount => $composableBuilder(
      column: $table.correctCount, builder: (column) => column);

  GeneratedColumn<String> get questionType => $composableBuilder(
      column: $table.questionType, builder: (column) => column);

  GeneratedColumn<String> get sourceLabel => $composableBuilder(
      column: $table.sourceLabel, builder: (column) => column);

  GeneratedColumn<String> get provider =>
      $composableBuilder(column: $table.provider, builder: (column) => column);

  GeneratedColumn<int> get timeTakenSecs => $composableBuilder(
      column: $table.timeTakenSecs, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get finishedAt => $composableBuilder(
      column: $table.finishedAt, builder: (column) => column);

  $$NotebooksTableAnnotationComposer get notebookId {
    final $$NotebooksTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.notebookId,
        referencedTable: $db.notebooks,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$NotebooksTableAnnotationComposer(
              $db: $db,
              $table: $db.notebooks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> quizQuestionsRefs<T extends Object>(
      Expression<T> Function($$QuizQuestionsTableAnnotationComposer a) f) {
    final $$QuizQuestionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.quizQuestions,
        getReferencedColumn: (t) => t.attemptId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$QuizQuestionsTableAnnotationComposer(
              $db: $db,
              $table: $db.quizQuestions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$QuizAttemptsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $QuizAttemptsTable,
    QuizAttemptRow,
    $$QuizAttemptsTableFilterComposer,
    $$QuizAttemptsTableOrderingComposer,
    $$QuizAttemptsTableAnnotationComposer,
    $$QuizAttemptsTableCreateCompanionBuilder,
    $$QuizAttemptsTableUpdateCompanionBuilder,
    (QuizAttemptRow, $$QuizAttemptsTableReferences),
    QuizAttemptRow,
    PrefetchHooks Function({bool notebookId, bool quizQuestionsRefs})> {
  $$QuizAttemptsTableTableManager(_$AppDatabase db, $QuizAttemptsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuizAttemptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuizAttemptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuizAttemptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> notebookId = const Value.absent(),
            Value<int> totalQuestions = const Value.absent(),
            Value<int> correctCount = const Value.absent(),
            Value<String> questionType = const Value.absent(),
            Value<String> sourceLabel = const Value.absent(),
            Value<String> provider = const Value.absent(),
            Value<int> timeTakenSecs = const Value.absent(),
            Value<DateTime> startedAt = const Value.absent(),
            Value<DateTime?> finishedAt = const Value.absent(),
          }) =>
              QuizAttemptsCompanion(
            id: id,
            notebookId: notebookId,
            totalQuestions: totalQuestions,
            correctCount: correctCount,
            questionType: questionType,
            sourceLabel: sourceLabel,
            provider: provider,
            timeTakenSecs: timeTakenSecs,
            startedAt: startedAt,
            finishedAt: finishedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> notebookId = const Value.absent(),
            required int totalQuestions,
            Value<int> correctCount = const Value.absent(),
            Value<String> questionType = const Value.absent(),
            Value<String> sourceLabel = const Value.absent(),
            Value<String> provider = const Value.absent(),
            Value<int> timeTakenSecs = const Value.absent(),
            Value<DateTime> startedAt = const Value.absent(),
            Value<DateTime?> finishedAt = const Value.absent(),
          }) =>
              QuizAttemptsCompanion.insert(
            id: id,
            notebookId: notebookId,
            totalQuestions: totalQuestions,
            correctCount: correctCount,
            questionType: questionType,
            sourceLabel: sourceLabel,
            provider: provider,
            timeTakenSecs: timeTakenSecs,
            startedAt: startedAt,
            finishedAt: finishedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$QuizAttemptsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {notebookId = false, quizQuestionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (quizQuestionsRefs) db.quizQuestions
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (notebookId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.notebookId,
                    referencedTable:
                        $$QuizAttemptsTableReferences._notebookIdTable(db),
                    referencedColumn:
                        $$QuizAttemptsTableReferences._notebookIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (quizQuestionsRefs)
                    await $_getPrefetchedData<QuizAttemptRow,
                            $QuizAttemptsTable, QuizQuestionRow>(
                        currentTable: table,
                        referencedTable: $$QuizAttemptsTableReferences
                            ._quizQuestionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$QuizAttemptsTableReferences(db, table, p0)
                                .quizQuestionsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.attemptId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$QuizAttemptsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $QuizAttemptsTable,
    QuizAttemptRow,
    $$QuizAttemptsTableFilterComposer,
    $$QuizAttemptsTableOrderingComposer,
    $$QuizAttemptsTableAnnotationComposer,
    $$QuizAttemptsTableCreateCompanionBuilder,
    $$QuizAttemptsTableUpdateCompanionBuilder,
    (QuizAttemptRow, $$QuizAttemptsTableReferences),
    QuizAttemptRow,
    PrefetchHooks Function({bool notebookId, bool quizQuestionsRefs})>;
typedef $$QuizQuestionsTableCreateCompanionBuilder = QuizQuestionsCompanion
    Function({
  Value<int> id,
  required int attemptId,
  required int wordId,
  required String prompt,
  Value<String> questionText,
  Value<String> questionType,
  Value<String> explanation,
  required String correctAnswer,
  required String optionsJson,
  Value<String?> chosenAnswer,
  Value<bool?> wasCorrect,
  Value<DateTime?> answeredAt,
});
typedef $$QuizQuestionsTableUpdateCompanionBuilder = QuizQuestionsCompanion
    Function({
  Value<int> id,
  Value<int> attemptId,
  Value<int> wordId,
  Value<String> prompt,
  Value<String> questionText,
  Value<String> questionType,
  Value<String> explanation,
  Value<String> correctAnswer,
  Value<String> optionsJson,
  Value<String?> chosenAnswer,
  Value<bool?> wasCorrect,
  Value<DateTime?> answeredAt,
});

final class $$QuizQuestionsTableReferences extends BaseReferences<_$AppDatabase,
    $QuizQuestionsTable, QuizQuestionRow> {
  $$QuizQuestionsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $QuizAttemptsTable _attemptIdTable(_$AppDatabase db) => db.quizAttempts
      .createAlias('quiz_questions__attempt_id__quiz_attempts__id');

  $$QuizAttemptsTableProcessedTableManager get attemptId {
    final $_column = $_itemColumn<int>('attempt_id')!;

    final manager = $$QuizAttemptsTableTableManager($_db, $_db.quizAttempts)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_attemptIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $WordsTable _wordIdTable(_$AppDatabase db) =>
      db.words.createAlias('quiz_questions__word_id__words__id');

  $$WordsTableProcessedTableManager get wordId {
    final $_column = $_itemColumn<int>('word_id')!;

    final manager = $$WordsTableTableManager($_db, $_db.words)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_wordIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$QuizQuestionsTableFilterComposer
    extends Composer<_$AppDatabase, $QuizQuestionsTable> {
  $$QuizQuestionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get prompt => $composableBuilder(
      column: $table.prompt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get questionText => $composableBuilder(
      column: $table.questionText, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get questionType => $composableBuilder(
      column: $table.questionType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get explanation => $composableBuilder(
      column: $table.explanation, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get correctAnswer => $composableBuilder(
      column: $table.correctAnswer, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get optionsJson => $composableBuilder(
      column: $table.optionsJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get chosenAnswer => $composableBuilder(
      column: $table.chosenAnswer, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get wasCorrect => $composableBuilder(
      column: $table.wasCorrect, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get answeredAt => $composableBuilder(
      column: $table.answeredAt, builder: (column) => ColumnFilters(column));

  $$QuizAttemptsTableFilterComposer get attemptId {
    final $$QuizAttemptsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.attemptId,
        referencedTable: $db.quizAttempts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$QuizAttemptsTableFilterComposer(
              $db: $db,
              $table: $db.quizAttempts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$WordsTableFilterComposer get wordId {
    final $$WordsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.wordId,
        referencedTable: $db.words,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WordsTableFilterComposer(
              $db: $db,
              $table: $db.words,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$QuizQuestionsTableOrderingComposer
    extends Composer<_$AppDatabase, $QuizQuestionsTable> {
  $$QuizQuestionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get prompt => $composableBuilder(
      column: $table.prompt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get questionText => $composableBuilder(
      column: $table.questionText,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get questionType => $composableBuilder(
      column: $table.questionType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get explanation => $composableBuilder(
      column: $table.explanation, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get correctAnswer => $composableBuilder(
      column: $table.correctAnswer,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get optionsJson => $composableBuilder(
      column: $table.optionsJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get chosenAnswer => $composableBuilder(
      column: $table.chosenAnswer,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get wasCorrect => $composableBuilder(
      column: $table.wasCorrect, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get answeredAt => $composableBuilder(
      column: $table.answeredAt, builder: (column) => ColumnOrderings(column));

  $$QuizAttemptsTableOrderingComposer get attemptId {
    final $$QuizAttemptsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.attemptId,
        referencedTable: $db.quizAttempts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$QuizAttemptsTableOrderingComposer(
              $db: $db,
              $table: $db.quizAttempts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$WordsTableOrderingComposer get wordId {
    final $$WordsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.wordId,
        referencedTable: $db.words,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WordsTableOrderingComposer(
              $db: $db,
              $table: $db.words,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$QuizQuestionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuizQuestionsTable> {
  $$QuizQuestionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get prompt =>
      $composableBuilder(column: $table.prompt, builder: (column) => column);

  GeneratedColumn<String> get questionText => $composableBuilder(
      column: $table.questionText, builder: (column) => column);

  GeneratedColumn<String> get questionType => $composableBuilder(
      column: $table.questionType, builder: (column) => column);

  GeneratedColumn<String> get explanation => $composableBuilder(
      column: $table.explanation, builder: (column) => column);

  GeneratedColumn<String> get correctAnswer => $composableBuilder(
      column: $table.correctAnswer, builder: (column) => column);

  GeneratedColumn<String> get optionsJson => $composableBuilder(
      column: $table.optionsJson, builder: (column) => column);

  GeneratedColumn<String> get chosenAnswer => $composableBuilder(
      column: $table.chosenAnswer, builder: (column) => column);

  GeneratedColumn<bool> get wasCorrect => $composableBuilder(
      column: $table.wasCorrect, builder: (column) => column);

  GeneratedColumn<DateTime> get answeredAt => $composableBuilder(
      column: $table.answeredAt, builder: (column) => column);

  $$QuizAttemptsTableAnnotationComposer get attemptId {
    final $$QuizAttemptsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.attemptId,
        referencedTable: $db.quizAttempts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$QuizAttemptsTableAnnotationComposer(
              $db: $db,
              $table: $db.quizAttempts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$WordsTableAnnotationComposer get wordId {
    final $$WordsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.wordId,
        referencedTable: $db.words,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WordsTableAnnotationComposer(
              $db: $db,
              $table: $db.words,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$QuizQuestionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $QuizQuestionsTable,
    QuizQuestionRow,
    $$QuizQuestionsTableFilterComposer,
    $$QuizQuestionsTableOrderingComposer,
    $$QuizQuestionsTableAnnotationComposer,
    $$QuizQuestionsTableCreateCompanionBuilder,
    $$QuizQuestionsTableUpdateCompanionBuilder,
    (QuizQuestionRow, $$QuizQuestionsTableReferences),
    QuizQuestionRow,
    PrefetchHooks Function({bool attemptId, bool wordId})> {
  $$QuizQuestionsTableTableManager(_$AppDatabase db, $QuizQuestionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuizQuestionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuizQuestionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuizQuestionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> attemptId = const Value.absent(),
            Value<int> wordId = const Value.absent(),
            Value<String> prompt = const Value.absent(),
            Value<String> questionText = const Value.absent(),
            Value<String> questionType = const Value.absent(),
            Value<String> explanation = const Value.absent(),
            Value<String> correctAnswer = const Value.absent(),
            Value<String> optionsJson = const Value.absent(),
            Value<String?> chosenAnswer = const Value.absent(),
            Value<bool?> wasCorrect = const Value.absent(),
            Value<DateTime?> answeredAt = const Value.absent(),
          }) =>
              QuizQuestionsCompanion(
            id: id,
            attemptId: attemptId,
            wordId: wordId,
            prompt: prompt,
            questionText: questionText,
            questionType: questionType,
            explanation: explanation,
            correctAnswer: correctAnswer,
            optionsJson: optionsJson,
            chosenAnswer: chosenAnswer,
            wasCorrect: wasCorrect,
            answeredAt: answeredAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int attemptId,
            required int wordId,
            required String prompt,
            Value<String> questionText = const Value.absent(),
            Value<String> questionType = const Value.absent(),
            Value<String> explanation = const Value.absent(),
            required String correctAnswer,
            required String optionsJson,
            Value<String?> chosenAnswer = const Value.absent(),
            Value<bool?> wasCorrect = const Value.absent(),
            Value<DateTime?> answeredAt = const Value.absent(),
          }) =>
              QuizQuestionsCompanion.insert(
            id: id,
            attemptId: attemptId,
            wordId: wordId,
            prompt: prompt,
            questionText: questionText,
            questionType: questionType,
            explanation: explanation,
            correctAnswer: correctAnswer,
            optionsJson: optionsJson,
            chosenAnswer: chosenAnswer,
            wasCorrect: wasCorrect,
            answeredAt: answeredAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$QuizQuestionsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({attemptId = false, wordId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (attemptId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.attemptId,
                    referencedTable:
                        $$QuizQuestionsTableReferences._attemptIdTable(db),
                    referencedColumn:
                        $$QuizQuestionsTableReferences._attemptIdTable(db).id,
                  ) as T;
                }
                if (wordId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.wordId,
                    referencedTable:
                        $$QuizQuestionsTableReferences._wordIdTable(db),
                    referencedColumn:
                        $$QuizQuestionsTableReferences._wordIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$QuizQuestionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $QuizQuestionsTable,
    QuizQuestionRow,
    $$QuizQuestionsTableFilterComposer,
    $$QuizQuestionsTableOrderingComposer,
    $$QuizQuestionsTableAnnotationComposer,
    $$QuizQuestionsTableCreateCompanionBuilder,
    $$QuizQuestionsTableUpdateCompanionBuilder,
    (QuizQuestionRow, $$QuizQuestionsTableReferences),
    QuizQuestionRow,
    PrefetchHooks Function({bool attemptId, bool wordId})>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$NotebooksTableTableManager get notebooks =>
      $$NotebooksTableTableManager(_db, _db.notebooks);
  $$WordsTableTableManager get words =>
      $$WordsTableTableManager(_db, _db.words);
  $$WordTranslationsTableTableManager get wordTranslations =>
      $$WordTranslationsTableTableManager(_db, _db.wordTranslations);
  $$TagsTableTableManager get tags => $$TagsTableTableManager(_db, _db.tags);
  $$WordTagsTableTableManager get wordTags =>
      $$WordTagsTableTableManager(_db, _db.wordTags);
  $$PendingEnrichmentsTableTableManager get pendingEnrichments =>
      $$PendingEnrichmentsTableTableManager(_db, _db.pendingEnrichments);
  $$QuizAttemptsTableTableManager get quizAttempts =>
      $$QuizAttemptsTableTableManager(_db, _db.quizAttempts);
  $$QuizQuestionsTableTableManager get quizQuestions =>
      $$QuizQuestionsTableTableManager(_db, _db.quizQuestions);
}
