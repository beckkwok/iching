import 'package:flutter/material.dart';
import '../services/llm_service.dart';
import 'chat_screen.dart';
import '../services/database_service.dart';

class ModelDownloadScreen extends StatefulWidget {
  final DatabaseService? databaseService;

  const ModelDownloadScreen({super.key, required this.databaseService});

  @override
  State<ModelDownloadScreen> createState() => _ModelDownloadScreenState();
}

class _ModelDownloadScreenState extends State<ModelDownloadScreen> {
  final _tokenController = TextEditingController();
  final _llmService = LlmService();

  bool _initialising = true;
  bool _modelFound = false;
  bool _downloading = false;
  double _downloadProgress = 0.0;
  String? _errorMessage;
  bool _downloadCompleted = false;
  String _statusText = 'Initialising...';

  @override
  void initState() {
    super.initState();
    _initialise();
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _initialise() async {
    try {
      await _llmService.initialize();
      final installed = await _llmService.isModelInstalled();
      if (mounted) {
        setState(() {
          _modelFound = installed;
          _initialising = false;
          _statusText = installed
              ? 'Model ready!'
              : 'Qwen3 0.6B needs to be downloaded (586 MB)';
        });
      }
      if (installed) {
        try {
          await _llmService.openChat();
          if (mounted) _proceedToChat();
        } catch (e) {
          if (mounted) {
            setState(() {
              _statusText = 'Model found but failed to load';
              _errorMessage = '$e';
              _downloadCompleted = true;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _initialising = false;
          _errorMessage = 'Failed to initialise: $e';
          _statusText = 'Initialisation failed';
        });
      }
    }
  }

  Future<void> _startDownload() async {
    final token = _tokenController.text.trim();
    setState(() {
      _downloading = true;
      _errorMessage = null;
      _statusText = 'Downloading model...';
      _downloadProgress = 0.0;
    });

    try {
      await _llmService.downloadModel(
        token: token.isNotEmpty ? token : null,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _downloadProgress = progress;
              _statusText =
                  'Downloading... ${(progress * 100).toStringAsFixed(0)}%';
            });
          }
        },
      );

      if (mounted) {
        setState(() => _statusText = 'Opening chat session...');
        try {
          await _llmService.openChat();
          if (mounted) _proceedToChat();
        } catch (openError) {
          if (mounted) {
            setState(() {
              _downloading = false;
              _errorMessage =
                  'Model downloaded but failed to load: $openError';
              _statusText = 'Chat session failed';
              _downloadCompleted = true;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _downloading = false;
          _errorMessage = 'Download failed: $e';
          _statusText = 'Download failed';
        });
      }
    }
  }

  void _proceedToChat() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          databaseService: widget.databaseService,
          llmService: _llmService,
        ),
      ),
    );
  }

  void _skipDownload() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          databaseService: widget.databaseService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('I-Ching Setup'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _modelFound
                    ? Icons.check_circle
                    : _downloading
                        ? Icons.downloading
                        : Icons.auto_awesome,
                size: 72,
                color: _modelFound
                    ? Colors.green
                    : Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),

              Text(
                _statusText,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),

              if (_initialising) const CircularProgressIndicator(),

              if (_downloading) ...[
                LinearProgressIndicator(value: _downloadProgress),
                const SizedBox(height: 8),
                Text(
                  '${(_downloadProgress * 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                const Text(
                  'This is a one-time download. '
                  'The model runs fully offline after installation.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],

              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
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
                // If the model was downloaded but chat failed, still let user proceed
                if (_downloadCompleted) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: _proceedToChat,
                      icon: const Icon(Icons.chat),
                      label: const Text('Continue to chat anyway'),
                    ),
                  ),
                ],
              ],

              if (!_initialising && !_modelFound && !_downloading && !_downloadCompleted) ...[
                const SizedBox(height: 24),
                Text(
                  'Download Qwen3 0.6B — an open-source LLM.\n'
                  'A HuggingFace token is optional (not required for this model).',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _tokenController,
                  decoration: const InputDecoration(
                    labelText: 'HuggingFace Token (optional)',
                    hintText: 'hf_...',
                    border: OutlineInputBorder(),
                    helperText: 'Only needed for gated models',
                  ),
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _startDownload(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _startDownload,
                    icon: const Icon(Icons.download),
                    label: const Text('Download Qwen3 0.6B (586 MB)'),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _skipDownload,
                  child: const Text(
                    'Skip — use placeholder responses',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],

              if (_modelFound && !_initialising && _errorMessage == null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Qwen3 0.6B is ready!\nStarting chat...',
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
