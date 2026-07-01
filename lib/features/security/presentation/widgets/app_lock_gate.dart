import 'dart:async';

import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/features/security/application/app_lock_controller.dart';

class AppLockGate extends StatelessWidget {
  const AppLockGate({
    required this.controller,
    required this.child,
    super.key,
  });

  final AppLockController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (controller.isLoading) {
          return Stack(
            fit: StackFit.expand,
            children: [
              Offstage(offstage: true, child: child),
              const Scaffold(
                backgroundColor: AppColors.homeBackground,
                body: Center(child: CircularProgressIndicator()),
              ),
            ],
          );
        }
        if (controller.isLocked) {
          return AppUnlockScreen(controller: controller);
        }
        return child;
      },
    );
  }
}

class AppUnlockScreen extends StatefulWidget {
  const AppUnlockScreen({required this.controller, super.key});

  final AppLockController controller;

  @override
  State<AppUnlockScreen> createState() => _AppUnlockScreenState();
}

class _AppUnlockScreenState extends State<AppUnlockScreen> {
  final TextEditingController _pinController = TextEditingController();
  String? _error;
  bool _isBiometricBusy = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller.settings.biometricEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(_biometric());
        }
      });
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _unlockWithPin() {
    final success = widget.controller.authenticatePin(_pinController.text);
    if (!success) {
      setState(() {
        _error = 'PIN ist nicht korrekt.';
        _pinController.clear();
      });
    }
  }

  Future<void> _biometric() async {
    if (_isBiometricBusy) {
      return;
    }
    setState(() {
      _isBiometricBusy = true;
      _error = null;
    });
    final success = await widget.controller.authenticateBiometric();
    if (mounted && !success) {
      setState(() {
        _isBiometricBusy = false;
        _error = 'Biometrische Entsperrung war nicht möglich.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homeBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.homeSurface,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppColors.homeBorder),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.homeSurfaceSoft,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.lock_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'FlorysDiaries entsperren',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Gib deine PIN ein oder nutze die biometrische Entsperrung.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.homeTextMuted,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      key: const ValueKey<String>('app-lock-pin'),
                      controller: _pinController,
                      autofocus: !widget.controller.settings.biometricEnabled,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      maxLength: 8,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _unlockWithPin(),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        counterText: '',
                        labelText: 'PIN',
                        labelStyle: const TextStyle(
                          color: AppColors.homeTextMuted,
                        ),
                        prefixIcon: const Icon(
                          Icons.pin_outlined,
                          color: Colors.white,
                        ),
                        errorText: _error,
                        filled: true,
                        fillColor: AppColors.homeSurfaceSoft,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _unlockWithPin,
                        icon: const Icon(Icons.lock_open_rounded),
                        label: const Text('Entsperren'),
                      ),
                    ),
                    if (widget.controller.settings.biometricEnabled) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isBiometricBusy ? null : _biometric,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(
                              color: AppColors.homeBorder,
                            ),
                          ),
                          icon: _isBiometricBusy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.fingerprint_rounded),
                          label: const Text('Biometrie verwenden'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<bool> showProtectedContentUnlockDialog(
  BuildContext context,
  AppLockController controller,
) async {
  if (!controller.protectsDocuments) {
    return true;
  }
  final pinController = TextEditingController();
  String? errorText;
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          Future<void> biometric() async {
            final success = await controller.authenticateBiometric();
            if (dialogContext.mounted && success) {
              Navigator.of(dialogContext).pop(true);
            } else if (dialogContext.mounted) {
              setState(() {
                errorText = 'Biometrische Entsperrung war nicht möglich.';
              });
            }
          }

          void submit() {
            final success = controller.authenticatePin(pinController.text);
            if (success) {
              Navigator.of(dialogContext).pop(true);
            } else {
              setState(() {
                errorText = 'PIN ist nicht korrekt.';
                pinController.clear();
              });
            }
          }

          return AlertDialog(
            title: const Text('Dokumente entsperren'),
            content: TextField(
              controller: pinController,
              autofocus: true,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 8,
              decoration: InputDecoration(
                labelText: 'PIN',
                counterText: '',
                errorText: errorText,
              ),
              onSubmitted: (_) => submit(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Abbrechen'),
              ),
              if (controller.settings.biometricEnabled)
                IconButton(
                  tooltip: 'Biometrie',
                  onPressed: biometric,
                  icon: const Icon(Icons.fingerprint_rounded),
                ),
              FilledButton(
                onPressed: submit,
                child: const Text('Entsperren'),
              ),
            ],
          );
        },
      );
    },
  );
  pinController.dispose();
  return result == true;
}
