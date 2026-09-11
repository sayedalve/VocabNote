/// features/enrich/lib/src/presentation/capture_input.dart
///
/// The word capture field — the app's primary action. Submit saves locally
/// and returns focus immediately so rapid entry is frictionless. The focus
/// node can be supplied by the host (the app shell points Ctrl+N and the
/// "Add first word" onboarding button at it).
///
/// Rendered dense so it fits the notebook's single-row toolbar next to the
/// notebook picker and the search field.
library;

import 'package:core_design_system/core_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/capture_controller.dart';

class CaptureInput extends ConsumerStatefulWidget {
  const CaptureInput({
    this.notebookId,
    this.onCaptured,
    this.focusNode,
    this.autofocus = false,
    this.scope = CaptureScope.toolbar,
    super.key,
  });

  final int? notebookId;

  /// Called with the new word id and its term after a successful capture.
  final void Function(int wordId, String term)? onCaptured;

  /// Optional external focus node so the host can focus this field from
  /// shortcuts or onboarding actions. When null, an internal node is used.
  final FocusNode? focusNode;

  /// Focus the field as soon as it appears (used on the notebook tab and in
  /// the quick-add dialog so typing can start immediately).
  final bool autofocus;

  /// Which capture surface this input belongs to. Capture state is isolated
  /// per scope so the quick-add dialog and the toolbar field never share
  /// transient state (rejections, "saved" flashes).
  final CaptureScope scope;

  @override
  ConsumerState<CaptureInput> createState() => _CaptureInputState();
}

class _CaptureInputState extends ConsumerState<CaptureInput> {
  final TextEditingController _controller = TextEditingController();
  FocusNode? _ownedFocusNode;

  FocusNode get _focusNode =>
      widget.focusNode ?? (_ownedFocusNode ??= FocusNode());

  @override
  void dispose() {
    _controller.dispose();
    _ownedFocusNode?.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text;
    if (text.trim().isEmpty) return;

    final wordId = await ref
        .read(captureControllerProvider(widget.scope).notifier)
        .capture(text, notebookId: widget.notebookId);

    if (!mounted) return;
    final captureState = ref.read(captureControllerProvider(widget.scope));
    if (wordId != null && captureState is CaptureSaved) {
      _controller.clear();
      widget.onCaptured?.call(wordId, captureState.headword);
    }
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final captureState = ref.watch(captureControllerProvider(widget.scope));
    final tokens = VnTheme.of(context).tokens;

    ref.listen(captureControllerProvider(widget.scope), (previous, next) {
      if (next case CaptureSaved(:final headword)) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('Added “$headword” — enriching...'),
              duration: const Duration(seconds: 2),
            ),
          );
      }
    });

    final isSaving = captureState is CaptureSaving;
    final rejection = switch (captureState) {
      CaptureRejected(:final reason) => reason,
      _ => null,
    };

    return Semantics(
      textField: true,
      label: 'Add a new word',
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        autofocus: widget.autofocus,
        enabled: !isSaving,
        autocorrect: false,
        textInputAction: TextInputAction.done,
        maxLength: 64,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: VnSpacing.x3,
            vertical: VnSpacing.x2 + 2,
          ),
          counterText: '',
          hintText: 'Add a word... (Enter)',
          prefixIcon: const Icon(Icons.add, size: 20),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 36,
            minHeight: 36,
          ),
          suffixIconConstraints: const BoxConstraints(
            minWidth: 36,
            minHeight: 36,
          ),
          errorText: rejection,
          suffixIcon: isSaving
              ? const Padding(
                  padding: EdgeInsets.all(VnSpacing.x2),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  tooltip: 'Save word',
                  icon: Icon(Icons.send, size: 18, color: tokens.accent),
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  onPressed: _submit,
                ),
        ),
        onChanged: (_) {
          if (rejection != null) {
            ref.read(captureControllerProvider(widget.scope).notifier).reset();
          }
        },
        onSubmitted: (_) => _submit(),
      ),
    );
  }
}
