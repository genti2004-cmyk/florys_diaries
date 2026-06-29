import 'dart:async';

import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';

class UnsavedChangesGuard<T> extends StatefulWidget {
  const UnsavedChangesGuard({
    required this.hasUnsavedChanges,
    required this.child,
    this.title = 'Änderungen verwerfen?',
    this.message = 'Deine nicht gespeicherten Änderungen gehen dabei verloren.',
    super.key,
  });

  final bool hasUnsavedChanges;
  final Widget child;
  final String title;
  final String message;

  @override
  State<UnsavedChangesGuard<T>> createState() => _UnsavedChangesGuardState<T>();
}

class _UnsavedChangesGuardState<T> extends State<UnsavedChangesGuard<T>> {
  bool _allowPop = false;
  bool _dialogOpen = false;

  @override
  void didUpdateWidget(covariant UnsavedChangesGuard<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.hasUnsavedChanges) {
      _allowPop = false;
    }
  }

  Future<void> _handleBlockedPop() async {
    if (_dialogOpen || !widget.hasUnsavedChanges) {
      return;
    }

    _dialogOpen = true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(Icons.edit_note_rounded, color: AppColors.primary),
          title: Text(widget.title),
          content: Text(widget.message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Weiter bearbeiten'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Änderungen verwerfen'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB42318),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
    _dialogOpen = false;

    if (!mounted || discard != true) {
      return;
    }

    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<T>(
      canPop: _allowPop || !widget.hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || _allowPop || !widget.hasUnsavedChanges) {
          return;
        }
        unawaited(_handleBlockedPop());
      },
      child: widget.child,
    );
  }
}
