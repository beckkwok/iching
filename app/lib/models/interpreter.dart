import 'package:flutter/material.dart';

/// A selectable interpreter persona (issue #22).
///
/// Each interpreter has its own system prompt, so the same cast can be read by
/// different "voices". The catalog lives in [InterpreterCatalog].
class Interpreter {
  /// Stable key persisted in settings.
  final String key;

  /// English display name.
  final String name;

  /// Traditional Chinese display name.
  final String nameZh;

  /// Short description shown as a tooltip/label.
  final String description;

  /// Avatar icon (profile-picture placeholder until real artwork is supplied).
  final IconData avatar;

  /// System instruction used when this interpreter generates an explanation.
  final String systemPrompt;

  const Interpreter({
    required this.key,
    required this.name,
    required this.nameZh,
    required this.description,
    required this.avatar,
    required this.systemPrompt,
  });

  /// The display name for the active language.
  String displayName(bool isChinese) => isChinese ? nameZh : name;

  @override
  String toString() => 'Interpreter($key)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Interpreter &&
          runtimeType == other.runtimeType &&
          key == other.key &&
          name == other.name &&
          nameZh == other.nameZh &&
          description == other.description &&
          avatar == other.avatar &&
          systemPrompt == other.systemPrompt;

  @override
  int get hashCode =>
      Object.hash(key, name, nameZh, description, avatar, systemPrompt);
}
