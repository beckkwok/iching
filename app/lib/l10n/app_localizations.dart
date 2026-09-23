import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/question_type.dart';

/// Hand-written localizations for the app (English / Traditional Chinese).
///
/// Wired into [MaterialApp] via [delegate] and [supportedLocales]. Access the
/// strings with [AppLocalizations.of], which falls back to English when no
/// delegate is installed (e.g. in isolated widget tests).
class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  /// True when the active locale is Chinese.
  bool get isChinese => locale.languageCode == 'zh';

  String _t(String en, String zh) => isChinese ? zh : en;

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('zh'),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// The localizations for [context], or an English instance when no
  /// [Localizations] delegate is present.
  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations) ??
      AppLocalizations(const Locale('en'));

  // --- Navigation (bottom bar) -----------------------------------------
  String get navHistory => _t('History', '歷史');
  String get navProfile => _t('Profile', '個人');
  String get navAsk => _t('Ask', '提問');
  String get navBrowse => _t('Browse', '卦象');
  String get navPreference => _t('Preference', '偏好');

  // --- Placeholder screens ---------------------------------------------
  String get historyEmpty => _t(
        'No consultations yet. Ask a question to get started.',
        '尚無諮詢紀錄。請提問以開始。',
      );
  String get profilePlaceholder => _t(
        'Profile settings are coming soon.',
        '個人設定即將推出。',
      );

  // --- Common -----------------------------------------------------------
  String get settings => _t('Settings', '設定');
  String get cancel => _t('Cancel', '取消');
  String get remove => _t('Remove', '移除');
  String get reset => _t('Reset', '重設');
  String get save => _t('Save', '儲存');
  String get close => _t('Close', '關閉');
  String get ok => _t('OK', '確定');
  String get loading => _t('Loading...', '載入中…');
  String get notAvailable => _t('Not available', '無法使用');
  String get error => _t('Error', '錯誤');

  // --- Question form ----------------------------------------------------
  String get askPrompt =>
      _t('What would you like to ask the I-Ching?', '您想向易經請教什麼？');
  String get questionType => _t('Question type', '問題類型');
  String get selectCategory => _t('Select a category', '選擇類別');
  String get yourQuestion => _t('Your question', '您的問題');
  String get questionHint => _t('Type your question here...', '在此輸入您的問題…');
  String get selectTypeError => _t('Please select a question type', '請選擇問題類型');
  String get enterQuestionError => _t('Please enter your question', '請輸入您的問題');
  String get generateHexagram => _t('Help me to generate hexagram', '幫我起卦');
  String get submitQuestion => _t('Submit Question', '提交問題');
  String get casting => _t('Casting...', '起卦中…');
  String get enableGenerationHint =>
      _t('Enable hexagram generation to begin your reading.', '請啟用起卦以開始您的解讀。');

  /// Localized label for a consultation [QuestionType].
  String questionTypeLabel(QuestionType type) {
    return switch (type) {
      QuestionType.careerAchievement => _t('Career Achievement', '事業成就'),
      QuestionType.intellectualMoralCultivation =>
        _t('Intellectual and moral cultivation', '進德修業'),
      QuestionType.timing => _t('Timing', '時機'),
      QuestionType.attitude => _t('Attitude', '心態'),
    };
  }

  // --- Settings ---------------------------------------------------------
  String get model => _t('Model', '模型');
  String get fileName => _t('File Name', '檔案名稱');
  String get fullPath => _t('Full Path', '完整路徑');
  String get removeModelFile => _t('Remove Model File', '移除模型檔案');
  String get removeModelFileTitle => _t('Remove Model File?', '移除模型檔案？');
  String get removeModelFileBody => _t(
        'This will delete the model file and reset your selection. '
            'The app will restart with the model selection screen.',
        '這將刪除模型檔案並重設您的選擇。應用程式將重新啟動至模型選擇畫面。',
      );
  String get noLlmService => _t('No LLM service', '無 LLM 服務');
  String get failedToRemoveModel => _t('Failed to remove model: ', '移除模型失敗：');

  String get language => _t('Language', '語言');
  String get english => _t('English', '英文');
  String get chinese => _t('中文 (Chinese)', '中文');

  String get prompts => _t('Prompts', '提示詞');
  String get systemPrompt => _t('System Prompt', '系統提示詞');
  String get systemPromptSubtitle => _t('Customize the LLM instruction', '自訂 LLM 指令');

  String get privacy => _t('Privacy', '隱私');
  String get privacyNotice => _t('Privacy Notice', '隱私聲明');
  String get privacySubtitle =>
      _t('Data stays local, no internet calls', '資料保留在本機，不連線網路');
  String get privacyNoticeBody => _t(
        'This app runs entirely offline. No data is sent to any server.\n\n'
            'All settings and hexagram data are stored locally on your device. '
            'The AI model runs on-device via flutter_gemma.\n\n'
            'No internet connection is required after the initial model '
            'download. Your privacy is fully protected.',
        '本應用程式完全離線運行，不會將任何資料傳送至伺服器。\n\n'
            '所有設定與卦象資料皆儲存於您的裝置本機，AI 模型透過 '
            'flutter_gemma 在裝置上運行。\n\n'
            '首次下載模型後即無需網路連線，您的隱私受到完整保護。',
      );

  String get about => _t('About', '關於');
  String get version => _t('Version', '版本');

  // --- Model selection --------------------------------------------------
  String get setupTitle => _t('I-Ching Setup', '易經設定');
  String get chooseYourModel => _t('Choose Your Model', '選擇您的模型');
  String get modelsOffline =>
      _t('All models run fully offline on your device.', '所有模型皆在您的裝置上離線運行。');
  String downloadModelTitle(String name) => _t('Download $name?', '下載 $name？');
  String downloadModelBody(String name, String size) => _t(
        'This will download the $name model ($size).\n\n'
            'Once confirmed, the model choice cannot be changed later.',
        '這將下載 $name 模型（$size）。\n\n確認後將無法再更改模型選擇。',
      );
  String get confirmDownload => _t('Confirm & Download', '確認並下載');
  String get checkingSetup => _t('Checking setup...', '檢查設定中…');
  String get chooseModelToStart => _t('Choose a model to get started', '選擇模型以開始');
  String get loadingModel => _t('Loading model...', '載入模型中…');
  String downloadingPercent(int percent) =>
      _t('Downloading... $percent%', '下載中… $percent%');
  String get oneTimeDownload => _t(
        'This is a one-time download. The model runs fully offline after '
            'installation.',
        '這是一次性下載。安裝後模型將完全離線運行。',
      );
  String get internetNotice => _t(
        'Internet is used only to download the model. Your questions and '
            'personal data stay on your device and are never uploaded.',
        '網路僅用於下載模型。您的問題與個人資料保留在裝置上，絕不會上傳。',
      );
  String get startupFailed => _t('Startup failed', '啟動失敗');
  String get loadFailed => _t('Load failed', '載入失敗');
  String get chatSessionFailed => _t('Chat session failed', '工作階段失敗');
  String get downloadFailed => _t('Download failed', '下載失敗');
  String get continueAnyway => _t('Continue anyway', '仍要繼續');
  String modelLoadFailed(String error) =>
      _t('Model file found but failed to load: $error', '找到模型檔案但載入失敗：$error');
  String modelDownloadedFailed(String error) =>
      _t('Model downloaded but failed to load: $error', '模型已下載但載入失敗：$error');
  String downloadFailedWith(String error) =>
      _t('Download failed: $error', '下載失敗：$error');

  // --- Cast result ------------------------------------------------------
  String get backToQuestion => _t('Back to question', '返回問題');
  String get tapForDetails => _t('Tap for details', '點擊查看詳情');
  String get linePattern => _t('Line pattern', '爻象');
  String get noCastDetails => _t('No cast details available.', '無起卦詳情。');
  String get getExplanation => _t('Get Explanation', '取得解讀');

  // --- Explanation ------------------------------------------------------
  String get explanation => _t('Explanation', '解讀');
  String get interpretation => _t('Interpretation', '解讀');
  String get noModelExplanation => _t(
        'No model available to provide an explanation. '
            'Here is the hexagram that was cast — reflect on its imagery '
            'in relation to your question.',
        '目前沒有可提供解讀的模型。以下為您所起的卦——請對照您的問題，'
            '反思其卦象。',
      );
  String failedExplanation(String error) =>
      _t('Failed to generate explanation: $error', '產生解讀失敗：$error');

  // --- Feedback ---------------------------------------------------------
  String get feedbackTitle => _t('Feedback', '意見回饋');
  String get feedbackPrompt => _t('How did you find the answer?', '您覺得這次解讀如何？');
  String get feedbackCommentHint => _t('Any thoughts? (optional)', '有何想法？（選填）');
  String get feedbackSubmit => _t('Submit feedback', '送出回饋');
  String get feedbackThanks => _t('Thanks for your feedback!', '感謝您的回饋！');

  // --- Hexagram browser / detail ---------------------------------------
  String hexagramNumber(int code) => _t('Hexagram $code', '第$code卦');
  String get hexagrams => _t('Hexagrams', '六十四卦');
  String get noHexagrams => _t('No hexagrams found.', '找不到卦。');
  String get recentlyViewed => _t('Recently viewed', '最近查看');
  String unableToRead(String name) =>
      _t('Unable to read the hexagram content for $name.', '無法讀取 $name 的卦文。');

  String get judgment => _t('Judgment', '卦辭');
  String get tuanCommentary => _t('Tuan Commentary', '彖傳');
  String get greatImage => _t('Great Image', '大象傳');
  String get lineTexts => _t('Line Texts', '爻辭');
  String get smallImage => _t('Small Image', '小象傳');
  String get symbolicMeaning => _t('Symbolic Meaning', '象徵意義');
  String get interpretations => _t('Interpretations', '不同人解讀');
  String get remarks => _t('Remarks', '備註');
  String get basicSymbol => _t('Basic Symbol', '基本卦象');
  String get structure => _t('Structure', '卦體');
  String get naturalImage => _t('Natural Image', '自然取象');
  String get explanationLabel => _t('Explanation', '說明');
  String get mainSymbols => _t('Main Symbols', '主要象徵');
  String get lifeSymbols => _t('Life & Divination Symbols', '生活與占事常見象徵');
  String get summary => _t('Summary', '總結');
  String get judgmentInterpretation => _t('Judgment interpretation', '卦辭解讀');

  // --- Prompt editor ----------------------------------------------------
  String get editInstruction => _t(
        'Edit the instruction sent to the model before each consultation.',
        '編輯每次諮詢前傳送給模型的指令。',
      );
  String get promptHint => _t('Enter your system prompt...', '輸入您的系統提示詞…');
  String get promptSaved => _t('Prompt saved.', '提示詞已儲存。');
  String failedToSavePrompt(String error) =>
      _t('Failed to save prompt: $error', '儲存提示詞失敗：$error');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales
          .any((l) => l.languageCode == locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture(AppLocalizations(locale));

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
