import 'package:app/l10n/app_localizations.dart';
import 'package:app/models/agent_memory.dart';

/// Builds a short, personalized greeting from the agent memory (issue #25).
///
/// Returns `null` when there is nothing to personalize. The greeting is
/// intentionally template-based (no LLM call) so it is instant and costs no
/// tokens; it appears on the Ask tab.
///
/// Because it only reads the locally stored [AgentMemory], it is backend
/// agnostic: the same greeting is shown whether the app is running the local
/// `flutter_gemma` model or the remote Gemini (Firebase AI Logic) edition.
String? buildAgentGreeting(AgentMemory memory, AppLocalizations l10n) {
  if (memory.isEmpty) return null;

  final parts = <String>[l10n.greetingWelcome];

  final feeling = _clean(memory.feeling);
  if (feeling.isNotEmpty) {
    parts.add(l10n.greetingWithFeeling(feeling));
  } else if (memory.feelings.isNotEmpty) {
    final topicFeeling = _clean(memory.feelings.values.first);
    if (topicFeeling.isNotEmpty) {
      parts.add(l10n.greetingWithFeeling(topicFeeling));
    }
  } else if (memory.facts.isNotEmpty) {
    parts.add(l10n.greetingRemember(_clean(memory.facts.first)));
  } else if (memory.preferences.isNotEmpty) {
    parts.add(l10n.greetingRemember(_clean(memory.preferences.first)));
  }

  return parts.join(' ');
}

/// Whether the memory's greeting content is written in the locale's script.
///
/// A profile is normally stored in the language that was active when it was
/// extracted. After switching languages, [QuestionFormScreen] re-summarizes a
/// mismatched profile once so the greeting stays in the selected language.
bool memoryGreetingMatchesLocale(AgentMemory memory, AppLocalizations l10n) {
  final sample = _greetingSample(memory);
  if (sample.isEmpty) return true;
  final hasCjk = RegExp(r'[\u4e00-\u9fff]').hasMatch(sample);
  return l10n.isChinese ? hasCjk : !hasCjk;
}

String _greetingSample(AgentMemory memory) {
  if (memory.feeling.trim().isNotEmpty) return memory.feeling;
  if (memory.feelings.isNotEmpty) return memory.feelings.values.first;
  if (memory.facts.isNotEmpty) return memory.facts.first;
  if (memory.preferences.isNotEmpty) return memory.preferences.first;
  return '';
}

/// Trim and drop a trailing sentence punctuation mark so the value reads well
/// when embedded in a sentence.
String _clean(String value) =>
    value.trim().replaceFirst(RegExp(r'[.。!！?？]\s*$'), '');
