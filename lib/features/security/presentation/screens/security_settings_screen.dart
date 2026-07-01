import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/features/security/application/app_lock_scope.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() =>
      _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  Future<void> _configurePin() async {
    final controller = AppLockScope.of(context);
    final pinController = TextEditingController();
    final confirmController = TextEditingController();
    bool obscure = true;
    String? error;

    final pin = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void submit() {
              final value = pinController.text.trim();
              final confirmation = confirmController.text.trim();
              if (!RegExp(r'^\d{4,8}$').hasMatch(value)) {
                setDialogState(() {
                  error = 'Die PIN muss aus 4 bis 8 Ziffern bestehen.';
                });
                return;
              }
              if (value != confirmation) {
                setDialogState(() {
                  error = 'Die beiden PIN-Eingaben stimmen nicht überein.';
                });
                return;
              }
              Navigator.of(dialogContext).pop(value);
            }

            return AlertDialog(
              title: Text(
                controller.settings.enabled
                    ? 'PIN ändern'
                    : 'App-Schutz aktivieren',
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: pinController,
                    autofocus: true,
                    obscureText: obscure,
                    keyboardType: TextInputType.number,
                    maxLength: 8,
                    decoration: InputDecoration(
                      labelText: 'Neue PIN',
                      counterText: '',
                      errorText: error,
                      suffixIcon: IconButton(
                        onPressed: () =>
                            setDialogState(() => obscure = !obscure),
                        icon: Icon(
                          obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: confirmController,
                    obscureText: obscure,
                    keyboardType: TextInputType.number,
                    maxLength: 8,
                    onSubmitted: (_) => submit(),
                    decoration: const InputDecoration(
                      labelText: 'PIN bestätigen',
                      counterText: '',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Abbrechen'),
                ),
                FilledButton(
                  onPressed: submit,
                  child: const Text('Speichern'),
                ),
              ],
            );
          },
        );
      },
    );
    pinController.dispose();
    confirmController.dispose();
    if (!mounted || pin == null) {
      return;
    }

    try {
      await controller.configure(
        pin: pin,
        biometricEnabled: controller.settings.biometricEnabled,
        documentsOnly: controller.settings.documentsOnly,
        lockAfterMinutes: controller.settings.lockAfterMinutes,
      );
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('App-Schutz wurde gespeichert.')),
        );
      }
    } on FormatException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    }
  }

  Future<void> _updatePreferences({
    bool? biometricEnabled,
    bool? documentsOnly,
    int? lockAfterMinutes,
  }) async {
    final controller = AppLockScope.of(context);
    await controller.updatePreferences(
      biometricEnabled:
          biometricEnabled ?? controller.settings.biometricEnabled,
      documentsOnly: documentsOnly ?? controller.settings.documentsOnly,
      lockAfterMinutes:
          lockAfterMinutes ?? controller.settings.lockAfterMinutes,
    );
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _disable() async {
    final controller = AppLockScope.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('App-Schutz ausschalten?'),
        content: const Text(
          'PIN und biometrische Sperre werden entfernt. Deine Reisedaten bleiben unverändert.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Ausschalten'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) {
      return;
    }
    await controller.disable();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppLockScope.of(context);
    final settings = controller.settings;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('App-Schutz')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: settings.enabled
                          ? AppColors.success.withValues(alpha: 0.12)
                          : AppColors.surfaceSoft,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      settings.enabled
                          ? Icons.lock_rounded
                          : Icons.lock_open_rounded,
                      color: settings.enabled
                          ? AppColors.success
                          : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          settings.enabled
                              ? 'Schutz ist aktiv'
                              : 'Noch kein App-Schutz',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          settings.enabled
                              ? settings.documentsOnly
                                  ? 'Nur Dokumente werden geschützt.'
                                  : 'Die gesamte App wird geschützt.'
                              : 'Schütze deine Reisedaten mit PIN und optional Biometrie.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _configurePin,
              icon: const Icon(Icons.pin_rounded),
              label: Text(
                settings.enabled ? 'PIN ändern' : 'PIN einrichten',
              ),
            ),
          ),
          if (settings.enabled) ...[
            const SizedBox(height: 16),
            Text(
              'Schutzumfang',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      !settings.documentsOnly
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: !settings.documentsOnly
                          ? AppColors.primary
                          : AppColors.textMuted,
                    ),
                    title: const Text('Gesamte App schützen'),
                    subtitle: const Text(
                      'Beim Start und nach Inaktivität entsperren',
                    ),
                    onTap: () => _updatePreferences(documentsOnly: false),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(
                      settings.documentsOnly
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: settings.documentsOnly
                          ? AppColors.primary
                          : AppColors.textMuted,
                    ),
                    title: const Text('Nur Dokumente schützen'),
                    subtitle: const Text(
                      'Reisen bleiben sichtbar, Dateien benötigen PIN',
                    ),
                    onTap: () => _updatePreferences(documentsOnly: true),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Entsperrung',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Fingerabdruck oder Gesicht'),
                    subtitle: const Text(
                      'Biometrie des Geräts zusätzlich zur PIN nutzen',
                    ),
                    value: settings.biometricEnabled,
                    onChanged: (value) =>
                        _updatePreferences(biometricEnabled: value),
                  ),
                  if (!settings.documentsOnly) ...[
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('Automatisch sperren'),
                      subtitle: Text(
                        _lockAfterLabel(settings.lockAfterMinutes),
                      ),
                      trailing: DropdownButton<int>(
                        value: settings.lockAfterMinutes,
                        underline: const SizedBox.shrink(),
                        items: const [
                          DropdownMenuItem(value: 0, child: Text('Sofort')),
                          DropdownMenuItem(value: 1, child: Text('1 Min.')),
                          DropdownMenuItem(value: 5, child: Text('5 Min.')),
                          DropdownMenuItem(value: 15, child: Text('15 Min.')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            _updatePreferences(lockAfterMinutes: value);
                          }
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _disable,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
              ),
              icon: const Icon(Icons.lock_open_rounded),
              label: const Text('App-Schutz ausschalten'),
            ),
          ],
          const SizedBox(height: 12),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(15),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: AppColors.primary),
                  SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      'Die PIN wird nicht im Klartext gespeichert. Vergiss die PIN nicht, da sie nicht ausgelesen werden kann.',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _lockAfterLabel(int minutes) {
    return switch (minutes) {
      0 => 'Sofort beim Verlassen der App',
      1 => 'Nach 1 Minute im Hintergrund',
      5 => 'Nach 5 Minuten im Hintergrund',
      15 => 'Nach 15 Minuten im Hintergrund',
      _ => 'Sofort beim Verlassen der App',
    };
  }
}
