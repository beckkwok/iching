/// Seed data for all 64 hexagrams (Gua) of the I-Ching.
///
/// Source: https://zh.wikipedia.org/wiki/周易六十四卦列表
/// Each entry includes the classical name, trigram composition, common name,
/// and a reflection-oriented summary.
class HexagramData {
  /// guaCode (1–64), guaName, guaContent (description), guaSummary, source
  static const List<Map<String, dynamic>> all = [
    {
      'gua_code': 1,
      'gua_name': '乾 (Qián)',
      'gua_content':
          '乾為天。上卦乾（天），下卦乾（天）。六爻皆陽，純陽之象。'
          '象徵天行健，自強不息。',
      'gua_summary':
          'Heaven above, heaven below. Pure creative energy in motion. '
          'This is a time of strength and initiative. Reflect on how you can '
          'move forward with integrity and perseverance.',
      'source': 'classical',
    },
    {
      'gua_code': 2,
      'gua_name': '坤 (Kūn)',
      'gua_content':
          '坤為地。上卦坤（地），下卦坤（地）。六爻皆陰，純陰之象。'
          '象徵地勢坤，厚德載物。',
      'gua_summary':
          'Earth above, earth below. Pure receptive power. '
          'This is a time to nurture, support, and yield — strength through '
          'stillness and devotion. Consider where patience and gentleness '
          'serve you best.',
      'source': 'classical',
    },
    {
      'gua_code': 3,
      'gua_name': '屯 (Zhūn)',
      'gua_content':
          '水雷屯。上卦坎（水），下卦震（雷）。天地定位後萬物生長，'
          '屯卦有「盈」「萬物始生」之意。',
      'gua_summary':
          'Water over thunder — clouds gathering, rain not yet fallen. '
          'A beginning full of promise but also difficulty. '
          'You are at the threshold of something new. '
          'What initial obstacles can you gently work through?',
      'source': 'classical',
    },
    {
      'gua_code': 4,
      'gua_name': '蒙 (Méng)',
      'gua_content':
          '山水蒙。上卦艮（山），下卦坎（水）。象徵萬物初生，'
          '「蒙昧」的狀態。',
      'gua_summary':
          'Mountain over water — a spring emerging from beneath a mountain. '
          'Youthful inexperience, but also openness and curiosity. '
          'This is a time for learning and asking questions. '
          'What are you ready to discover?',
      'source': 'classical',
    },
    {
      'gua_code': 5,
      'gua_name': '需 (Xū)',
      'gua_content':
          '水天需。上卦坎（水），下卦乾（天）。需為「飲食之道」，'
          '指萬物啟蒙後的養育。',
      'gua_summary':
          'Water over heaven — clouds building but rain not yet falling. '
          'A time of patient waiting and preparation. '
          'Trust the natural timing of things. What are you nourishing '
          'as it grows?',
      'source': 'classical',
    },
    {
      'gua_code': 6,
      'gua_name': '訟 (Sòng)',
      'gua_content':
          '天水訟。上卦乾（天），下卦坎（水）。為了飲食生活的「需」求，'
          '開始會有爭執，是為「爭訟」。',
      'gua_summary':
          'Heaven over water — the waters flow away, conflict arises. '
          'Differences of opinion may surface. '
          'Consider whether standing your ground serves you, or whether '
          'a middle path brings more peace.',
      'source': 'classical',
    },
    {
      'gua_code': 7,
      'gua_name': '師 (Shī)',
      'gua_content':
          '地水師。上卦坤（地），下卦坎（水）。師為軍隊之意，'
          '因為群眾的爭執，演變成「興兵為師」的狀況。',
      'gua_summary':
          'Earth over water — an army organised beneath the surface. '
          'Collective effort, discipline, and leadership. '
          'How can you organise your energy with purpose and compassion?',
      'source': 'classical',
    },
    {
      'gua_code': 8,
      'gua_name': '比 (Bǐ)',
      'gua_content':
          '水地比。上卦坎（水），下卦坤（地）。比為比鄰，親近友好之意，'
          '起兵興師後同群之人為「比」。',
      'gua_summary':
          'Water over earth — waters embrace the land. '
          'Union, alliance, and亲近. '
          'Who are your true companions? Reflect on the connections '
          'that support you.',
      'source': 'classical',
    },
    {
      'gua_code': 9,
      'gua_name': '小畜 (Xiǎo Chù)',
      'gua_content':
          '風天小畜。上卦巽（風），下卦乾（天）。小畜有集合之意，'
          '人們親近後開始集合。',
      'gua_summary':
          'Wind over heaven — gentle but accumulating force. '
          'Small accumulations leading to larger results. '
          'What small, consistent steps can you take right now?',
      'source': 'classical',
    },
    {
      'gua_code': 10,
      'gua_name': '履 (Lǚ)',
      'gua_content':
          '天澤履。上卦乾（天），下卦兌（澤）。履為踩踏之意，'
          '序卦傳另云：履者禮也。',
      'gua_summary':
          'Heaven over lake — walking step by step with care. '
          'Conduct, ritual, and mindful action. '
          'How do you carry yourself? Consider the grace in your '
          'every step.',
      'source': 'classical',
    },
    {
      'gua_code': 11,
      'gua_name': '泰 (Tài)',
      'gua_content':
          '地天泰。上卦坤（地），下卦乾（天）。泰為通達之意。',
      'gua_summary':
          'Earth over heaven — the energies intermingle in harmony. '
          'Peace, prosperity, and flow. '
          'Things are in balance. What can you do to sustain this '
          'harmony?',
      'source': 'classical',
    },
    {
      'gua_code': 12,
      'gua_name': '否 (Pǐ)',
      'gua_content':
          '天地否。上卦乾（天），下卦坤（地）。否為閉「塞」之意。',
      'gua_summary':
          'Heaven over earth — the energies separate and withdraw. '
          'Stagnation, obstruction. '
          'When things feel stuck, where can you find the inner stillness '
          'to wait for the cycle to turn?',
      'source': 'classical',
    },
    {
      'gua_code': 13,
      'gua_name': '同人 (Tóng Rén)',
      'gua_content':
          '天火同人。上卦乾（天），下卦離（火）。同人是「會同」、'
          '「協同」之意。',
      'gua_summary':
          'Heaven over fire — bright light shared by all. '
          ' Fellowship, community, shared purpose. '
          'How can you find common ground with those around you?',
      'source': 'classical',
    },
    {
      'gua_code': 14,
      'gua_name': '大有 (Dà Yǒu)',
      'gua_content':
          '火天大有。上卦離（火），下卦乾（天）。意指大的收穫。',
      'gua_summary':
          'Fire over heaven — abundance shining everywhere. '
          'Great possession, fullness. '
          'You have much. What are you grateful for, and how can you '
          'share your blessings?',
      'source': 'classical',
    },
    {
      'gua_code': 15,
      'gua_name': '謙 (Qiān)',
      'gua_content':
          '地山謙。上卦坤（地），下卦艮（山）。謙為謙遜之意。',
      'gua_summary':
          'Earth over mountain — hiding greatness beneath humility. '
          'Modesty, groundedness. '
          'True strength does not need to boast. Where in your life '
          'can humility bring you peace?',
      'source': 'classical',
    },
    {
      'gua_code': 16,
      'gua_name': '豫 (Yù)',
      'gua_content':
          '雷地豫。上卦震（雷），下卦坤（地）。豫為愉悅、預備之意。',
      'gua_summary':
          'Thunder over earth — excitement stirring beneath the surface. '
          'Joy, preparation, anticipation. '
          'What brings you genuine delight? Let that energy guide you.',
      'source': 'classical',
    },
    {
      'gua_code': 17,
      'gua_name': '隨 (Suí)',
      'gua_content':
          '澤雷隨。上卦兌（澤），下卦震（雷）。隨為跟隨、順從之意。',
      'gua_summary':
          'Lake over thunder — following the natural rhythm. '
          'Adaptability, following the moment. '
          'Sometimes wisdom is knowing when to follow rather than lead.',
      'source': 'classical',
    },
    {
      'gua_code': 18,
      'gua_name': '蠱 (Gǔ)',
      'gua_content':
          '山風蠱。上卦艮（山），下卦巽（風）。蠱有腐敗、整治之意。',
      'gua_summary':
          'Mountain over wind — decay beneath the surface. '
          'Corruption, renovation, setting things right. '
          'What in your life needs careful attention and repair?',
      'source': 'classical',
    },
    {
      'gua_code': 19,
      'gua_name': '臨 (Lín)',
      'gua_content':
          '地澤臨。上卦坤（地），下卦兌（澤）。臨為降臨、親臨之意。',
      'gua_summary':
          'Earth over lake — approaching presence. '
          'Approach, oversight, care. '
          'What is drawing near? How can you welcome it with '
          'open awareness?',
      'source': 'classical',
    },
    {
      'gua_code': 20,
      'gua_name': '觀 (Guān)',
      'gua_content':
          '風地觀。上卦巽（風），下卦坤（地）。觀為觀察、觀看之意。',
      'gua_summary':
          'Wind over earth — observing the patterns of life. '
          'Contemplation, perspective. '
          'Step back and observe without judgment. What do you see '
          'when you are not trying to control?',
      'source': 'classical',
    },
    {
      'gua_code': 21,
      'gua_name': '噬嗑 (Shì Kè)',
      'gua_content':
          '火雷噬嗑。上卦離（火），下卦震（雷）。噬嗑為咬合、'
          '以刑除奸之意。',
      'gua_summary':
          'Fire over thunder — biting through obstacles. '
          'Justice, clearing blockages. '
          'What barrier needs to be broken through with decisive action?',
      'source': 'classical',
    },
    {
      'gua_code': 22,
      'gua_name': '賁 (Bì)',
      'gua_content':
          '山火賁。上卦艮（山），下卦離（火）。賁為裝飾、文飾之意。',
      'gua_summary':
          'Mountain over fire — elegance and adornment. '
          'Grace, beauty, refinement. '
          'Look at the beauty around you. What touches your heart '
          'with its grace?',
      'source': 'classical',
    },
    {
      'gua_code': 23,
      'gua_name': '剝 (Bō)',
      'gua_content':
          '山地剝。上卦艮（山），下卦坤（地）。剝為剝落、潰爛之意。',
      'gua_summary':
          'Mountain over earth — layer by layer, things fall away. '
          'Collapse, stripping away. '
          'When things break down, what remains at the core? '
          'Sometimes loss clears the way for renewal.',
      'source': 'classical',
    },
    {
      'gua_code': 24,
      'gua_name': '復 (Fù)',
      'gua_content':
          '地雷復。上卦坤（地），下卦震（雷）。復為回復、復甦之意。',
      'gua_summary':
          'Earth over thunder — the turning point, return of light. '
          'Rebirth, renewal, the turning point. '
          'After darkness, light returns. What is reviving in your life?',
      'source': 'classical',
    },
    {
      'gua_code': 25,
      'gua_name': '无妄 (Wú Wàng)',
      'gua_content':
          '天雷无妄。上卦乾（天），下卦震（雷）。无妄為真誠、'
          '不虛偽之意。',
      'gua_summary':
          'Heaven over thunder — acting in accord with the natural way. '
          'Innocence, unexpected grace. '
          'Act from your authentic self without forcing outcomes. '
          'What arises when you let go of expectations?',
      'source': 'classical',
    },
    {
      'gua_code': 26,
      'gua_name': '大畜 (Dà Chù)',
      'gua_content':
          '山天大畜。上卦艮（山），下卦乾（天）。大畜為大聚集、'
          '大儲蓄之意。',
      'gua_summary':
          'Mountain over heaven — great accumulation. '
          'Reserve, potential held in store. '
          'You have gathered inner and outer resources. How will you '
          'use them wisely when the time comes?',
      'source': 'classical',
    },
    {
      'gua_code': 27,
      'gua_name': '頤 (Yí)',
      'gua_content':
          '山雷頤。上卦艮（山），下卦震（雷）。頤為養生、滋養之意。',
      'gua_summary':
          'Mountain over thunder — nourishing life. '
          'Nourishment, care of body and spirit. '
          'What truly nourishes you? Are you giving yourself the care '
          'you need?',
      'source': 'classical',
    },
    {
      'gua_code': 28,
      'gua_name': '大過 (Dà Guò)',
      'gua_content':
          '澤風大過。上卦兌（澤），下卦巽（風）。大過為過度、'
          '超越承載之意。',
      'gua_summary':
          'Lake over wind — the structure is overloaded. '
          'Great excess, crisis. '
          'When things feel overwhelming, what is the one small step '
          'that can restore balance?',
      'source': 'classical',
    },
    {
      'gua_code': 29,
      'gua_name': '坎 (Kǎn)',
      'gua_content':
          '坎為水。上卦坎（水），下卦坎（水）。雙水重險之象，'
          '象徵險難、深淵。',
      'gua_summary':
          'Water over water — repeated challenges. '
          'Danger, the abyss, the unknown. '
          'Face the difficulty with sincerity. What can you learn '
          'from navigating troubled waters?',
      'source': 'classical',
    },
    {
      'gua_code': 30,
      'gua_name': '離 (Lí)',
      'gua_content':
          '離為火。上卦離（火），下卦離（火）。雙火相疊之象，'
          '象徵光明、依附、文明。',
      'gua_summary':
          'Fire over fire — radiance and clarity. '
          'Illumination, dependence, warmth. '
          'What gives you light and clarity? What do you hold close '
          'that brings warmth to your life?',
      'source': 'classical',
    },
    {
      'gua_code': 31,
      'gua_name': '咸 (Xián)',
      'gua_content':
          '澤山咸。上卦兌（澤），下卦艮（山）。咸為感應、感動之意。',
      'gua_summary':
          'Lake over mountain — attraction and mutual influence. '
          'Feeling, courtship, connection. '
          'Open your heart to genuine connection. '
          'What moves you deeply?',
      'source': 'classical',
    },
    {
      'gua_code': 32,
      'gua_name': '恆 (Héng)',
      'gua_content':
          '雷風恆。上卦震（雷），下卦巽（風）。恆為持久、恆久之意。',
      'gua_summary':
          'Thunder over wind — enduring movement. '
          'Constancy, perseverance, long-lasting. '
          'What in your life is worth sustaining over the long term? '
          'Steadiness is its own reward.',
      'source': 'classical',
    },
    {
      'gua_code': 33,
      'gua_name': '遯 (Dùn)',
      'gua_content':
          '天山遯。上卦乾（天），下卦艮（山）。遯為退避、隱遁之意。',
      'gua_summary':
          'Heaven over mountain — retreating to preserve strength. '
          'Withdrawal, timely retreat. '
          'Sometimes wisdom is knowing when to step back. '
          'What can you release for now?',
      'source': 'classical',
    },
    {
      'gua_code': 34,
      'gua_name': '大壯 (Dà Zhuàng)',
      'gua_content':
          '雷天大壯。上卦震（雷），下卦乾（天）。大壯為盛大、強壯之意。',
      'gua_summary':
          'Thunder over heaven — great power and vitality. '
          'Strength, vigour, forward momentum. '
          'You have energy to act. Direct it with wisdom — '
          'not all that is strong needs to assert itself.',
      'source': 'classical',
    },
    {
      'gua_code': 35,
      'gua_name': '晉 (Jìn)',
      'gua_content':
          '火地晉。上卦離（火），下卦坤（地）。晉為前進、晉升之意。',
      'gua_summary':
          'Fire over earth — the sun rising over the land. '
          'Advancement, progress, visibility. '
          'You are moving forward. What brightens your path today?',
      'source': 'classical',
    },
    {
      'gua_code': 36,
      'gua_name': '明夷 (Míng Yí)',
      'gua_content':
          '地火明夷。上卦坤（地），下卦離（火）。明夷為光明受傷、'
          '晦暗之意。',
      'gua_summary':
          'Earth over fire — light hidden beneath the surface. '
          'Darkening of the light, injury to wisdom. '
          'In times of difficulty, keep your inner light safe. '
          'Patience — the dawn will come again.',
      'source': 'classical',
    },
    {
      'gua_code': 37,
      'gua_name': '家人 (Jiā Rén)',
      'gua_content':
          '風火家人。上卦巽（風），下卦離（火）。家人為家庭、家人之意。',
      'gua_summary':
          'Wind over fire — warmth spreading through the home. '
          'Family, kinship, belonging. '
          'Tend to your hearth and your relationships. '
          'What makes a home for you?',
      'source': 'classical',
    },
    {
      'gua_code': 38,
      'gua_name': '睽 (Kuí)',
      'gua_content':
          '火澤睽。上卦離（火），下卦兌（澤）。睽為乖離、對立之意。',
      'gua_summary':
          'Fire over lake — opposing forces, divergence. '
          'Opposition, estrangement, difference. '
          'Not all differences are conflicts. '
          'Can you find a way to honour what makes you unique '
          'while staying connected?',
      'source': 'classical',
    },
    {
      'gua_code': 39,
      'gua_name': '蹇 (Jiǎn)',
      'gua_content':
          '水山蹇。上卦坎（水），下卦艮（山）。蹇為跛足、行走困難之意。',
      'gua_summary':
          'Water over mountain — obstacles ahead on the path. '
          'Difficulty, halting progress. '
          'When the road is steep, slow down and find solid footing. '
          'What support can you call on?',
      'source': 'classical',
    },
    {
      'gua_code': 40,
      'gua_name': '解 (Xiè)',
      'gua_content':
          '雷水解。上卦震（雷），下卦坎（水）。解為解脫、解除之意。',
      'gua_summary':
          'Thunder over water — the storm breaks, tension releases. '
          'Deliverance, release, resolution. '
          'What has been holding you is loosening. '
          'Breathe and let the relief come.',
      'source': 'classical',
    },
    {
      'gua_code': 41,
      'gua_name': '損 (Sǔn)',
      'gua_content':
          '山澤損。上卦艮（山），下卦兌（澤）。損為減少、損失之意。',
      'gua_summary':
          'Mountain over lake — decreasing to increase. '
          'Loss, reduction, sacrifice. '
          'Sometimes we must let go to grow. What can you release '
          'that no longer serves you?',
      'source': 'classical',
    },
    {
      'gua_code': 42,
      'gua_name': '益 (Yì)',
      'gua_content':
          '風雷益。上卦巽（風），下卦震（雷）。益為增益、利益之意。',
      'gua_summary':
          'Wind over thunder — increase spreading everywhere. '
          'Gain, benefit, flourishing. '
          'Goodness is multiplying. Receive it graciously and '
          'let it flow through you to others.',
      'source': 'classical',
    },
    {
      'gua_code': 43,
      'gua_name': '夬 (Guài)',
      'gua_content':
          '澤天夬。上卦兌（澤），下卦乾（天）。夬為決斷、果決之意。',
      'gua_summary':
          'Lake over heaven — a decisive break, like a dam bursting. '
          'Resolution, decisive action. '
          'A moment of clarity calls for a firm decision. '
          'Trust your resolve.',
      'source': 'classical',
    },
    {
      'gua_code': 44,
      'gua_name': '姤 (Gòu)',
      'gua_content':
          '天風姤。上卦乾（天），下卦巽（風）。姤為相遇、邂逅之意。',
      'gua_summary':
          'Heaven over wind — an unexpected encounter. '
          'Meeting, encounter, coming together. '
          'Life brings unexpected meetings. Stay open — '
          'something or someone new may arrive.',
      'source': 'classical',
    },
    {
      'gua_code': 45,
      'gua_name': '萃 (Cuì)',
      'gua_content':
          '澤地萃。上卦兌（澤），下卦坤（地）。萃為聚集、薈萃之意。',
      'gua_summary':
          'Lake over earth — waters gathering into a community. '
          'Gathering, assembly, coming together. '
          'People and resources are converging. '
          'What is drawing everyone together?',
      'source': 'classical',
    },
    {
      'gua_code': 46,
      'gua_name': '升 (Shēng)',
      'gua_content':
          '地風升。上卦坤（地），下卦巽（風）。升為上升、晉升之意。',
      'gua_summary':
          'Earth over wind — rising upward like a plant growing. '
          'Ascending, pushing upward. '
          'Gradual progress is carrying you higher. Trust the ascent '
          'one step at a time.',
      'source': 'classical',
    },
    {
      'gua_code': 47,
      'gua_name': '困 (Kùn)',
      'gua_content':
          '澤水困。上卦兌（澤），下卦坎（水）。困為困厄、窮困之意。',
      'gua_summary':
          'Lake over water — drained, depleted, trapped. '
          'Exhaustion, hardship, being stuck. '
          'In difficulty, the wise person holds to what is true. '
          'What remains meaningful even in hardship?',
      'source': 'classical',
    },
    {
      'gua_code': 48,
      'gua_name': '井 (Jǐng)',
      'gua_content':
          '水風井。上卦坎（水），下卦巽（風）。井為水井、源泉之意。',
      'gua_summary':
          'Water over wind — a well that never runs dry. '
          'The wellspring, source of sustenance. '
      'Nourishment is available if you know where to draw from. '
          'What is your inner source of renewal?',
      'source': 'classical',
    },
    {
      'gua_code': 49,
      'gua_name': '革 (Gé)',
      'gua_content':
          '澤火革。上卦兌（澤），下卦離（火）。革為變革、革命之意。',
      'gua_summary':
          'Lake over fire — transformation through conflict of elements. '
          'Revolution, change, shedding the old. '
          'Change is coming. What needs to be transformed '
          'so something new can be born?',
      'source': 'classical',
    },
    {
      'gua_code': 50,
      'gua_name': '鼎 (Dǐng)',
      'gua_content':
          '火風鼎。上卦離（火），下卦巽（風）。鼎為烹飪之器，'
          '象徵養育、文明。',
      'gua_summary':
          'Fire over wind — the cauldron, a vessel for transformation. '
          'Civilisation, nourishment, alchemy. '
          'You have the tools to transform what is raw into what '
          'nourishes. What are you cooking in the vessel of your life?',
      'source': 'classical',
    },
    {
      'gua_code': 51,
      'gua_name': '震 (Zhèn)',
      'gua_content':
          '震為雷。上卦震（雷），下卦震（雷）。雙雷疊加之象，'
          '象徵驚雷、震動。',
      'gua_summary':
          'Thunder over thunder — shock and awakening. '
          'Arousal, crisis, sudden insight. '
          'A shake-up can be a call to awaken. '
          'What jolts you into presence?',
      'source': 'classical',
    },
    {
      'gua_code': 52,
      'gua_name': '艮 (Gèn)',
      'gua_content':
          '艮為山。上卦艮（山），下卦艮（山）。雙山疊加之象，'
          '象徵靜止、安止。',
      'gua_summary':
          'Mountain over mountain — stillness, inner calm. '
          'Rest, meditation, knowing when to stop. '
          'Find the stillness within. In the pause, you may '
          'hear what you have been missing.',
      'source': 'classical',
    },
    {
      'gua_code': 53,
      'gua_name': '漸 (Jiàn)',
      'gua_content':
          '風山漸。上卦巽（風），下卦艮（山）。漸為漸進、逐步之意。',
      'gua_summary':
          'Wind over mountain — gradual progress, like a bird learning to fly. '
          'Development, steady advance. '
          'Great things grow slowly. Honour your pace — '
          'each step forward is meaningful.',
      'source': 'classical',
    },
    {
      'gua_code': 54,
      'gua_name': '歸妹 (Guī Mèi)',
      'gua_content':
          '雷澤歸妹。上卦震（雷），下卦兌（澤）。歸妹為女子出嫁之意，'
          '象徵結合。',
      'gua_summary':
          'Thunder over lake — a joyful union, but not without challenge. '
          'Marriage, union, coming together. '
          'When two become one, each must still be true to themselves. '
          'What does harmony mean to you?',
      'source': 'classical',
    },
    {
      'gua_code': 55,
      'gua_name': '豐 (Fēng)',
      'gua_content':
          '雷火豐。上卦震（雷），下卦離（火）。豐為豐盛、豐收之意。',
      'gua_summary':
          'Thunder over fire — abundance and brilliance. '
          'Fullness, prosperity, great fortune. '
          'You are in a time of fullness. Enjoy it fully, '
          'but remember that all seasons change.',
      'source': 'classical',
    },
    {
      'gua_code': 56,
      'gua_name': '旅 (Lǚ)',
      'gua_content':
          '火山旅。上卦離（火），下卦艮（山）。旅為旅行、旅居之意。',
      'gua_summary':
          'Fire over mountain — a traveller passing through. '
          'The wanderer, the journey. '
          'You are a guest in this moment. What can you learn '
          'from being unattached?',
      'source': 'classical',
    },
    {
      'gua_code': 57,
      'gua_name': '巽 (Xùn)',
      'gua_content':
          '巽為風。上卦巽（風），下卦巽（風）。雙風重疊之象，'
          '象徵滲透、順從。',
      'gua_summary':
          'Wind over wind — gentle but penetrating. '
          'Gentleness, gradual influence. '
          'The soft can overcome the hard. How can persuasion '
          'and patience achieve what force cannot?',
      'source': 'classical',
    },
    {
      'gua_code': 58,
      'gua_name': '兌 (Duì)',
      'gua_content':
          '兌為澤。上卦兌（澤），下卦兌（澤）。雙澤重疊之象，'
          '象徵喜悅、交流。',
      'gua_summary':
          'Lake over lake — joy reflected and multiplied. '
          'Joy, communication, openness. '
          'True joy is shared. What brings you happiness, '
          'and how can you share it with others?',
      'source': 'classical',
    },
    {
      'gua_code': 59,
      'gua_name': '渙 (Huàn)',
      'gua_content':
          '風水渙。上卦巽（風），下卦坎（水）。渙為渙散、消散之意。',
      'gua_summary':
          'Wind over water — dispersion, scattering like mist. '
          'Dispersal, release, letting go. '
          'What needs to be released so clarity can emerge? '
          'Sometimes dissolving is a form of healing.',
      'source': 'classical',
    },
    {
      'gua_code': 60,
      'gua_name': '節 (Jié)',
      'gua_content':
          '水澤節。上卦坎（水），下卦兌（澤）。節為節制、節度之意。',
      'gua_summary':
          'Water over lake — boundaries and regulation. '
          'Moderation, discipline, structure. '
          'Freedom grows within wise limits. '
          'What boundaries can you set to protect your peace?',
      'source': 'classical',
    },
    {
      'gua_code': 61,
      'gua_name': '中孚 (Zhōng Fú)',
      'gua_content':
          '風澤中孚。上卦巽（風），下卦兌（澤）。中孚為內心誠信、'
          '中正之信。',
      'gua_summary':
          'Wind over lake — inner truth radiating outward. '
          'Inner sincerity, trust, integrity. '
          'When your heart is true, the world responds. '
          'What do you know in your core to be true?',
      'source': 'classical',
    },
    {
      'gua_code': 62,
      'gua_name': '小過 (Xiǎo Guò)',
      'gua_content':
          '雷山小過。上卦震（雷），下卦艮（山）。小過為稍微超過、'
          '小有過失之意。',
      'gua_summary':
          'Thunder over mountain — a slight excess, a small misstep. '
          'Small excesses, minor mistakes. '
          'Perfection is not the goal. What small adjustment '
          'can bring you back to centre?',
      'source': 'classical',
    },
    {
      'gua_code': 63,
      'gua_name': '既濟 (Jì Jì)',
      'gua_content':
          '水火既濟。上卦坎（水），下卦離（火）。既濟為已經完成、'
          '成功之意。',
      'gua_summary':
          'Water over fire — completion, harmony achieved. '
          'Already accomplished, balance. '
          'A cycle completes. Celebrate what you have achieved, '
          'and know that every ending holds a new beginning.',
      'source': 'classical',
    },
    {
      'gua_code': 64,
      'gua_name': '未濟 (Wèi Jì)',
      'gua_content':
          '火水未濟。上卦離（火），下卦坎（水）。未濟為尚未完成、'
          '有待努力之意。',
      'gua_summary':
          'Fire over water — not yet complete, the work continues. '
          'Incomplete, looking ahead. '
          'The journey is never truly over. What remains to be done? '
          'The future is open and full of potential.',
      'source': 'classical',
    },
  ];
}
