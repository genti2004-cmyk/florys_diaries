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
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final yearField = DropdownButtonFormField<int?>(
                initialValue: selectedYear,
                decoration: const InputDecoration(labelText: 'Jahr'),
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
              final styleSelector = SegmentedButton<WorldMapStyle>(
                segments: const [
                  ButtonSegment(
                    value: WorldMapStyle.light,
                    label: Text('Hell'),
                    icon: Icon(Icons.wb_sunny_outlined),
                  ),
                  ButtonSegment(
                    value: WorldMapStyle.dark,
                    label: Text('Dunkel'),
                    icon: Icon(Icons.dark_mode_outlined),
                  ),
                ],
                selected: {selectedStyle},
                onSelectionChanged: (value) {
                  onStyleChanged(value.first);
                },
              );

              if (constraints.maxWidth < 520) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    yearField,
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: styleSelector,
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: yearField),
                  const SizedBox(width: 12),
                  styleSelector,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
