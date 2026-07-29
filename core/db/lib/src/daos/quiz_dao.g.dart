// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quiz_dao.dart';

// ignore_for_file: type=lint
mixin _$QuizDaoMixin on DatabaseAccessor<AppDatabase> {
  $NotebooksTable get notebooks => attachedDatabase.notebooks;
  $QuizAttemptsTable get quizAttempts => attachedDatabase.quizAttempts;
  $WordsTable get words => attachedDatabase.words;
  $QuizQuestionsTable get quizQuestions => attachedDatabase.quizQuestions;
  QuizDaoManager get managers => QuizDaoManager(this);
}

class QuizDaoManager {
  final _$QuizDaoMixin _db;
  QuizDaoManager(this._db);
  $$NotebooksTableTableManager get notebooks =>
      $$NotebooksTableTableManager(_db.attachedDatabase, _db.notebooks);
  $$QuizAttemptsTableTableManager get quizAttempts =>
      $$QuizAttemptsTableTableManager(_db.attachedDatabase, _db.quizAttempts);
  $$WordsTableTableManager get words =>
      $$WordsTableTableManager(_db.attachedDatabase, _db.words);
  $$QuizQuestionsTableTableManager get quizQuestions =>
      $$QuizQuestionsTableTableManager(_db.attachedDatabase, _db.quizQuestions);
}
