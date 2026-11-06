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
  String get consultationDetail => _t('Consultation', '諮詢紀錄');
  String get delete => _t('Delete', '刪除');
  String get deleteConsultationTitle =>
      _t('Delete this entry?', '刪除此紀錄？');
  String get deleteConsultationBody => _t(
        'It will be removed from your history.',
        '這將從您的歷史紀錄中移除。',
      );

  // --- Profile / agent memory -----------------------------------------
  String get lastConsultation => _t('Last consultation', '最近諮詢');
  String get memoryTitle => _t('Agent Memory', '智能記憶');
  String get memoryFeeling => _t('How you might feel', '你可能的心情');
  String get memoryTopics => _t('How you feel by topic', '各類主題的心情');
  String get memoryFacts => _t('Facts about you', '關於你的事實');
  String get memoryPreferences => _t('Your preferences', '你的偏好');
  String get memoryEmpty => _t(
        'No memory yet. Complete a consultation to build your profile.',
        '尚無記憶。完成一次諮詢後將建立您的檔案。',
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

  /// Personalized greeting on the Ask tab (issue #25).
  String get greetingWelcome => _t('Welcome back.', '歡迎回來。');
  String greetingWithFeeling(String feeling) => _t(
        'It sounds like you have been feeling $feeling.',
        '聽起來您最近感到$feeling。',
      );
  String greetingRemember(String detail) => _t(
        'I remember: $detail.',
        '我記得：$detail。',
      );

  /// Interpreter selector label (issue #22).
  String get interpreter => _t('Interpreter', '解讀者');

  String get questionType => _t('Question type', '問題類型');
  String get selectCategory => _t('Select a category', '選擇類別');
  String get yourQuestion => _t('Your question', '您的問題');
  String get questionHint => _t('Type your question here...', '在此輸入您的問題…');
  String get selectTypeError => _t('Please select a question type', '請選擇問題類型');
  String get enterQuestionError => _t('Please enter your question', '請輸入您的問題');
  String get generateHexagram => _t('Help me to generate hexagram', '幫我起卦');
  String get castingMethod => _t('Casting method', '起卦方式');
  String get quickGenerate => _t('Quick Generate', '快速起卦');
  String get manualGenerate => _t('Manual', '手動起卦');
  String get submitQuestion => _t('Submit Question', '提交問題');
  String get casting => _t('Casting...', '起卦中…');
  String get enableGenerationHint =>
      _t('Enable hexagram generation to begin your reading.', '請啟用起卦以開始您的解讀。');

  // --- Manual cast (issue #20) -----------------------------------------
  String get manualCastTitle => _t('Choose the six lines', '選擇六爻');
  String get manualCastHint =>
      _t('Tap a line to change it.', '點按爻線以更改。');
  String manualCastLine(int n) => _t('Line $n', '第$n爻');
  String get manualCastProceed => _t('Use this hexagram', '使用此卦');

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

  String get theme => _t('Theme', '主題');
  String get dark => _t('Dark', '深色');
  String get light => _t('Light', '淺色');

  String get prompts => _t('Prompts', '提示詞');
  String get systemPrompt => _t('System Prompt', '系統提示詞');
  String get systemPromptSubtitle => _t('Customize the LLM instruction', '自訂 LLM 指令');

  String get privacy => _t('Privacy', '隱私');
  String get privacyNotice => _t('Privacy Notice', '隱私聲明');
  String get privacySubtitle =>
      _t('How your data is handled', '資料如何處理');
  String get privacyNoticeBody => _t(
        'Explanations are generated by the selected AI model. Depending on '
            'your configuration, this may run on your device (flutter_gemma) '
            'or on a remote AI provider. On Android, remote explanations use '
            'Firebase AI Logic (Gemini).\n\n'
            'When a remote provider is used, your question and hexagram '
            'context are sent to it only to generate the explanation. All '
            'settings and consultations are stored locally on your device.\n\n'
            'No telemetry or analytics beyond the provider\'s standard traffic.',
        '解讀由所選的 AI 模型產生。視您的設定，模型可能在您的裝置上（'
            'flutter_gemma）或在遠端 AI 服務商上運行。在 Android 上，遠端解讀使用 '
            'Firebase AI Logic（Gemini）。\n\n'
            '使用遠端服務商時，您的問題與卦象內容僅會傳送給該服務商以產生解讀。'
            '所有設定與諮詢紀錄皆儲存於您的裝置本機。\n\n'
            '除服務商的標準流量外，不含任何遙測或分析。',
      );

  // --- Firebase remote consent (issue #86) -------------------------------
  String get firebaseConsentTitle => _t('Before we begin', '開始之前');
  String get firebaseConsentBody => _t(
        'To generate an explanation, your question and hexagram details are '
            'sent to Google\'s Gemini API through Firebase. Your consultation '
            'history stays on this device. No telemetry or analytics beyond '
            'the provider\'s traffic.',
        '為產生解讀，您的問題與卦象內容將透過 Firebase 傳送至 Google Gemini API。'
            '您的諮詢紀錄仍保留在裝置本機。除服務商的標準流量外，不含任何遙測或分析。',
      );
  String get firebaseConsentAgree => _t('Agree & continue', '同意並繼續');

  String get about => _t('About', '關於');
  String get version => _t('Version', '版本');

  // --- Model selection --------------------------------------------------
  String get setupTitle => _t('I-Ching Setup', '易經設定');
  String get chooseYourModel => _t('Choose Your Model', '選擇您的模型');
  String get modelsOffline => _t(
        'These on-device models run fully offline on your device.',
        '這些裝置端模型皆在您的裝置上離線運行。',
      );
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
        'This is a one-time download. The on-device model runs fully offline '
            'after installation.',
        '這是一次性下載。裝置端模型安裝後將完全離線運行。',
      );
  String get internetNotice => _t(
        'Internet is used to download the on-device model. If you configure a '
            'remote AI provider, your question and hexagram context are sent to '
            'that provider to generate the explanation.',
        '網路用於下載裝置端模型。若您設定遠端 AI 服務商，您的問題與卦象內容將傳送給'
            '該服務商以產生解讀。',
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
  String get original => _t('Original', '本卦');
  String get changed => _t('Changed', '變卦');
  String get changedHexagram =>
      _t('Changed hexagram (future state)', '變卦（未來之象）');
  String get getExplanation => _t('Get Explanation', '取得解讀');

  // --- Explanation ------------------------------------------------------
  String get explanation => _t('Explanation', '解讀');
  String get interpretation => _t('Interpretation', '解讀');
  String get generatingExplanation => _t(
        'Consulting the hexagram...',
        '正在為您解讀…',
      );
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
  String get feedbackTitle => _t('Feedback', '意見');
  String get feedbackPrompt => _t('How did you find the answer?', '您覺得這次解讀如何？');
  String get feedbackCommentHint => _t(
        'How do you feel about this, and what\'s your next step? (optional)',
        '你有何感受，以及下一步有何打算？（選填）',
      );
  String get feedbackSubmit => _t('Submit feedback', '送出回饋');
  String get feedbackThanks => _t('Thanks for your feedback!', '感謝您的意見！');

  // Reaction tooltips (issue #27).
  String get reactionHappy => _t('Happy', '開心');
  String get reactionLove => _t('Love', '喜愛');
  String get reactionSad => _t('Sad', '難過');
  String get reactionAngry => _t('Angry', '生氣');
  String get reactionSurprised => _t('Surprised', '驚訝');
  String get reactionHealing => _t('Healing', '療癒');

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
  String get resultSection => _t('Result', '結果');
  String get hexagramSymbolSection => _t('Hexagram', '卦象');
  String get symbolicMeaning => _t('Symbolic Meaning', '象徵意義');
  String get interpretations => _t('Interpretation', '解釋');
  String get modernInterpretation => _t('Modern & General', '現代白話／通解');
  String get otherInterpretations => _t('Other Interpretations', '其他的解釋');
  String get originalText => _t('Original Text', '原文');
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
  String get promptReadOnly => _t(
        'The system prompt is read-only in this version.',
        '此版本的系統提示詞為唯讀。',
      );
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
