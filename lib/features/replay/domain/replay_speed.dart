enum ReplaySpeed {
  normal(multiplier: 1, stepDuration: Duration(seconds: 3), label: '×1'),
  doubleSpeed(
    multiplier: 2,
    stepDuration: Duration(milliseconds: 1500),
    label: '×2',
  ),
  quadrupleSpeed(
    multiplier: 4,
    stepDuration: Duration(milliseconds: 750),
    label: '×4',
  );

  const ReplaySpeed({
    required this.multiplier,
    required this.stepDuration,
    required this.label,
  });

  final int multiplier;
  final Duration stepDuration;
  final String label;
}
