/// core/tts/lib/src/tts_service.dart
///
/// Text-to-speech behind an abstract interface so the app never touches
/// the plugin directly (and tests can inject [SilentTtsService]).
///
/// Threading note (Windows): flutter_tts's Windows implementation can
/// deliver native completion callbacks from an SAPI worker thread instead
/// of the platform thread, which the engine logs as:
///   "The 'flutter_tts' channel sent a message from native to Flutter on
///    a non-platform thread."
/// Every Dart-side call in this service already runs on the platform
/// thread, so the app itself never violates the channel threading
/// contract - the stray message originates inside the plugin's native
/// code. Mitigations applied here:
///  * no native-to-Flutter callbacks are requested: completion/progress
///    handlers are never registered and awaitSpeakCompletion stays off,
///    which removes the offending callback path for normal speech,
///  * every engine call is serialized through a single operation queue so
///    overlapping speak/stop calls can never interleave mid-message,
///  * engine errors are contained so a dropped channel message can never
///    crash the UI - speech simply does not play.
/// Keep the plugin current (`flutter pub upgrade flutter_tts`) to pick up
/// the upstream fix for the warning itself.
library;

import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tts_service.g.dart';

const kDefaultTtsLanguage = 'en-US';

abstract interface class TtsService {
  /// Speaks [text] aloud, replacing any utterance already playing.
  Future<void> speak(String text, {String? language});

  /// Stops any utterance currently playing.
  Future<void> stop();
}

/// Production implementation backed by the platform TTS engine.
final class FlutterTtsService implements TtsService {
  FlutterTtsService([FlutterTts? tts]) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;
  bool _configured = false;
  String? _language;

  /// Tail of the operation queue: every engine call chains onto this so
  /// calls execute strictly one at a time, in order.
  Future<void> _queue = Future<void>.value();

  /// Serializes [action] behind every previously queued engine call and
  /// contains its errors (a TTS failure must never crash the app or wedge
  /// the queue).
  Future<void> _enqueue(Future<void> Function() action) {
    final run = _queue.then((_) => action()).catchError((Object _) {
      // Swallowed intentionally: see the library doc comment.
    });
    _queue = run;
    return run;
  }

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
    _configured = true;
  }

  @override
  Future<void> speak(String text, {String? language}) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return Future<void>.value();
    final lang = language ?? kDefaultTtsLanguage;
    return _enqueue(() async {
      await _ensureConfigured();
      // Replace whatever is playing; serialized, so a rapid double-click
      // on pronounce can never interleave stop/speak pairs.
      await _tts.stop();
      if (_language != lang) {
        await _tts.setLanguage(lang);
        _language = lang;
      }
      await _tts.speak(trimmed);
    });
  }

  @override
  Future<void> stop() => _enqueue(() async {
        await _tts.stop();
      });
}

/// No-op implementation for tests and unsupported platforms.
final class SilentTtsService implements TtsService {
  @override
  Future<void> speak(String text, {String? language}) async {}

  @override
  Future<void> stop() async {}
}

@Riverpod(keepAlive: true)
TtsService ttsService(Ref ref) {
  final service = FlutterTtsService();
  ref.onDispose(service.stop);
  return service;
}
