import 'dart:ui';

/// Tiny Arabic / English string table. Language follows the device locale.
class S {
  static bool ar = true;

  static void init(Locale l) {
    ar = l.languageCode == 'ar';
  }

  static String _t(String a, String e) => ar ? a : e;

  static String get appName => _t('عكسها', 'Antitap');
  static String get tagline => _t('اعمل العكس!', 'Do the opposite!');
  static String get play => _t('العب', 'PLAY');
  static String get best => _t('أفضل نتيجة', 'Best');
  static String get gameOver => _t('خسرت!', 'Game over');
  static String get newBest => _t('رقم قياسي جديد! 🎉', 'New record! 🎉');
  static String get playAgain => _t('العب مجددًا', 'Play again');
  static String get cont => _t('تابع (شاهد إعلانًا)', 'Continue (watch ad)');
  static String get home => _t('الرئيسية', 'Home');

  // Loss reasons
  static String get timeUp => _t('انتهى الوقت', "Time's up");
  static String get wrongTap => _t('هذه كانت ممنوعة', 'That one was forbidden');
  static String get shouldWait =>
      _t('كان عليك ألا تفعل شيئًا', 'You should have done nothing');
  static String get rightAnswer =>
      _t('هذه هي الإجابة الصحيحة!', 'That was the correct answer!');
  static String get sameSide =>
      _t('ضغطت على نفس الاتجاه', 'You tapped the same side');

  // Round prompts
  static String get avoidBig =>
      _t('لا تضغط على الدائرة الكبيرة', "Don't tap the big circle");
  static String get wrongAnswer =>
      _t('اضغط على الإجابة الخاطئة!', 'Tap the WRONG answer!');
  static String get opposite =>
      _t('اضغط عكس اتجاه السهم', 'Tap the opposite side');
  static String avoidColor(String name) =>
      _t('اضغط على كل شيء ما عدا $name', 'Tap everything except $name');
  static List<String> get doNothing => ar
      ? ['اقفز!', 'اضغط الآن!', 'اركض!', 'أسرع!']
      : ['JUMP!', 'TAP NOW!', 'RUN!', 'HURRY!'];

  // Home screen examples
  static String get ex1 =>
      _t('اضغط على كل شيء ما عدا الأحمر', 'Tap everything except red');
  static String get ex2 =>
      _t('يقول «اقفز!» ... لا تفعل شيئًا', 'Says "JUMP!" ... do nothing');
  static String get ex3 =>
      _t('اضغط على الإجابة الخاطئة', 'Tap the wrong answer');
}
