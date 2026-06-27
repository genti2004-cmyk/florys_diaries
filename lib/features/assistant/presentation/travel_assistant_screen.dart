import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/core/widgets/app_section_title.dart';
import 'package:florys_diaries/features/assistant/application/travel_assistant_analyzer.dart';
import 'package:florys_diaries/features/assistant/application/travel_assistant_answer_service.dart';
import 'package:florys_diaries/features/assistant/domain/travel_assistant_models.dart';
import 'package:florys_diaries/features/assistant/presentation/widgets/assistant_insight_card.dart';
import 'package:florys_diaries/features/assistant/presentation/widgets/assistant_overview_grid.dart';
import 'package:florys_diaries/features/assistant/presentation/widgets/assistant_question_panel.dart';
import 'package:florys_diaries/features/trips/application/trip_store_scope.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';
import 'package:florys_diaries/features/trips/presentation/screens/trip_detail_screen.dart';

class TravelAssistantScreen extends StatefulWidget {
  const TravelAssistantScreen({super.key});

  @override
  State<TravelAssistantScreen> createState() => _TravelAssistantScreenState();
}

class _TravelAssistantScreenState extends State<TravelAssistantScreen> {
  static const _analyzer = TravelAssistantAnalyzer();
  static const _answerService = TravelAssistantAnswerService();

  final TextEditingController _questionController = TextEditingController();
  TravelAssistantAnswer? _answer;

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  void _ask(
    String question,
    List<Trip> trips,
    TravelAssistantSnapshot snapshot,
  ) {
    FocusScope.of(context).unfocus();
    setState(() {
      _answer = _answerService.answer(
        question: question,
        trips: trips,
        snapshot: snapshot,
      );
    });
  }

  void _askQuick(
    String question,
    List<Trip> trips,
    TravelAssistantSnapshot snapshot,
  ) {
    _questionController.text = question;
    _ask(question, trips, snapshot);
  }

  void _openTripById(List<Trip> trips, String? tripId) {
    if (tripId == null) {
      return;
    }
    final matching = trips.where((trip) => trip.id == tripId);
    if (matching.isEmpty) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TripDetailScreen(trip: matching.first),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = TripStoreScope.of(context);
    final trips = store.trips;
    final snapshot = _analyzer.analyze(trips);

    return Scaffold(
      appBar: AppBar(title: const Text('Reiseassistent')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 28),
          children: [
            const AppSectionTitle(
              title: 'Smart Travel Assistant',
              subtitle:
                  'Lokale Hinweise aus deinen Reisen, Dokumenten und Erinnerungen.',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ReadinessCard(snapshot: snapshot),
                  const SizedBox(height: 14),
                  AssistantOverviewGrid(snapshot: snapshot),
                  const SizedBox(height: 14),
                  AssistantQuestionPanel(
                    controller: _questionController,
                    answer: _answer,
                    onSubmit: (question) => _ask(question, trips, snapshot),
                    onQuickQuestion: (question) =>
                        _askQuick(question, trips, snapshot),
                    onOpenAnswerTrip: _answer?.tripId == null
                        ? null
                        : () => _openTripById(trips, _answer?.tripId),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Empfehlungen',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.text,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...snapshot.insights.map(
                    (insight) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AssistantInsightCard(
                        insight: insight,
                        onTap: insight.tripId == null
                            ? null
                            : () => _openTripById(trips, insight.tripId),
                      ),
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

class _ReadinessCard extends StatelessWidget {
  const _ReadinessCard({required this.snapshot});

  final TravelAssistantSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final trip = snapshot.nextTrip;
    final progress = snapshot.nextTripReadiness / 100;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.route_rounded, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    trip == null
                        ? 'Aktuell keine kommende Reise'
                        : 'Nächste Reise: ${trip.destination}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.text,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  trip == null ? '–' : '${snapshot.nextTripReadiness} %',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: trip == null ? 0 : progress,
                minHeight: 10,
                backgroundColor: AppColors.surfaceSoft,
                color: AppColors.sage,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              snapshot.readinessLabel,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
