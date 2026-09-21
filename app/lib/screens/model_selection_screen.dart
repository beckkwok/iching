import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../data/model_catalog.dart';
import '../l10n/app_localizations.dart';
import '../models/model_info.dart';
import '../services/llm_service.dart';
import '../services/database_service.dart';
import '../services/gua_generator.dart';
import 'question_form_screen.dart';

/// Startup screen that either auto-detects a saved model, shows the model
/// selection card grid, or shows download progress for a previously chosen
/// model whose file is missing.
///
/// Flow:
/// 1. Check `settings` table for `selected_model_key`.
/// 2. If found → look up ModelInfo, check file existence.
///    - File exists → proceed to the question form.
///    - File missing → download that model.
/// 3. If no key → check old default file for backward compatibility.
///    - Exists → auto-select Gemma4, save, proceed to the question form.
/// 4. Otherwise → show the 6-model selection grid.
class ModelSelectionScreen extends StatefulWidget {
  final DatabaseService? databaseService;

  const ModelSelectionScreen({super.key, required this.databaseService});

  @override
  State<ModelSelectionScreen> createState() => _ModelSelectionScreenState();
}

enum _ScreenPhase { initialising, selecting, downloading, loading, error }

class _ModelSelectionScreenState extends State<ModelSelectionScreen> {
  _ScreenPhase _phase = _ScreenPhase.initialising;
  LlmService? _llmService;
  double _downloadProgress = 0.0;
  String _statusText = '';
  String? _errorMessage;

  bool _startupStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Run once, after the first build context (and localizations) exist.
    if (_startupStarted) return;
    _startupStarted = true;
    _startupCheck();
  }

  // ---------------------------------------------------------------------------
  // Startup logic
  // ---------------------------------------------------------------------------

  Future<void> _startupCheck() async {
    final l10n = AppLocalizations.of(context);
    _statusText = l10n.checkingSetup;

    try {
      final db = widget.databaseService;
      String? savedKey;

      if (db != null) {
        savedKey = await db.getSetting('selected_model_key');
      }

      if (savedKey != null && savedKey.isNotEmpty) {
        final model = ModelCatalog.byKey(savedKey);
        if (model != null) {
          final fileExists = await _modelFileExists(model.filename);
          if (fileExists) {
            _llmService = LlmService(modelInfo: model);
            try {
              await _llmService!.initialize();
              await _applySavedPrompt();
              await _llmService!.openExplanationChat();
              if (mounted) _proceed();
            } catch (e) {
              if (mounted) {
                setState(() {
                  _phase = _ScreenPhase.error;
                  _errorMessage = l10n.modelLoadFailed('$e');
                  _statusText = l10n.loadFailed;
                });
              }
            }
            return;
          }
          // File missing — download it
          _llmService = LlmService(modelInfo: model);
          await _llmService!.initialize();
          if (mounted) _startDownload();
          return;
        }
      }

      // No saved key — check old default model (backward compat)
      const oldDefault = 'gemma-4-E2B-it.litertlm';
      if (await _modelFileExists(oldDefault)) {
        final gemma4 = ModelCatalog.byKey('gemma4_e2b')!;
        _llmService = LlmService(modelInfo: gemma4);
        if (db != null) {
          await db.setSetting('selected_model_key', 'gemma4_e2b');
        }
        try {
          await _llmService!.initialize();
          await _applySavedPrompt();
          await _llmService!.openExplanationChat();
          if (mounted) _proceed();
        } catch (e) {
          if (mounted) {
            setState(() {
              _phase = _ScreenPhase.error;
              _errorMessage = l10n.autoDetectFailed('$e');
              _statusText = l10n.loadFailed;
            });
          }
        }
        return;
      }

      // Nothing found — show selection screen
      if (mounted) {
        setState(() {
          _phase = _ScreenPhase.selecting;
          _statusText = l10n.chooseModelToStart;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _phase = _ScreenPhase.error;
          _errorMessage = '$e';
          _statusText = l10n.startupFailed;
        });
      }
    }
  }

  Future<bool> _modelFileExists(String filename) async {
    final appDir = await getApplicationSupportDirectory();
    final modelPath = p.join(appDir.path, 'models', filename);
    return File(modelPath).exists();
  }

  /// Apply a user-saved custom system prompt (if any) to the LLM service
  /// before opening the chat.
  Future<void> _applySavedPrompt() async {
    final db = widget.databaseService;
    final svc = _llmService;
    if (db == null || svc == null) return;
    final saved = await db.getSetting(LlmService.systemPromptSettingsKey);
    if (saved != null && saved.isNotEmpty) {
      svc.systemPrompt = saved;
    }
  }

  // ---------------------------------------------------------------------------
  // Download
  // ---------------------------------------------------------------------------

  Future<void> _startDownload() async {
    if (_llmService == null) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _phase = _ScreenPhase.downloading;
      _downloadProgress = 0.0;
      _statusText = l10n.downloadingPercent(0);
    });

    try {
      await _llmService!.downloadModel(
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _downloadProgress = progress;
              _statusText =
                  l10n.downloadingPercent((progress * 100).round());
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _phase = _ScreenPhase.loading;
          _statusText = l10n.loadingModel;
        });
        try {
          await _applySavedPrompt();
          await _llmService!.openExplanationChat();
          if (mounted) _proceed();
        } catch (openError) {
          if (mounted) {
            setState(() {
              _phase = _ScreenPhase.error;
              _errorMessage = l10n.modelDownloadedFailed('$openError');
              _statusText = l10n.chatSessionFailed;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _phase = _ScreenPhase.error;
          _errorMessage = l10n.downloadFailedWith('$e');
          _statusText = l10n.downloadFailed;
        });
      }
    }
  }

  Future<void> _selectModel(ModelInfo model) async {
    _llmService = LlmService(modelInfo: model);

    // Persist the selection immediately.
    final db = widget.databaseService;
    if (db != null) {
      await db.setSetting('selected_model_key', model.key);
    }

    await _llmService!.initialize();
    _startDownload();
  }

  GuaGenerator get _guaGenerator => GuaGenerator();

  void _proceed() {
    // Wire the GuaGenerator so the explanation prompt includes the cast
    // context (cast lines, line types, hexagram content).
    if (_llmService != null) {
      _llmService!.guaGenerator = _guaGenerator;
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => QuestionFormScreen(
          databaseService: widget.databaseService,
          llmService: _llmService,
        ),
      ),
    );
  }

  void _skipDownload() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            QuestionFormScreen(databaseService: widget.databaseService),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).setupTitle),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (_phase) {
      case _ScreenPhase.initialising:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(l10n.checkingSetup),
            ],
          ),
        );

      case _ScreenPhase.selecting:
        return _buildSelectionGrid(context);

      case _ScreenPhase.downloading:
        return _buildDownloadProgress(context);

      case _ScreenPhase.loading:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(l10n.loadingModel),
            ],
          ),
        );

      case _ScreenPhase.error:
        return _buildErrorView(context);
    }
  }

  Widget _buildSelectionGrid(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final models = ModelCatalog.all;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.chooseYourModel,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.modelsOffline,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          ...models.map(
            (model) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ModelCard(
                model: model,
                onTap: () => _confirmSelection(context, model),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmSelection(BuildContext context, ModelInfo model) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.downloadModelTitle(model.modelFamily)),
        content: Text(
          l10n.downloadModelBody(model.modelFamily, model.sizeLabel),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _selectModel(model);
            },
            child: Text(l10n.confirmDownload),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadProgress(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.downloading, size: 72),
            const SizedBox(height: 24),
            Text(
              _statusText,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(value: _downloadProgress),
            const SizedBox(height: 8),
            Text(
              '${(_downloadProgress * 100).toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).oneTimeDownload,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 72, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(_statusText, style: Theme.of(context).textTheme.titleMedium),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                ),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _skipDownload,
              icon: const Icon(Icons.chat),
              label: Text(AppLocalizations.of(context).continueAnyway),
            ),
          ],
        ),
      ),
    );
  }
}

/// A card widget that displays model info and responds to taps.
class _ModelCard extends StatelessWidget {
  final ModelInfo model;
  final VoidCallback onTap;

  const _ModelCard({required this.model, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                model.modelFamily,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                model.bestFor,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Chip(
                    label: Text(
                      model.language,
                      style: const TextStyle(fontSize: 11),
                    ),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(
                      model.sizeLabel,
                      style: const TextStyle(fontSize: 11),
                    ),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
