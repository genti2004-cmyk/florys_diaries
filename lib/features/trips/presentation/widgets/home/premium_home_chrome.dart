import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/core/widgets/travel_visuals.dart';

class PremiumHomeBackground extends StatelessWidget {
  const PremiumHomeBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF050C17),
            AppColors.homeBackground,
            Color(0xFF0B1728),
          ],
          stops: [0, 0.48, 1],
        ),
      ),
      child: Stack(
        children: [
          const Positioned(
            top: -110,
            right: -90,
            child: _AmbientGlow(
              size: 270,
              color: Color(0x332D5BDE),
            ),
          ),
          const Positioned(
            top: 330,
            left: -130,
            child: _AmbientGlow(
              size: 260,
              color: Color(0x246E9E96),
            ),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class PremiumHomeHeader extends StatelessWidget {
  const PremiumHomeHeader({
    required this.onOpenAssistant,
    required this.onOpenSearch,
    required this.onOpenSettings,
    super.key,
  });

  final VoidCallback onOpenAssistant;
  final VoidCallback onOpenSearch;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 370;
        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${TravelVisuals.greeting()} ✨',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.homeTextMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'FlorysDiaries',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontSize: 29,
                letterSpacing: -0.8,
              ),
            ),
          ],
        );

        final actions = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PremiumHomeIconButton(
              tooltip: 'Reiseassistent',
              icon: Icons.auto_awesome_rounded,
              onTap: onOpenAssistant,
            ),
            const SizedBox(width: 8),
            PremiumHomeIconButton(
              tooltip: 'Globale Suche',
              icon: Icons.search_rounded,
              onTap: onOpenSearch,
            ),
            const SizedBox(width: 8),
            PremiumHomeIconButton(
              tooltip: 'Einstellungen',
              icon: Icons.settings_outlined,
              onTap: onOpenSettings,
            ),
          ],
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title,
              const SizedBox(height: 14),
              Align(alignment: Alignment.centerRight, child: actions),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: title),
            const SizedBox(width: 12),
            actions,
          ],
        );
      },
    );
  }
}

class PremiumHomeIconButton extends StatelessWidget {
  const PremiumHomeIconButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
    super.key,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.homeSurface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(17),
          child: Ink(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: AppColors.homeBorder),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 21),
          ),
        ),
      ),
    );
  }
}

class PremiumHomeQuickActions extends StatelessWidget {
  const PremiumHomeQuickActions({
    required this.onCreateTrip,
    required this.onOpenTrips,
    required this.onOpenStatistics,
    required this.onOpenTemplates,
    super.key,
  });

  final VoidCallback onCreateTrip;
  final VoidCallback onOpenTrips;
  final VoidCallback onOpenStatistics;
  final VoidCallback onOpenTemplates;

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[
      _QuickAction(
        icon: Icons.add_rounded,
        label: 'Neue Reise',
        onTap: onCreateTrip,
        emphasized: true,
      ),
      _QuickAction(
        icon: Icons.luggage_outlined,
        label: 'Reisen',
        onTap: onOpenTrips,
      ),
      _QuickAction(
        icon: Icons.collections_bookmark_outlined,
        label: 'Vorlagen',
        onTap: onOpenTemplates,
      ),
      _QuickAction(
        icon: Icons.bar_chart_rounded,
        label: 'Statistik',
        onTap: onOpenStatistics,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 390 ? 2 : 4;
        final width =
            (constraints.maxWidth - ((columns - 1) * 10)) / columns;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: actions
              .map((action) => SizedBox(width: width, child: action))
              .toList(growable: false),
        );
      },
    );
  }
}

class PremiumHomeOverviewCard extends StatelessWidget {
  const PremiumHomeOverviewCard({
    required this.tripCount,
    required this.countryCount,
    required this.documentCount,
    required this.memoryCount,
    required this.onOpenMap,
    super.key,
  });

  final int tripCount;
  final int countryCount;
  final int documentCount;
  final int memoryCount;
  final VoidCallback onOpenMap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 13, 16, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF13233A), AppColors.homeSurface],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.homeBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x30000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Deine Reisewelt',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onOpenMap,
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                icon: const Icon(Icons.public_rounded, size: 17),
                label: const Text('Weltkarte'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _OverviewMetric(value: '$tripCount', label: 'Reisen'),
              ),
              Expanded(
                child: _OverviewMetric(value: '$countryCount', label: 'Länder'),
              ),
              Expanded(
                child: _OverviewMetric(
                  value: '$documentCount',
                  label: 'Dokumente',
                ),
              ),
              Expanded(
                child: _OverviewMetric(value: '$memoryCount', label: 'Momente'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PremiumHomeSectionHeader extends StatelessWidget {
  const PremiumHomeSectionHeader({
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.homeTextMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (onAction != null && actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(actionLabel!),
                const SizedBox(width: 2),
                const Icon(Icons.chevron_right_rounded, size: 18),
              ],
            ),
          ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final background = emphasized ? Colors.white : AppColors.homeSurface;
    final foreground = emphasized ? AppColors.primary : Colors.white;
    final border = emphasized ? Colors.white : AppColors.homeBorder;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(21),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(21),
        child: Ink(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(21),
            border: Border.all(color: border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x24000000),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: foreground),
              const SizedBox(height: 7),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  const _OverviewMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.homeTextMuted,
          ),
        ),
      ],
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}
