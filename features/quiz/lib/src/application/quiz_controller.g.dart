// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quiz_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Keep-alive so an in-progress quiz survives switching tabs (parity with
/// the legacy app, which kept the quiz page mounted).

@ProviderFor(QuizController)
final quizControllerProvider = QuizControllerProvider._();

/// Keep-alive so an in-progress quiz survives switching tabs (parity with
/// the legacy app, which kept the quiz page mounted).
final class QuizControllerProvider
    extends $AsyncNotifierProvider<QuizController, QuizState> {
  /// Keep-alive so an in-progress quiz survives switching tabs (parity with
  /// the legacy app, which kept the quiz page mounted).
  QuizControllerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'quizControllerProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$quizControllerHash();

  @$internal
  @override
  QuizController create() => QuizController();
}

String _$quizControllerHash() => r'dcdac15bd093b425cb20eb4603242616cf7cfa9e';

/// Keep-alive so an in-progress quiz survives switching tabs (parity with
/// the legacy app, which kept the quiz page mounted).

abstract class _$QuizController extends $AsyncNotifier<QuizState> {
  FutureOr<QuizState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<QuizState>, QuizState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<QuizState>, QuizState>,
        AsyncValue<QuizState>,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}
