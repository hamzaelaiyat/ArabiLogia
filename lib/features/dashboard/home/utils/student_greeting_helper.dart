import 'dart:math';

class StudentGreetingParts {
  final String prefix;
  final String name;

  const StudentGreetingParts({required this.prefix, required this.name});

  String get full => '$prefix $name';
}

class StudentGreetingHelper {
  StudentGreetingHelper._();

  // Session Caching to prevent text from changing when switching pages!
  static StudentGreetingParts? _sessionGreetingParts;
  static String? _sessionStudentName;
  static String? _sessionTeacherQuote;

  /// Call this if user logs out or app resets
  static void resetSession() {
    _sessionGreetingParts = null;
    _sessionStudentName = null;
    _sessionTeacherQuote = null;
  }

  // Primary list of boys names
  static const List<String> boyNames = [
    'محمد',
    'علي',
    'سيد',
    'جمعة',
    'رمضان',
    'احمد',
    'عمر',
    'حمزة',
    'محمود',
    'مصطفى',
    'يوسف',
    'ابراهيم',
    'حسين',
    'حسن',
    'عبدالله',
    'عبدالرحمن',
    'عبدالعزيز',
    'زياد',
    'كريم',
    'خالد',
    'طارق',
    'عمرو',
    'حسام',
    'وليد',
    'مازن',
    'أنس',
    'بلال',
    'ياسين',
    'حازم',
    'فارس',
    'سامح',
    'إسلام',
    'أشرف',
    'عادل',
    'ايمن',
    'تامر',
    'شريف',
    'رامي',
    'مروان',
    'مؤمن',
    'باسم',
  ];

  // Primary list of girls names
  static const List<String> girlNames = [
    'سارة',
    'جميلة',
    'حبيبة',
    'هبة',
    'همس',
    'مريم',
    'نور',
    'فاطمة',
    'اية',
    'ندى',
    'شهد',
    'ياسمين',
    'سلمى',
    'رنا',
    'جنى',
    'هنا',
    'ملك',
    'فريدة',
    'منار',
    'رحمة',
    'رضوى',
    'ريماس',
    'بسنت',
    'دعاء',
    'شيماء',
    'ريهام',
    'امنية',
    'اسماء',
    'نجلاء',
    'منى',
    'مها',
    'نورهان',
    'هدير',
    'مي',
    'دينا',
    'داليا',
    'اروى',
    'شروق',
    'جود',
    'ليان',
  ];

  /// Strictly normalizes Arabic letters to unify shapes (وحّد الأشكال):
  static String normalizeArabicText(String text) {
    if (text.isEmpty) return text;
    var result = text;
    // Remove diacritics / tashkeel (\u064B-\u065B, \u0670) and tatweel (\u0640)
    result = result.replaceAll(RegExp(r'[\u064B-\u065B\u0670\u0640]'), '');

    // Convert every Alef variant (أ آ إ ٱ) to ا
    result = result.replaceAll(RegExp(r'[أآإٱ]'), 'ا');

    // Convert Taa Marbouta (ة) and Haa (ه) to ه
    result = result.replaceAll(RegExp(r'[ةه]'), 'ه');

    // Convert Yaa (ي), Alef Maqsura (ى), Hamza Yaa (ئ) to ي
    result = result.replaceAll(RegExp(r'[يىئ]'), 'ي');

    // Convert Hamza Waw (ؤ) to و
    result = result.replaceAll('ؤ', 'و');

    return result.trim();
  }

  /// Returns structured greeting parts, cached for the current session until app resets
  static StudentGreetingParts getGreetingParts(String? fullName) {
    if (_sessionGreetingParts != null && _sessionStudentName == fullName) {
      return _sessionGreetingParts!;
    }

    final random = Random();
    StudentGreetingParts parts;

    if (fullName == null || fullName.trim().isEmpty) {
      final prefixes = ['منور يا', 'عامل ايه يا', 'كله تمام يا'];
      final titles = ['كبير', 'برنس', 'دفعة', 'بطل'];
      parts = StudentGreetingParts(
        prefix: prefixes[random.nextInt(prefixes.length)],
        name: titles[random.nextInt(titles.length)],
      );
    } else {
      final rawFirstName = fullName.trim().split(' ').first;
      final normalizedFirstName = normalizeArabicText(rawFirstName);

      final isBoy = boyNames.any(
        (name) => normalizeArabicText(name) == normalizedFirstName,
      );
      final isGirl = girlNames.any(
        (name) => normalizeArabicText(name) == normalizedFirstName,
      );

      if (isBoy) {
        final boyPrefixes = [
          'منور يا',
          'عامل ايه يا',
          'كله تمام يا',
          'منور الدنيا يا',
          'أهلاً بيك يا',
        ];
        parts = StudentGreetingParts(
          prefix: boyPrefixes[random.nextInt(boyPrefixes.length)],
          name: rawFirstName,
        );
      } else if (isGirl) {
        final girlPrefixes = [
          'منورة يا',
          'عامله ايه يا',
          'كله تمام يا',
          'منورة الدنيا يا',
          'أهلاً بيكي يا',
        ];
        parts = StudentGreetingParts(
          prefix: girlPrefixes[random.nextInt(girlPrefixes.length)],
          name: rawFirstName,
        );
      } else {
        final prefixes = ['منور يا', 'عامل ايه يا', 'كله تمام يا'];
        final titles = ['كبير', 'برنس', 'دفعة', 'بطل'];
        parts = StudentGreetingParts(
          prefix: prefixes[random.nextInt(prefixes.length)],
          name: titles[random.nextInt(titles.length)],
        );
      }
    }

    _sessionStudentName = fullName;
    _sessionGreetingParts = parts;
    return parts;
  }

  /// Single line full greeting string
  static String getGreeting(String? fullName) {
    return getGreetingParts(fullName).full;
  }

  /// Get teacher motivational message, PERMANENT for current session until app resets
  static String getTeacherQuote({
    int uncompletedLecturesCount = 3,
    DateTime? now,
  }) {
    if (_sessionTeacherQuote != null) {
      return _sessionTeacherQuote!;
    }

    final date = now ?? DateTime.now();
    final hour = date.hour;
    final month = date.month;
    final day = date.day;
    final random = Random();
    String quote;

    // 1) Late Night Condition (11:00 PM to 4:59 AM)
    if (hour >= 23 || hour < 5) {
      final nightQuotes = [
        'وجدنا بومة في اخر الليل تفتح هذا التطبيق',
        'نام وكمل بكرة كفاية',
        'الغربان كتروا',
      ];
      quote = nightQuotes[random.nextInt(nightQuotes.length)];
    }
    // 2) June or early July (Exams Season) Condition
    else if (month == DateTime.june || (month == DateTime.july && day <= 10)) {
      final examSeasonQuotes = [
        'بتعمل ايه والامتحانات قربت؟',
        'اعتقد مش لازم تهدر اي وقت وتجري عالتاب التانية',
      ];
      quote = examSeasonQuotes[random.nextInt(examSeasonQuotes.length)];
    }
    // 3) Morning Condition (5:00 AM to 11:59 AM)
    else if (hour >= 5 && hour < 12) {
      if (uncompletedLecturesCount > 2) {
        quote = 'صبح صباحك عالمتراكم يا صياحك';
      } else {
        final morningQuotes = [
          'طب روح افطر يا كبير',
          'شكلك لسة صاحي',
          'دحيح من يوم ما اتولدت',
        ];
        quote = morningQuotes[random.nextInt(morningQuotes.length)];
      }
    }
    // 4) Backlog (> 2 lectures not 50% completed) Condition
    else if (uncompletedLecturesCount > 2) {
      final backlogQuotes = [
        'روح شوف الي وراك',
        'المستر بيقولك روح لم المتراكم',
        'متفكرش كتير وبص عالتاب التانية',
      ];
      quote = backlogQuotes[random.nextInt(backlogQuotes.length)];
    }
    // Default fallback
    else {
      final generalQuotes = [
        'المستر بيقولك شد حيلك وتابع المحاضرات أول بأول!',
        'المستر بيقولك كل اختبار بيقربك خطوة للقمة 🎯',
        'المستر بيقولك أنت قدها وفي كل مرحلة بتبهرنا 🌟',
      ];
      quote = generalQuotes[random.nextInt(generalQuotes.length)];
    }

    _sessionTeacherQuote = quote;
    return quote;
  }
}
