import 'package:flutter/material.dart';

/// Question categories the user can choose from when starting a consultation.
///
/// The human-readable label is provided by `AppLocalizations.questionTypeLabel`
/// so it follows the active language.
enum QuestionType {
  careerAchievement(Icons.work_outline),
  intellectualMoralCultivation(Icons.school_outlined),
  timing(Icons.schedule_outlined),
  attitude(Icons.self_improvement_outlined);

  final IconData icon;

  const QuestionType(this.icon);
}
