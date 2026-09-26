import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arabilogia/features/admin/services/docx_exam_parser.dart';

/// Builds a minimal in-memory .docx from a list of paragraphs.
/// Each paragraph is a map of runs: {'text': ..., 'color': ...} so we can
/// simulate white-colored braces in a separate run.
Uint8List buildDocx(List<List<Map<String, String>>> paragraphs) {
  final runsXml = StringBuffer();

  for (final para in paragraphs) {
    runsXml.write('<w:p>');
    for (final run in para) {
      final text = run['text']!;
      final color = run['color'];
      if (color != null) {
        runsXml.write(
          '<w:r><w:rPr><w:color w:val="$color"/></w:rPr>'
          '<w:t xml:space="preserve">$text</w:t></w:r>',
        );
      } else {
        runsXml.write(
          '<w:r><w:t xml:space="preserve">$text</w:t></w:r>',
        );
      }
    }
    runsXml.write('</w:p>');
  }

  final documentXml = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    $runsXml
  </w:body>
</w:document>
''';

  final archive = Archive()
    ..addFile(ArchiveFile.string(
      'word/document.xml',
      documentXml,
    ));

  return Uint8List.fromList(ZipEncoder().encode(archive));
}

List<Map<String, String>> run(String text, {String? color}) =>
    [{'text': text, if (color != null) 'color': color}];

void main() {
  group('DocxExamParser braces format', () {
    test('detects {Question}: with أ- ب- ج- د- options', () {
      final bytes = buildDocx([
        run('{ما عاصمة مصر؟}:'),
        run('أ- القاهرة'),
        run('ب- الإسكندرية'),
        run('ج- الجيزة'),
        run('د- الأقصر'),
      ]);

      final result = DocxExamParser.parse(bytes);

      expect(result.questions.length, 1);
      expect(result.questions.first.text, 'ما عاصمة مصر؟');
      expect(result.questions.first.options, [
        'القاهرة',
        'الإسكندرية',
        'الجيزة',
        'الأقصر',
      ]);
    });

    test('detects {Question} without trailing colon and with white braces', () {
      final bytes = buildDocx([
        [
          {'text': '{', 'color': 'FFFFFF'},
          {'text': 'ماذا يعني النحو؟'},
          {'text': '}', 'color': 'FFFFFF'},
          {'text': ':'},
        ],
        run('أ- علم الإعراب'),
        run('ب- علم البيان'),
        run('ج- علم البديع'),
        run('د- علم الصرف'),
      ]);

      final result = DocxExamParser.parse(bytes);

      expect(result.questions.length, 1);
      expect(result.questions.first.text, 'ماذا يعني النحو؟');
      expect(result.questions.first.options.length, 4);
    });

    test('detects multiple brace questions', () {
      final bytes = buildDocx([
        run('{س1}:'),
        run('أ- خيار1'),
        run('ب- خيار2'),
        run('ج- خيار3'),
        run('د- خيار4'),
        run('{س2}:'),
        run('أ- صحيح'),
        run('ب- خطأ'),
        run('ج- غير معروف'),
        run('د- لا شيء'),
      ]);

      final result = DocxExamParser.parse(bytes);

      expect(result.questions.length, 2);
      expect(result.questions[0].text, 'س1');
      expect(result.questions[1].text, 'س2');
    });
  });

  group('DocxExamParser other formats', () {
    test('detects quoted passage followed by lettered options', () {
      final bytes = buildDocx([
        run('"قال الشاعر: العلم نور"'),
        run('{ماذا قال الشاعر؟}:'),
        run('أ- العلم نور'),
        run('ب- الجهل ظلام'),
        run('ج- النور علم'),
        run('د- لا شيء'),
      ]);

      final result = DocxExamParser.parse(bytes);

      expect(result.passages.length, 1);
      expect(result.passages.first.content, 'قال الشاعر: العلم نور');
      expect(result.questions.length, 1);
    });

    test('detects western-numbered questions with dart options', () {
      final bytes = buildDocx([
        run('1. ما هي اللغة العربية؟'),
        run('أ- لغة عظيمة'),
        run('ب- لغة قديمة'),
        run('ج- لغة معاصرة'),
        run('د- لغة جديدة'),
      ]);

      final result = DocxExamParser.parse(bytes);

      expect(result.questions.length, 1);
      expect(
        result.questions.first.text,
        'ما هي اللغة العربية؟',
      );
    });

    test('detects Arabic-numbered questions', () {
      final bytes = buildDocx([
        run('١. ما هي لغة القرآن؟'),
        run('أ- العربية'),
        run('ب- الإنجليزية'),
        run('ج- الفرنسية'),
        run('د- الإسبانية'),
      ]);

      final result = DocxExamParser.parse(bytes);

      expect(result.questions.length, 1);
      expect(result.questions.first.text, 'ما هي لغة القرآن؟');
    });
  });

  group('DocxExamParser triple-quoted passage format', () {
    test('parses a """ ... """ passage on a single line', () {
      final bytes = buildDocx([
        run('""" العلم نور في زمن التقدم، والجهل ظلام يهدي صاحبه."""'),
      ]);

      final result = DocxExamParser.parse(bytes);

      expect(result.passages.length, 1);
      expect(
        result.passages.first.content,
        'العلم نور في زمن التقدم، والجهل ظلام يهدي صاحبه.',
      );
    });

    test('parses a multi-line """ ... """ passage', () {
      final bytes = buildDocx([
        run('"""العلم نور في زمن التقدم،'),
        run('والجهل ظلام يهدي صاحبه."""'),
      ]);

      final result = DocxExamParser.parse(bytes);

      expect(result.passages.length, 1);
      expect(
        result.passages.first.content,
        contains('العلم نور في زمن التقدم،'),
      );
      expect(
        result.passages.first.content,
        contains('والجهل ظلام يهدي صاحبه.'),
      );
    });

    test('parses pN. passage questions after a """ """ passage', () {
      final bytes = buildDocx([
        run('""" نص القراءة الكامل لمجموعة الأسئلة النصية """'),
        run('p1. ما موضوع النص السابق؟'),
        run('أ- العلم'),
        run('ب- الجهل'),
        run('ج- المال'),
        run('د- الشهرة'),
        run('p2. ما الخلاصة التي يُرشّد إليها النص؟'),
        run('a- طلب العلم'),
        run('b- جمع المال'),
        run('c- حب السفر'),
        run('d- اتخاذ الجاه'),
      ]);

      final result = DocxExamParser.parse(bytes);

      expect(result.passages.length, 1);
      expect(
        result.passages.first.content,
        'نص القراءة الكامل لمجموعة الأسئلة النصية',
      );
      expect(result.questions.length, 2);
      expect(result.questions[0].text, 'ما موضوع النص السابق؟');
      expect(result.questions[0].options.length, 4);
      expect(result.questions[1].text, 'ما الخلاصة التي يُرشّد إليها النص؟');
      expect(result.questions[1].options.length, 4);
    });

    test('parses فN. and فـN. passage questions', () {
      final bytes = buildDocx([
        run('""" نص فقرة القراءة """'),
        run('ف1. ما الفكرة الرئيسية للنص؟'),
        run('أ- التعليم'),
        run('ب- الصحة'),
        run('ج- الرياضة'),
        run('د- الفن'),
        run('فـ2. ماذا علينا أن نفعل؟'),
        run('أ- التعلم'),
        run('ب- اللعب'),
        run('ج- النوم'),
        run('د- الأكل'),
      ]);

      final result = DocxExamParser.parse(bytes);

      expect(result.questions.length, 2);
      expect(result.questions[0].text, 'ما الفكرة الرئيسية للنص؟');
      expect(result.questions[1].text, 'ماذا علينا أن نفعل؟');
      expect(result.questions[0].options.length, 4);
      expect(result.questions[1].options.length, 4);
    });

    test('mixes normal numbered and passage-numbered questions', () {
      final bytes = buildDocx([
        run('1. سؤال عادي خارج النص'),
        run('أ- خيار أ'),
        run('ب- خيار ب'),
        run('ج- خيار ج'),
        run('د- خيار د'),
        run('""" فقرة القراءة النصية """'),
        run('p1. سؤال بخصوص الفقرة'),
        run('أ- واحد'),
        run('ب- اثنان'),
        run('ج- ثلاثة'),
        run('د- أربعة'),
      ]);

      final result = DocxExamParser.parse(bytes);

      expect(result.questions.length, 2);
      expect(result.questions[0].text, 'سؤال عادي خارج النص');
      expect(result.questions[1].text, 'سؤال بخصوص الفقرة');
      expect(result.passages.length, 1);
    });
  });
}
