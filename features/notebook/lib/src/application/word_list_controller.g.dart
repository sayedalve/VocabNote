// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'word_list_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(WordListController)
final wordListControllerProvider = WordListControllerFamily._();

final class WordListControllerProvider
    extends $AsyncNotifierProvider<WordListController, WordListState> {
  WordListControllerProvider._(
      {required WordListControllerFamily super.from,
      required WordListFilter super.argument})
      : super(
          retry: null,
          name: r'wordListControllerProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$wordListControllerHash();

  @override
  String toString() {
    return r'wordListControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  WordListController create() => WordListController();

  @override
  bool operator ==(Object other) {
    return other is WordListControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$wordListControllerHash() =>
    r'90e4ff5f9496281feafd772c6895bebe97d48d5f';

final class WordListControllerFamily extends $Family
    with
        $ClassFamilyOverride<WordListController, AsyncValue<WordListState>,
            WordListState, FutureOr<WordListState>, WordListFilter> {
  WordListControllerFamily._()
      : super(
          retry: null,
          name: r'wordListControllerProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  WordListControllerProvider call(
    WordListFilter filter,
  ) =>
      WordListControllerProvider._(argument: filter, from: this);

  @override
  String toString() => r'wordListControllerProvider';
}

abstract class _$WordListController extends $AsyncNotifier<WordListState> {
  late final _$args = ref.$arg as WordListFilter;
  WordListFilter get filter => _$args;

  FutureOr<WordListState> build(
    WordListFilter filter,
  );
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<WordListState>, WordListState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<WordListState>, WordListState>,
        AsyncValue<WordListState>,
        Object?,
        Object?>;
    return element.handleCreate(
        ref,
        () => build(
              _$args,
            ));
  }
}
