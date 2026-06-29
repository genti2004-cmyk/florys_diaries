import 'package:flutter/material.dart';

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
      title: 'Kartensteuerung',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ebene', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: WorldMapLayer.values
                .map(
                  (layer) => ChoiceChip(
                    label: Text(layer.label),
                    selected: selectedLayer == layer,
                    onSelected: (_) => onLayerChanged(layer),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final yearField = DropdownButtonFormField<int?>(
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
              );

              final styleButtons = Row(
                children: [
                  Expanded(
                    child: _StyleButton(
                      label: 'Hell',
                      icon: Icons.wb_sunny_outlined,
                      selected: selectedStyle == WorldMapStyle.light,
                      onTap: () => onStyleChanged(WorldMapStyle.light),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StyleButton(
                      label: 'Dunkel',
                      icon: Icons.dark_mode_outlined,
                      selected: selectedStyle == WorldMapStyle.dark,
                      onTap: () => onStyleChanged(WorldMapStyle.dark),
                    ),
                  ),
                ],
              );

              if (constraints.maxWidth < 520) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    yearField,
                    const SizedBox(height: 12),
                    Text(
                      'Kartenstil',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    styleButtons,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: yearField),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kartenstil',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 8),
                        styleButtons,
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
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
    return Material(
      color: selected
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minHeight: 46),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 19),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
