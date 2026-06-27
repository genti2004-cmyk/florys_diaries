import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/features/assistant/domain/travel_assistant_models.dart';

class AssistantQuestionPanel extends StatelessWidget {
  const AssistantQuestionPanel({
    required this.controller,
    required this.onSubmit,
    required this.onQuickQuestion,
    this.answer,
    this.onOpenAnswerTrip,
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmit;
  final ValueChanged<String> onQuickQuestion;
  final TravelAssistantAnswer? answer;
  final VoidCallback? onOpenAnswerTrip;

  static const _quickQuestions = [
    'Was steht als Nächstes an?',
    'Wo fehlen Dokumente?',
    'Zeig meine Highlights',
    'Meine Reiseübersicht',
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Frage deine Reisen',
                        style: TextStyle(
                          color: AppColors.text,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Die Auswertung bleibt lokal auf deinem Gerät.',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              textInputAction: TextInputAction.send,
              onSubmitted: onSubmit,
              decoration: InputDecoration(
                hintText: 'Zum Beispiel: Wo fehlen Dokumente?',
                suffixIcon: IconButton(
                  tooltip: 'Frage auswerten',
                  onPressed: () => onSubmit(controller.text),
                  icon: const Icon(Icons.arrow_upward_rounded),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickQuestions
                  .map(
                    (question) => ActionChip(
                      label: Text(question),
                      onPressed: () => onQuickQuestion(question),
                    ),
                  )
                  .toList(growable: false),
            ),
            if (answer != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      answer!.title,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      answer!.body,
                      style: const TextStyle(color: AppColors.text),
                    ),
                    if (onOpenAnswerTrip != null) ...[
                      const SizedBox(height: 10),
                      TextButton.icon(
                        onPressed: onOpenAnswerTrip,
                        icon: const Icon(Icons.open_in_new_rounded, size: 18),
                        label: const Text('Reise öffnen'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
