// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(notebookRepository)
final notebookRepositoryProvider = NotebookRepositoryProvider._();

final class NotebookRepositoryProvider extends $FunctionalProvider<
    NotebookRepository,
    NotebookRepository,
    NotebookRepository> with $Provider<NotebookRepository> {
  NotebookRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'notebookRepositoryProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$notebookRepositoryHash();

  @$internal
  @override
  $ProviderElement<NotebookRepository> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  NotebookRepository create(Ref ref) {
    return notebookRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NotebookRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NotebookRepository>(value),
    );
  }
}

String _$notebookRepositoryHash() =>
    r'858e821beebf97fb16eb1a3496fe1733f2564ac9';

@ProviderFor(notebooks)
final notebooksProvider = NotebooksProvider._();

final class NotebooksProvider extends $FunctionalProvider<
        AsyncValue<List<Notebook>>, List<Notebook>, Stream<List<Notebook>>>
    with $FutureModifier<List<Notebook>>, $StreamProvider<List<Notebook>> {
  NotebooksProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'notebooksProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$notebooksHash();

  @$internal
  @override
  $StreamProviderElement<List<Notebook>> $createElement(
          $ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<Notebook>> create(Ref ref) {
    return notebooks(ref);
  }
}

String _$notebooksHash() => r'c544304ae0a2f614bf4f915185a25dcf7e3107f6';

/// The word highlighted in the master-detail layout (null = nothing).

@ProviderFor(SelectedWordId)
final selectedWordIdProvider = SelectedWordIdProvider._();

/// The word highlighted in the master-detail layout (null = nothing).
final class SelectedWordIdProvider
    extends $NotifierProvider<SelectedWordId, int?> {
  /// The word highlighted in the master-detail layout (null = nothing).
  SelectedWordIdProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'selectedWordIdProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$selectedWordIdHash();

  @$internal
  @override
  SelectedWordId create() => SelectedWordId();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int?>(value),
    );
  }
}

String _$selectedWordIdHash() => r'f92d24f5921e4840612aec707542fab6bedb55cf';

/// The word highlighted in the master-detail layout (null = nothing).

abstract class _$SelectedWordId extends $Notifier<int?> {
  int? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int?, int?>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<int?, int?>, int?, Object?, Object?>;
    return element.handleCreate(ref, build);
  }
}

/// Tracks the ID of a recently added word for a 3-second highlight animation.

@ProviderFor(NewlyAddedWordId)
final newlyAddedWordIdProvider = NewlyAddedWordIdProvider._();

/// Tracks the ID of a recently added word for a 3-second highlight animation.
final class NewlyAddedWordIdProvider
    extends $NotifierProvider<NewlyAddedWordId, int?> {
  /// Tracks the ID of a recently added word for a 3-second highlight animation.
  NewlyAddedWordIdProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'newlyAddedWordIdProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$newlyAddedWordIdHash();

  @$internal
  @override
  NewlyAddedWordId create() => NewlyAddedWordId();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int?>(value),
    );
  }
}

String _$newlyAddedWordIdHash() => r'9ee7fd911d853e579ce2097a5450c020d5618242';

/// Tracks the ID of a recently added word for a 3-second highlight animation.

abstract class _$NewlyAddedWordId extends $Notifier<int?> {
  int? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int?, int?>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<int?, int?>, int?, Object?, Object?>;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(wordDetail)
final wordDetailProvider = WordDetailFamily._();

final class WordDetailProvider
    extends $FunctionalProvider<AsyncValue<Word?>, Word?, Stream<Word?>>
    with $FutureModifier<Word?>, $StreamProvider<Word?> {
  WordDetailProvider._(
      {required WordDetailFamily super.from, required int super.argument})
      : super(
          retry: null,
          name: r'wordDetailProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$wordDetailHash();

  @override
  String toString() {
    return r'wordDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Word?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Word?> create(Ref ref) {
    final argument = this.argument as int;
    return wordDetail(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is WordDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$wordDetailHash() => r'70574c0e934285614a2ec7ad1b9caeac15159b57';

final class WordDetailFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Word?>, int> {
  WordDetailFamily._()
      : super(
          retry: null,
          name: r'wordDetailProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  WordDetailProvider call(
    int wordId,
  ) =>
      WordDetailProvider._(argument: wordId, from: this);

  @override
  String toString() => r'wordDetailProvider';
}

@ProviderFor(wordTranslations)
final wordTranslationsProvider = WordTranslationsFamily._();

final class WordTranslationsProvider extends $FunctionalProvider<
        AsyncValue<Map<String, String>>,
        Map<String, String>,
        Stream<Map<String, String>>>
    with
        $FutureModifier<Map<String, String>>,
        $StreamProvider<Map<String, String>> {
  WordTranslationsProvider._(
      {required WordTranslationsFamily super.from, required int super.argument})
      : super(
          retry: null,
          name: r'wordTranslationsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$wordTranslationsHash();

  @override
  String toString() {
    return r'wordTranslationsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Map<String, String>> $createElement(
          $ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Map<String, String>> create(Ref ref) {
    final argument = this.argument as int;
    return wordTranslations(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is WordTranslationsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$wordTranslationsHash() => r'f123bc9022195145a4c4f3e543addd49cbb8e609';

final class WordTranslationsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Map<String, String>>, int> {
  WordTranslationsFamily._()
      : super(
          retry: null,
          name: r'wordTranslationsProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  WordTranslationsProvider call(
    int wordId,
  ) =>
      WordTranslationsProvider._(argument: wordId, from: this);

  @override
  String toString() => r'wordTranslationsProvider';
}
