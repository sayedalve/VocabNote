/// core/ai/lib/src/ai_client.dart
///
/// The provider-agnostic completion interface plus the shared HTTP transport
/// (retry, timeout, error taxonomy) that both adapters inherit. Ported from
/// the legacy `api/api.py` contract: 2 retries with linear backoff on
/// 429/5xx, hard timeout, HTTPS enforcement, no key material in errors.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import 'provider_config.dart';

part 'ai_client.freezed.dart';

@freezed
abstract class AiRequest with _$AiRequest {
  const factory AiRequest({
    required String prompt,
    String? system,
    @Default(0.4) double temperature,
    @Default(Duration(seconds: 15)) Duration timeout,
  }) = _AiRequest;
}

/// Failure taxonomy. UI maps these to user-facing copy; nothing here ever
/// contains an API key.
sealed class AiFailure {
  const AiFailure();

  String get message;
}

final class MissingApiKey extends AiFailure {
  const MissingApiKey();

  @override
  String get message => 'No API key is configured for this provider.';
}

final class InsecureBaseUrl extends AiFailure {
  const InsecureBaseUrl(this.baseUrl);

  final String baseUrl;

  @override
  String get message =>
      'Refusing to send the API key over an insecure URL: $baseUrl';
}

final class NetworkFailure extends AiFailure {
  const NetworkFailure(this.detail);

  final String detail;

  @override
  String get message => 'Network error: $detail';
}

final class HttpFailure extends AiFailure {
  const HttpFailure({required this.statusCode, required this.body});

  final int statusCode;
  final String body;

  @override
  String get message => 'Provider returned HTTP $statusCode: $body';
}

final class InvalidResponse extends AiFailure {
  const InvalidResponse(this.detail);

  final String detail;

  @override
  String get message => 'Unexpected provider response: $detail';
}

/// Result type for AI calls.
sealed class AiResult<T> {
  const AiResult();
}

final class AiOk<T> extends AiResult<T> {
  const AiOk(this.value);

  final T value;
}

final class AiErr<T> extends AiResult<T> {
  const AiErr(this.failure);

  final AiFailure failure;
}

/// The interface every provider adapter implements.
abstract interface class AiClient {
  ProviderConfig get config;

  Future<AiResult<String>> complete(AiRequest request, {required String apiKey});
}

/// Shared HTTP transport. Adapters supply the endpoint, headers, body shape,
/// and response extraction — nothing else.
abstract base class HttpAiAdapter implements AiClient {
  HttpAiAdapter({required this.config, required http.Client httpClient})
      : _http = httpClient;

  @override
  final ProviderConfig config;

  final http.Client _http;

  static const int _maxRetries = 2;
  static const Set<int> _retryableStatuses = {429, 500, 502, 503, 504};

  @protected
  Uri endpoint();

  @protected
  Map<String, String> headers(String apiKey);

  @protected
  Map<String, Object?> body(AiRequest request);

  /// Returns the completion text, or null if the JSON shape is unexpected.
  @protected
  String? extractText(Map<String, Object?> json);

  @override
  Future<AiResult<String>> complete(
    AiRequest request, {
    required String apiKey,
  }) async {
    if (apiKey.trim().isEmpty) return const AiErr(MissingApiKey());
    if (!isBaseUrlAllowed(config.baseUrl)) {
      return AiErr(InsecureBaseUrl(config.baseUrl));
    }

    var attempt = 0;
    while (true) {
      attempt += 1;
      try {
        final response = await _http
            .post(
              endpoint(),
              headers: {
                'Content-Type': 'application/json',
                ...headers(apiKey.trim()),
              },
              body: jsonEncode(body(request)),
            )
            .timeout(request.timeout);

        if (response.statusCode == 200) {
          final decoded = jsonDecode(utf8.decode(response.bodyBytes));
          if (decoded is! Map<String, Object?>) {
            return const AiErr(InvalidResponse('Top-level JSON is not an object'));
          }
          final text = extractText(decoded);
          if (text == null || text.trim().isEmpty) {
            return const AiErr(InvalidResponse('Completion text was empty'));
          }
          return AiOk(text);
        }

        if (_retryableStatuses.contains(response.statusCode) &&
            attempt <= _maxRetries) {
          await _backoff(attempt);
          continue;
        }
        return AiErr(
          HttpFailure(
            statusCode: response.statusCode,
            body: _truncate(utf8.decode(response.bodyBytes)),
          ),
        );
      } on TimeoutException {
        if (attempt <= _maxRetries) {
          await _backoff(attempt);
          continue;
        }
        return const AiErr(NetworkFailure('The request timed out.'));
      } on http.ClientException catch (e) {
        if (attempt <= _maxRetries) {
          await _backoff(attempt);
          continue;
        }
        return AiErr(NetworkFailure(e.message));
      } on SocketException catch (e) {
        if (attempt <= _maxRetries) {
          await _backoff(attempt);
          continue;
        }
        return AiErr(NetworkFailure(e.message));
      } on FormatException catch (e) {
        return AiErr(InvalidResponse('Malformed JSON: ${e.message}'));
      }
    }
  }

  Future<void> _backoff(int attempt) =>
      Future<void>.delayed(Duration(seconds: 2 * attempt));

  static String _truncate(String value, [int max = 300]) {
    final collapsed = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    return collapsed.length <= max
        ? collapsed
        : '${collapsed.substring(0, max)}...';
  }
}
