import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/core/constants/app_metadata.dart';

class PrivacyAndDataScreen extends StatelessWidget {
  const PrivacyAndDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Datenschutz & Daten')),
      body: SafeArea(
        top: false,
        child: ListView(
          key: const PageStorageKey<String>('privacy-and-data-content'),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _PrivacyHeroCard(version: AppMetadata.displayVersion),
            const SizedBox(height: 14),
            const _PrivacyFactCard(
              key: ValueKey<String>('privacy-local-data'),
              icon: Icons.phone_android_outlined,
              title: 'Lokale Reisedaten',
              text:
                  'Reisen, Dokumentmetadaten, Album, Checklisten und '
                  'zugeordnete Dateien werden im privaten App-Bereich des '
                  'Geräts gespeichert. FlorysDiaries betreibt keinen eigenen '
                  'Server für diese Inhalte.',
            ),
            const SizedBox(height: 12),
            const _PrivacyFactCard(
              key: ValueKey<String>('privacy-system-backup'),
              icon: Icons.phonelink_erase_outlined,
              title: 'Kein Android-Systembackup',
              text:
                  'Das automatische Android-Systembackup und die direkte '
                  'Übertragung app-interner Daten auf ein anderes Gerät sind '
                  'für FlorysDiaries deaktiviert. Für einen Gerätewechsel '
                  'werden ausschließlich die geprüften lokalen oder '
                  'Google-Drive-Backups der App verwendet.',
            ),
            const SizedBox(height: 12),
            const _PrivacyFactCard(
              key: ValueKey<String>('privacy-google-drive'),
              icon: Icons.cloud_outlined,
              title: 'Google Drive ist optional',
              text:
                  'Google Drive wird erst nach einer bewussten Anmeldung '
                  'verwendet. Die App fordert nur den app-eigenen '
                  'Drive-Datenbereich an. Die Konto-E-Mail wird in der App '
                  'zur Zuordnung angezeigt. Backups können in der '
                  'Google-Drive-Historie wiederhergestellt oder gelöscht '
                  'werden.',
            ),
            const SizedBox(height: 12),
            const _PrivacyFactCard(
              key: ValueKey<String>('privacy-map-services'),
              icon: Icons.map_outlined,
              title: 'Karten aus dem Internet',
              text:
                  'Weltkarte und Travel Replay laden Kartenkacheln über '
                  'verschlüsselte Internetverbindungen von '
                  'OpenStreetMap-Kartendiensten. Dabei fallen beim jeweiligen '
                  'Kartendienst technisch notwendige Verbindungsdaten wie die '
                  'IP-Adresse und die angeforderte Kartenregion an.',
            ),
            const SizedBox(height: 12),
            const _PrivacyFactCard(
              key: ValueKey<String>('privacy-no-tracking'),
              icon: Icons.visibility_off_outlined,
              title: 'Keine Werbung und kein Tracking',
              text:
                  'Die aktuelle App enthält keine Werbenetzwerke, keine '
                  'Nutzungsanalyse und kein externes Absturz-Tracking. '
                  'Reiseinhalte werden nicht an den Entwickler übertragen.',
            ),
            const SizedBox(height: 12),
            const _PrivacyFactCard(
              key: ValueKey<String>('privacy-delete-data'),
              icon: Icons.delete_outline_rounded,
              title: 'Daten löschen',
              text:
                  'Reisen und ihre Inhalte können in der App gelöscht werden. '
                  'Lokale sowie Google-Drive-Backups besitzen eigene '
                  'Löschaktionen. Beim Deinstallieren werden die lokalen '
                  'App-Daten entfernt; getrennt gespeicherte Backups müssen '
                  'bei Bedarf zusätzlich gelöscht werden.',
            ),
            const SizedBox(height: 16),
            Container(
              key: const ValueKey<String>('privacy-current-version-note'),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                'Diese Übersicht beschreibt den technischen Datenfluss von '
                '${AppMetadata.name} ${AppMetadata.displayVersion}. Eine '
                'öffentliche Datenschutzerklärung für den Store muss vor der '
                'Veröffentlichung zusätzlich mit Anbieter- und '
                'Kontaktangaben bereitgestellt werden.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyHeroCard extends StatelessWidget {
  const _PrivacyHeroCard({required this.version});

  final String version;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.verified_user_outlined,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Deine Daten bleiben unter deiner Kontrolle',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Transparente Übersicht für FlorysDiaries $version.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyFactCard extends StatelessWidget {
  const _PrivacyFactCard({
    required this.icon,
    required this.title,
    required this.text,
    super.key,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 5),
                  Text(
                    text,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
