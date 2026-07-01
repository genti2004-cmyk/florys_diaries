import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/features/map/domain/map_visit_models.dart';
import 'package:florys_diaries/features/map/widgets/world_map_panel.dart';

class WorldMapControls extends StatelessWidget {
  const WorldMapControls({
    super.key,
    required this.selectedLayer,
    required this.selectedStyle,
    required this.selectedYear,
    required this.years,
    required this.onLayerChanged,
    required this.onStyleChanged,
    required this.onYearChanged,
  });

  final WorldMapLayer selectedLayer;
  final WorldMapStyle selectedStyle;
  final int? selectedYear;
  final List<int> years;
  final ValueChanged<WorldMapLayer> onLayerChanged;
  final ValueChanged<WorldMapStyle> onStyleChanged;
  final ValueChanged<int?> onYearChanged;

  @override
  Widget build(BuildContext context) {
    return WorldMapPanel(
      title: 'Kartenansicht',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Was soll die Karte zeigen?',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: WorldMapLayer.values
                .map(
                  (layer) => ChoiceChip(
                    avatar: Icon(_iconForLayer(layer), size: 16),
                    label: Text(layer.label),
                    selected: selectedLayer == layer,
                    onSelected: (_) => onLayerChanged(layer),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int?>(
            key: ValueKey<String>(
              'world-map-year-filter-${selectedYear ?? 'all'}',
            ),
            initialValue: selectedYear,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Reisejahr',
              prefixIcon: Icon(Icons.calendar_month_outlined),
            ),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('Alle Jahre'),
              ),
              ...years.map(
                (year) => DropdownMenuItem<int?>(
                  value: year,
                  child: Text(year.toString()),
                ),
              ),
            ],
            onChanged: onYearChanged,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _StyleButton(
                  label: 'Hell',
                  icon: Icons.light_mode_rounded,
                  selected: selectedStyle == WorldMapStyle.light,
                  onTap: () => onStyleChanged(WorldMapStyle.light),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StyleButton(
                  label: 'Dunkel',
                  icon: Icons.dark_mode_rounded,
                  selected: selectedStyle == WorldMapStyle.dark,
                  onTap: () => onStyleChanged(WorldMapStyle.dark),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static IconData _iconForLayer(WorldMapLayer layer) {
    return switch (layer) {
      WorldMapLayer.all => Icons.layers_rounded,
      WorldMapLayer.countries => Icons.flag_rounded,
      WorldMapLayer.cities => Icons.location_city_rounded,
      WorldMapLayer.routes => Icons.route_rounded,
    };
  }
}

class _StyleButton extends StatelessWidget {
  const _StyleButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? AppColors.primary : AppColors.text;

    return Material(
      color: selected ? AppColors.primarySoft : AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.55)
                  : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: foreground),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
