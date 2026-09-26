import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:arabilogia/features/admin/services/docx_exam_parser.dart';

void main() {
  // These fixtures are real exam documents kept out of git, so this group only
  // runs on a machine that has them at the repo root.
  const fixtures = ['exam1.docx', 'example_exam.docx', 'exam2.docx'];
  final missing = fixtures.where((f) => !File(f).existsSync()).toList();

  group('DocxExamParser real .docx files', () {
    test('parses exam1.docx with hyphen/paren numbering and inline options', () {
      final bytes = File('exam1.docx').readAsBytesSync();
      final result = DocxExamParser.parse(bytes);

      expect(result.questions.length, 25);
      // The exam header (title) is not a passage and is ignored.
      expect(result.passages, isEmpty);

      // Q1 uses 1- with inline options on the following line.
      final q1 = result.questions.first;
      expect(q1.text.contains('نوع التشبيه'), isTrue);
      expect(q1.options, containsAll(['بليغ', 'تمثيلي.', 'ضمني', 'مجمل']));

      // Q4 has only 3 options in the source document.
      final q4 = result.questions[3];
      expect(q4.options.length, 3);

      // Paren-numbered questions (21)-(25) carry 3 كناية options each.
      final last = result.questions.last;
      expect(last.options, [
        'كناية عن صفة.',
        'كناية عن موصوف.',
        'كناية عن نسبة.',
      ]);
    });

    test('parses example_exam.docx (passage + multi-format questions)', () {
      final bytes = File('example_exam.docx').readAsBytesSync();
      final result = DocxExamParser.parse(bytes);

      // 2 quoted passages + 12 questions spanning every supported format.
      expect(result.passages.length, 2);
      expect(result.questions.length, 12);

      for (final q in result.questions) {
        expect(q.options.length, 4);
      }

      // The triple-quoted """ """ passage imports as a passage.
      final triplePassage = result.passages
          .firstWhere((p) => p.content.contains('استُشهد بالعلم'));
      expect(triplePassage.content, contains('في النهضة'));

      // The p1. / فـ2. passage-numbered questions import as questions.
      final passageQ1 =
          result.questions.firstWhere((q) => q.text.contains('ما موضوع الفقرة'));
      expect(passageQ1.options.length, 4);
      final passageQ2 = result.questions
          .firstWhere((q) => q.text.contains('ماذا يهدّم الجهل'));
      expect(passageQ2.options.length, 4);

      // The "أي الأبيات الآتية" poem-comparison question imports its four
      // verse options as أ/ب/ج/د options (each بيت is one choice).
      final comparePoem = result.questions
          .firstWhere((q) => q.text.contains('أي الأبيات الآتية'));
      expect(comparePoem.options.length, 4);
      expect(comparePoem.options.first, contains('أَجِدُّ'));

      // The poem questions carry their verse block as context, including the
      // "قال فلان:" intro line.
      final poemQ = result.questions
          .firstWhere((q) => q.text.contains('المضاد المرادف'));
      expect(poemQ.context, isNotNull);
      expect(poemQ.context, contains('قال السموأل:'));
      expect(poemQ.context, contains('سَلُوا قُلوبَنا'));
    });

    test(
        'parses exam2.docx with en-dash option separators and poetry prompts',
        () {
      final bytes = File('exam2.docx').readAsBytesSync();
      final result = DocxExamParser.parse(bytes);

      // 18 numbered questions + 11 اللون البياني + 16 recovered poem questions
      // (12 كناية groups, each with 4 أ/ب/ج/د options, the البارودي one, and
      // 3 "أي الأبيات الآتية" poem-comparison questions whose verse blocks now
      // carry أ/ب/ج/د markers so they import as 4-option multiple choice).
      expect(result.questions.length, 45);

      // Q1 uses en-dash separators ("ب –", "د –") mixed with hyphens; all four
      // options must be recovered cleanly instead of being merged.
      final q1 = result.questions.first;
      expect(q1.options, [
        'أالله أذن لكم.',
        'آلله أذن لكم.',
        'االله أذن لكم.',
        'األله أذن لكم.',
      ]);

      // A question whose options contain internal hyphens (e.g. "معرب - مبنى")
      // must NOT have those internal dashes mistaken for new option markers.
      final qWithInternalDash = result.questions
          .firstWhere((q) => q.text.contains('أنتن تسعين للخير'));
      expect(qWithInternalDash.options.length, 4);
      expect(
        qWithInternalDash.options,
        containsAll(['معرب - مبنى.', 'معرب  - معرب.']),
      );

      // The poetry-comprehension prompt before أ) ب) ج) options is captured.
      final poemQuestion = result.questions
          .firstWhere((q) => q.text.contains('قال البارودي'));
      expect(poemQuestion.options.length, 3);

      // The 12 كناية groups whose option lines used to lack أ/ب/ج/د markers
      // are now recovered as questions with exactly 4 options each.
      final kinnayaStems = result.questions
          .where((q) =>
              (q.text.contains('حدد') || q.text.contains('كناية')) &&
              !q.text.contains('أي الأبيات'))
          .toList();
      expect(kinnayaStems.length, 12);
      for (final q in kinnayaStems) {
        expect(q.options.length, 4);
      }

      // The 3 "أي الأبيات الآتية" poem-comparison questions: each stem keeps a
      // textual question and its 4 poem-verse choices import as أ/ب/ج/د options
      // (two hemistich paragraphs merged into one option per بيت).
      final anyAbyat = result.questions
          .where((q) => q.text.contains('أي الأبيات الآتية'))
          .toList();
      expect(anyAbyat.length, 3);
      for (final q in anyAbyat) {
        expect(q.options.length, 4);
      }
      // The "لا يحتوي على كناية عن موصوف" question's first option must be the
      // شوقي verse (أَلَيْسَ مِنَ العِزّ...) merged with its second hemistich.
      final anyAbyatMotawasif = anyAbyat
          .firstWhere((q) => q.text.contains('لا يحتوي'));
      expect(anyAbyatMotawasif.options.first,
          contains('أَلَيْسَ'));
      expect(anyAbyatMotawasif.options.first,
          contains('جَاثِيَا'));

      // The poem context (verse block + "قال فلان:" intro) is attached to the
      // question whose stem it sits above.
      final contextQ = result.questions
          .firstWhere((q) => q.text.contains('حدد موضعها'));
      expect(contextQ.context, isNotNull);
      expect(contextQ.context, contains('قَدْ كَان تُعْجِبُ بَعْضَهن بَرَاعَتي'));
      expect(contextQ.context, contains('قال الحضرمي:'));
    });
  }, skip: missing.isEmpty ? null : 'Missing local fixtures: ${missing.join(', ')}');
}
