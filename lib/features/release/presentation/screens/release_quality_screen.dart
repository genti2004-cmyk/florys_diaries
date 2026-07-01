import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:florys_diaries/core/constants/app_metadata.dart';
import 'package:florys_diaries/features/backup/domain/data_safety_report.dart';
import 'package:florys_diaries/features/backup/domain/local_backup_entry.dart';
import 'package:florys_diaries/features/release/application/release_quality_analyzer.dart';
import 'package:florys_diaries/features/release/domain/release_quality_report.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

class ReleaseQualityScreen extends StatelessWidget {
  const ReleaseQualityScreen({
    super.key,
    required this.trips,
    required this.localBackups,
    required this.dataSafetyReport,
    this.isReleaseBuild = kReleaseMode,
  });

  final List<Trip> trips;
  final List<LocalBackupEntry> localBackups;
  final DataSafetyReport? dataSafetyReport;
  final bool isReleaseBuild;

  @override
  Widget build(BuildContext context) {
    final report = const ReleaseQualityAnalyzer().inspect(
      trips: trips,
      localBackups: localBackups,
      dataSafetyReport: dataSafetyReport,
      isReleaseBuild: isReleaseBuild,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Release & Qualität')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _StatusHero(report: report),
          const SizedBox(height: 16),
          Text(
            'Aktueller Datenbestand',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          _MetricsGrid(report: report),
          const SizedBox(height: 20),
          Text(
            'Prüfpunkte',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          ...report.checks.map(
            (check) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _CheckCard(check: check),
            ),
          ),
          const SizedBox(height: 6),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.fact_check_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Finale technische Freigabe',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Diese Übersicht prüft den lokalen App- und Datenzustand. '
                    'Sie ersetzt nicht den signierten Release-Build, den Test '
                    'der installierten APK beziehungsweise AAB und die '
                    'Prüfungen in der Play Console.',
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: () => _copyReport(context, report),
                    icon: const Icon(Icons.copy_all_outlined),
                    label: const Text('Diagnose kopieren'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _copyReport(
    BuildContext context,
    ReleaseQualityReport report,
  ) async {
    final text = report.toPlainText(
      appName: AppMetadata.name,
      releaseVersion: AppMetadata.fullVersion,
      developmentMilestone: AppMetadata.developmentMilestone,
      packageId: AppMetadata.releasePackageId,
    );
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Release-Diagnose wurde kopiert.')),
    );
  }
}

class _StatusHero extends StatelessWidget {
  const _StatusHero({required this.report});

  final ReleaseQualityReport report;

  @override
  Widget build(BuildContext context) {
    final colors = _stateColors(context, report.state);
    final icon = switch (report.state) {
      ReleaseCheckState.ready => Icons.verified_rounded,
      ReleaseCheckState.attention => Icons.rule_rounded,
      ReleaseCheckState.blocked => Icons.gpp_bad_rounded,
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.foreground.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors.foreground.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: colors.foreground),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.statusTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: colors.foreground,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${report.readyCount} bereit · '
                  '${report.attentionCount} prüfen · '
                  '${report.blockedCount} blockiert',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.foreground,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${AppMetadata.displayVersion} · Build '
                  '${AppMetadata.buildNumber} · '
                  '${AppMetadata.developmentMilestone}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.foreground.withValues(alpha: 0.88),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.report});

  final ReleaseQualityReport report;

  @override
  Widget build(BuildContext context) {
    final metrics = <({IconData icon, String label, int value})>[
      (icon: Icons.flight_takeoff_rounded, label: 'Reisen', value: report.tripCount),
      (icon: Icons.description_outlined, label: 'Dokumente', value: report.documentCount),
      (icon: Icons.photo_library_outlined, label: 'Momente', value: report.momentCount),
      (icon: Icons.route_outlined, label: 'Programmpunkte', value: report.planItemCount),
      (icon: Icons.payments_outlined, label: 'Ausgaben', value: report.expenseCount),
      (icon: Icons.group_outlined, label: 'Teilnehmer', value: report.participantCount),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 600 ? 3 : 2;
        final spacing = 10.0;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: metrics
              .map(
                (metric) => SizedBox(
                  width: width,
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Icon(
                            metric.icon,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${metric.value}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                Text(
                                  metric.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _CheckCard extends StatelessWidget {
  const _CheckCard({required this.check});

  final ReleaseQualityCheck check;

  @override
  Widget build(BuildContext context) {
    final colors = _stateColors(context, check.state);
    final icon = switch (check.state) {
      ReleaseCheckState.ready => Icons.check_circle_rounded,
      ReleaseCheckState.attention => Icons.info_rounded,
      ReleaseCheckState.blocked => Icons.error_rounded,
    };

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: colors.foreground),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    check.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(check.detail),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

({Color background, Color foreground}) _stateColors(
  BuildContext context,
  ReleaseCheckState state,
) {
  final scheme = Theme.of(context).colorScheme;
  return switch (state) {
    ReleaseCheckState.ready => (
        background: scheme.primaryContainer,
        foreground: scheme.onPrimaryContainer,
      ),
    ReleaseCheckState.attention => (
        background: scheme.tertiaryContainer,
        foreground: scheme.onTertiaryContainer,
      ),
    ReleaseCheckState.blocked => (
        background: scheme.errorContainer,
        foreground: scheme.onErrorContainer,
      ),
  };
}
