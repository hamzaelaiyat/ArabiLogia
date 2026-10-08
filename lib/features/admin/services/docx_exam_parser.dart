import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

class DocxExamParser {
  static final _numberPattern = RegExp(r'^[٠-٩0-9]+[\-\.\:]?\s*');
  static final _parenNumberPattern = RegExp(r'^\([٠-٩0-9]+\)\s*');
  static final _bracePattern = RegExp(r'^\{([^}]*)\}\s*:?\s*(.*)$');

  /// Numbered questions that belong to a reading passage. The author prefixes
  /// the number with p / ف / فـ (e.g. "p1-", "ف1.", "فـ1)") to set them apart
  /// from normal numbered questions (1- ، 2- ...). The prefix is stripped from
  /// the question text when parsed.
  static final _passageNumberPattern = RegExp(
    r'^(?:p|ف|فـ)\s*[٠-٩0-9]+\s*[\-\.\:\–\—\)]?\s*',
  );

  static DocxParseResult parse(Uint8List bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);

    final documentFile = archive.firstWhere(
      (file) => file.name == 'word/document.xml',
      orElse: () =>
          throw Exception('Invalid .docx file: word/document.xml not found'),
    );

    final xmlContent = utf8.decode(documentFile.content as List<int>);
    final document = XmlDocument.parse(xmlContent);

    final paragraphs = _extractParagraphs(document);
    final unnumberedStems = _detectUnnumberedStems(paragraphs);
    return _parseParagraphs(paragraphs, unnumberedStems: unnumberedStems);
  }

  static List<String> _extractParagraphs(XmlDocument document) {
    final paragraphs = <String>[];
    final body = document.findAllElements('w:body');

    if (body.isEmpty) return paragraphs;

    for (final p in body.first.findAllElements('w:p')) {
      final text = _extractParagraphText(p);
      paragraphs.add(text);
    }

    return paragraphs;
  }

  static String _extractParagraphText(XmlElement p) {
    final buffer = StringBuffer();
    _extractTextRecursive(p, buffer);
    return buffer.toString().trim();
  }

  static void _extractTextRecursive(XmlElement element, StringBuffer buffer) {
    for (final child in element.children) {
      if (child is XmlElement) {
        final localName = child.name.local;
        if (localName == 't') {
          buffer.write(child.innerText);
        } else if (localName == 'r' ||
            localName == 'fldSimple' ||
            localName == 'hyperlink') {
          _extractTextRecursive(child, buffer);
        }
      }
    }
  }

  static DocxParseResult _parseParagraphs(
    List<String> paragraphs, {
    Set<int> unnumberedStems = const {},
  }) {
    final passages = <ParsedPassage>[];
    final questions = <ParsedQuestion>[];

    String? pendingText;
    List<String> currentOptions = [];
    bool pendingIsQuestionPending = false;
    bool pendingIsQuotedPassage = false;

    // True while reading the body of a """ ... """ triple-quoted passage that
    // spans multiple paragraphs. Additional lines accumulate into pendingText
    // until a line that closes with """ , after which the passage is finalized.
    bool pendingIsTripleQuoted = false;

    // Most recent plain prose line that reads like a question stem (ends with
    // ?, ؟, or :). Used to recover "short-answer"/poetry-comprehension groups
    // where the question text appears as prose and only the following lettered
    // options mark the presence of a question.
    String? lastQuestionStem;

    // Accumulated poetic/reading context (a poem's verse block + its "قال فلان:"
    // intro) that sits directly above the next question stem. It is captured
    // when a question is opened and then reset.
    String? pendingContext;

    // True once a "قال فلان:" intro arms context accumulation; only verse-like
    // lines while armed are gathered, so unrelated explanatory prose is not
    // mistakenly attached as a question's context.
    bool contextArmed = false;

    // The context captured when the current pending question's stem was opened.
    String? pendingQuestionContext;

    bool looksLikeQuestionPrompt(String line) {
      if (line.isEmpty) return false;
      return line.endsWith('?') ||
          line.endsWith('؟') ||
          line.endsWith(':') ||
          line.endsWith('؛');
    }

    void commitPendingQuestion() {
      if (pendingText != null &&
          pendingIsQuestionPending &&
          currentOptions.length >= 2) {
        questions.add(
          ParsedQuestion(
            text: pendingText!,
            options: List.from(currentOptions),
            context: pendingQuestionContext,
          ),
        );
        pendingText = null;
        currentOptions.clear();
        pendingIsQuestionPending = false;
        pendingQuestionContext = null;
      }
    }

    for (var index = 0; index < paragraphs.length; index++) {
      final paragraph = paragraphs[index];
      final trimmed = paragraph.trim();
      if (trimmed.isEmpty) {
        continue;
      }

      final split = _splitLine(trimmed);
      final lineText = split.text.trim();
      final inlineOptions = split.options;

      // The line contains options (inline or starting options line).
      final isOptionLine = inlineOptions.isNotEmpty;

      // Is this a new question line? (brace, western/arabic number, paren number,
      // or passage-numbered question pN. / فN. / فـN.)
      final braceQuestion = _extractBraceQuestion(lineText);
      final numberMatch = _numberPattern.firstMatch(lineText);
      final parenMatch = _parenNumberPattern.firstMatch(lineText);
      final passageNumberMatch = _passageNumberPattern.firstMatch(lineText);
      final looksLikeQuestion =
          braceQuestion != null ||
          numberMatch != null ||
          parenMatch != null ||
          passageNumberMatch != null;
      final isQuotedPassage =
          !_opensTripleQuote(trimmed) && _extractQuotedText(lineText) != null;
      final tripleText = _extractTripleQuotedText(trimmed);
      final isTripleOpener =
          !(tripleText != null) && _opensTripleQuote(trimmed);
      final isTripleCloser = _closesTripleQuote(trimmed);

      if (looksLikeQuestion) {
        // Commit any pending question before starting a new one.
        commitPendingQuestion();
        // Finalize any dangling quoted or triple-quoted passage.
        if (pendingText != null &&
            (pendingIsQuotedPassage || pendingIsTripleQuoted)) {
          passages.add(ParsedPassage(content: pendingText!));
        }
        // Reset options for the new question.
        currentOptions.clear();
        pendingText = null;
        pendingIsQuotedPassage = false;
        pendingIsTripleQuoted = false;
        pendingIsQuestionPending = true;
        lastQuestionStem = null;
        // Capture any poetic context that accumulates above this stem.
        pendingQuestionContext = pendingContext;
        pendingContext = null;
        contextArmed = false;

        if (braceQuestion != null) {
          pendingText = braceQuestion;
        } else {
          final qbody = parenMatch != null
              ? lineText.substring(parenMatch.end)
              : (numberMatch != null
                    ? lineText.substring(numberMatch.end)
                    : (passageNumberMatch != null
                          ? lineText.substring(passageNumberMatch.end)
                          : lineText));
          pendingText = qbody.trim().isNotEmpty ? qbody.trim() : lineText;
        }

        // The question line may itself carry inline options.
        if (isOptionLine) {
          currentOptions.addAll(inlineOptions);
        }
        continue;
      }

      // An unnumbered plain-prose line that was pre-detected as a question
      // stem (it is followed by a run of consecutive, ordered lettered
      // options). Open a pending question so those option lines attach to it.
      if (unnumberedStems.contains(index)) {
        commitPendingQuestion();
        if (pendingText != null &&
            (pendingIsQuotedPassage || pendingIsTripleQuoted)) {
          passages.add(ParsedPassage(content: pendingText!));
        }
        currentOptions.clear();
        pendingText = lineText;
        pendingIsQuotedPassage = false;
        pendingIsTripleQuoted = false;
        pendingIsQuestionPending = true;
        lastQuestionStem = null;
        pendingQuestionContext = pendingContext;
        pendingContext = null;
        contextArmed = false;
        continue;
      }

      if (isOptionLine) {
        // Attach options to the pending question if there is one.
        if (pendingText != null && pendingIsQuestionPending) {
          // Leftover leading text on an option-only line is the first option.
          if (split.text.isNotEmpty && inlineOptions.isNotEmpty) {
            currentOptions.add(_cleanOption(split.text));
          }
          currentOptions.addAll(inlineOptions);
        } else {
          // An option line with no pending question. If a recent prose line
          // reads like a question stem (e.g. a poetry-comprehension prompt),
          // treat it as the question and attach these options. Otherwise
          // discard the orphaned options.
          if (lastQuestionStem != null) {
            final stem = lastQuestionStem;
            final finalOptions = List<String>.from(inlineOptions);
            if (split.text.isNotEmpty) {
              finalOptions.insert(0, _cleanOption(split.text));
            }
            if (finalOptions.length >= 2) {
              questions.add(
                ParsedQuestion(
                  text: stem,
                  options: finalOptions,
                  context: pendingContext,
                ),
              );
            }
            pendingContext = null;
            contextArmed = false;
          }
          lastQuestionStem = null;
          currentOptions.clear();
          pendingText = null;
          pendingIsQuestionPending = false;
        }
        continue;
      }

      if (pendingIsTripleQuoted) {
        // Inside a """ ... """ passage: accumulate until it closes.
        if (isTripleCloser) {
          final bodyText = (lineText.length >= 3 && lineText.endsWith('"""'))
              ? lineText.substring(0, lineText.trimRight().length - 3).trim()
              : lineText;
          final content = (pendingText ?? '').trim();
          passages.add(
            ParsedPassage(
              content: (content.isEmpty ? '' : '$content ') + bodyText,
            ),
          );
          pendingText = null;
          pendingIsTripleQuoted = false;
          pendingIsQuestionPending = false;
        } else {
          pendingText = (pendingText == null)
              ? lineText
              : '$pendingText $lineText';
        }
        continue;
      }

      if (isQuotedPassage) {
        // Commit any pending question.
        commitPendingQuestion();
        // Commit any prior quoted passage accumulation before starting a new one.
        if (pendingText != null && pendingIsQuotedPassage) {
          passages.add(ParsedPassage(content: pendingText!));
        }
        pendingText = _extractQuotedText(lineText);
        pendingIsQuotedPassage = true;
        pendingIsQuestionPending = false;
        continue;
      }

      if (tripleText != null) {
        // A complete """ ... """ passage on a single line.
        commitPendingQuestion();
        if (pendingText != null && pendingIsQuotedPassage) {
          passages.add(ParsedPassage(content: pendingText!));
        }
        passages.add(ParsedPassage(content: tripleText));
        pendingText = null;
        pendingIsQuotedPassage = false;
        pendingIsTripleQuoted = false;
        pendingIsQuestionPending = false;
        lastQuestionStem = null;
        continue;
      }

      if (isTripleOpener) {
        // Begin a multi-paragraph """ ... """ passage (closes on a later line).
        commitPendingQuestion();
        if (pendingText != null && pendingIsQuotedPassage) {
          passages.add(ParsedPassage(content: pendingText!));
        }
        pendingText = lineText.substring(3).trim();
        pendingIsQuotedPassage = false;
        pendingIsTripleQuoted = true;
        pendingIsQuestionPending = false;
        lastQuestionStem = null;
        continue;
      }

      // Continuation text of the pending question.
      if (pendingText != null &&
          pendingIsQuestionPending &&
          currentOptions.isNotEmpty) {
        // Already have options; a plain line after options closes the question.
        commitPendingQuestion();
        // If the following line reads like a question stem (e.g. a poetry
        // prompt that a prior question had absorbed), remember it so a later
        // lettered option line can be attached to it.
        if (_isPoetIntro(lineText)) {
          // A new poem's "قال فلان:" intro arms verse-context accumulation for
          // the next question's block.
          lastQuestionStem = lineText;
          pendingContext = lineText;
          contextArmed = true;
        } else if (looksLikeQuestionPrompt(lineText)) {
          lastQuestionStem = lineText;
          pendingContext = null;
          contextArmed = false;
        } else {
          // Unrelated plain prose after options breaks any armed verse block.
          pendingContext = null;
          contextArmed = false;
        }
        pendingText = null;
        pendingIsQuestionPending = false;
        continue;
      }

      if (pendingText != null &&
          pendingIsQuestionPending &&
          lineText.isNotEmpty) {
        pendingText = '$pendingText $lineText';
        continue;
      }

      // Otherwise it's plain prose. Only accumulate it if we're already
      // building a quoted passage; unquoted header/prose is not a passage.
      if (pendingText != null &&
          pendingIsQuotedPassage &&
          lineText.isNotEmpty) {
        pendingText = '$pendingText $lineText';
      } else {
        if (_isPoetIntro(lineText)) {
          // A poet intro (e.g. "قال الحضرمي:") begins a fresh verse block and
          // also registers as a short question prompt (it ends with ":").
          pendingContext = lineText;
          contextArmed = true;
          if (looksLikeQuestionPrompt(lineText)) {
            lastQuestionStem = lineText;
          }
        } else if (contextArmed && _isVerseContextLine(lineText)) {
          // A verse line (carries Arabic diacritics) right under a poem intro.
          // Accumulate it, even if it ends with rhetorical punctuation (e.g.
          // "بِرَبِّكُمُ اغْتِرَابِي بَيْنَ أَهْلِي؟").
          pendingContext = (pendingContext == null)
              ? lineText
              : '$pendingContext $lineText';
        } else if (looksLikeQuestionPrompt(lineText)) {
          lastQuestionStem = lineText;
          // A non-verse question prompt is a boundary: it neither belongs to
          // the running verse block nor extends it, so clear accumulation.
          pendingContext = null;
          contextArmed = false;
        } else {
          // Unrelated plain prose breaks any armed verse block.
          pendingContext = null;
          contextArmed = false;
        }
        pendingText = null;
        pendingIsQuotedPassage = false;
      }
    }

    if (pendingText != null &&
        (pendingIsQuotedPassage || pendingIsTripleQuoted)) {
      passages.add(ParsedPassage(content: pendingText!));
    } else if (pendingText != null && pendingIsQuestionPending) {
      commitPendingQuestion();
    }

    return DocxParseResult(passages: passages, questions: questions);
  }

  /// Detect unnumbered plain-prose question stems: a line that reads like a
  /// question is immediately followed by a run of 2+ consecutive (no blank
  /// between) lettered option lines in natural أ/ب/ج/د order. This recovers
  /// poetry/short-answer comprehension groups whose options carry no number
  /// on the stem (e.g. "ما نوع الكناية...؟" followed by أ/ب/ج/د choices).
  static Set<int> _detectUnnumberedStems(List<String> paragraphs) {
    const ordered = ['أ', 'ب', 'ج', 'د', 'ه', 'و'];
    final stems = <int>{};

    for (var i = 0; i < paragraphs.length; i++) {
      final stem = paragraphs[i].trim();
      if (stem.isEmpty || !_looksLikeQuestionStem(stem)) continue;

      // Collect the run of consecutive lettered option lines following the
      // stem (blank lines between the stem and the first option are allowed).
      final optionLines = <int>[];
      var j = i + 1;
      while (j < paragraphs.length) {
        final trimmed = paragraphs[j].trim();
        if (trimmed.isEmpty) {
          // Blank lines may separate a poem-comparison option row (each verse
          // option sits in its own paragraph with empty paragraphs around it),
          // so blanks don't terminate the candidate option run.
          j++;
          continue;
        }
        final split = _splitLine(trimmed);
        if (split.options.isEmpty) break;
        optionLines.add(_leadingLetter(trimmed));
        j++;
      }

      if (optionLines.length < 2) continue;

      // Option lines must form a consecutive sub-run of أ/ب/ج/د… in order.
      final startIdx = optionLines[0];
      if (startIdx < 0 || startIdx + optionLines.length > ordered.length)
        continue;
      var consecutive = true;
      for (var k = 0; k < optionLines.length; k++) {
        if (optionLines[k] != startIdx + k) {
          consecutive = false;
          break;
        }
      }
      if (consecutive) stems.add(i);
    }
    return stems;
  }

  /// Returns the index in [أ,ب,ج,د,…] of the option letter that prefixes a
  /// standalone option line (e.g. "أ- …" -> 0, "ب) …" -> 1), or -1 if none.
  static int _leadingLetter(String trimmed) {
    const ordered = ['أ', 'ب', 'ج', 'د', 'ه', 'و'];
    final m = RegExp(
      r'^\s*([أبجدهـ])\s*[\u200c\u200f]*\s*[\)\-\.\u2013\u2014]',
    ).firstMatch(trimmed);
    if (m == null) return -1;
    return ordered.indexOf(m.group(1)!);
  }

  static bool _looksLikeQuestionStem(String line) {
    if (line.isEmpty) return false;
    // A line that begins with a lettered option marker (أ/ب/ج/د…) is an
    // option, not a question stem — even if it ends with a "؟" (e.g. a poem
    // hemistich that is itself one of the أ/ب/ج/د verse choices).
    if (_leadingLetter(line) >= 0) return false;
    if (line.length > 130) return false;
    if (line.endsWith('?') || line.endsWith('؟') || line.endsWith(':')) {
      return true;
    }
    if (line.contains('.........') || line.contains('........')) return true;
    const keywords = ['حدد', 'بين', 'بيّن', 'اذكر', 'ماذا', 'كيف', 'أين'];
    for (final k in keywords) {
      if (line.contains(k)) return true;
    }
    return false;
  }

  /// True for a short Arabic source/intro line that announces a poem's author,
  /// e.g. "قال الحضرمي:", "يقول خليل مطران:", "قال الشاعر:". This marks the
  /// start of a fresh verse-context block that the following question uses.
  static bool _isPoetIntro(String line) {
    final t = line.trim();
    if (t.length > 40 || !t.contains(':')) return false;
    return RegExp(
      r'^\s*[«(.“"]?\s*(قال|يقول|وقال)\s+[^:]{1,30}:\s*$',
    ).hasMatch(t);
  }

  /// True for a line that reads as part of an Arabic poem verse (carries short
  /// vowel/harakat diacritics), distinguishing it from plain instruction prose.
  static bool _isVerseContextLine(String line) {
    if (line.isEmpty) return false;
    // Arabic diacritics: fatha..sukun, shadda, tanwins, tatweel.
    return RegExp(r'[\u064B-\u0652\u0640]').hasMatch(line);
  }

  /// Splits a line into its leading non-option text and any option fragments.
  /// Handles:
  ///   - a single standalone option: "أ- القاهرة"            -> text:"", options:[القاهرة]
  ///   - multiple inline options: "أ- صفة ب- موصوف ج- نسبة"  -> text:"", options:[صفة,موصوف,نسبة]
  ///   - question + inline options: "س1؟ أ- أ ب- ب"          -> text:"س1؟", options:[أ,ب]
  static ({String text, List<String> options}) _splitLine(String line) {
    final markers = <({int index, int afterEnd})>[];
    // Option markers: أ/ب/ج/د/a/b/c/d optionally followed by RTL joiner chars
    // and a separator ), -, – (en-dash), — (em-dash), or . (e.g. "أ-", "ب)",
    // "ج–", "د.", "أ - "). Word processors commonly autocorrect the hyphen to
    // an en/em dash, so we treat all of them as equivalent separators.
    //
    // The label letter must sit at a word boundary (not immediately after
    // another Latin/Arabic letter) so that an ordinary word ending in ب/د
    // followed by a dash (e.g. "معرب - مبنى") is NOT mistaken for a new option
    // marker, while a true side-by-side option like "ب – آلله" still is.
    final optionMarker = RegExp(
      r'(?<![a-zA-Z\u0600-\u06FF])[أبجدabcd][\u200c\u200f]*\s*[\)\-\.\u2013\u2014]',
    );
    for (final match in optionMarker.allMatches(line)) {
      markers.add((index: match.start, afterEnd: match.end));
    }
    if (markers.isEmpty) return (text: line, options: const []);

    // A single marker counts as an option only if it's at the very start of
    // the line (a standalone option paragraph), to avoid false positives
    // inside ordinary prose.
    if (markers.length == 1) {
      if (markers.first.index == 0) {
        final opt = line.substring(markers.first.afterEnd).trim();
        return (
          text: '',
          options: opt.isEmpty ? const [] : [_cleanOption(opt)],
        );
      }
      return (text: line, options: const []);
    }

    markers.sort((a, b) => a.index.compareTo(b.index));

    // Leading text is everything before the first marker.
    final text = line.substring(0, markers.first.index).trim();

    final options = <String>[];
    for (var i = 0; i < markers.length; i++) {
      final start = markers[i].afterEnd;
      final end = i + 1 < markers.length ? markers[i + 1].index : line.length;
      final opt = line.substring(start, end).trim();
      if (opt.isEmpty) continue;
      options.add(_cleanOption(opt));
    }

    return (text: text, options: options);
  }

  /// Strips stray separators/joiner chars and whitespace from an option.
  static String _cleanOption(String text) {
    return text
        .replaceAll(RegExp(r'^[\u200c\u200f\s\.\-–—\)>]+'), '')
        .replaceAll(RegExp(r'[\u200c\u200f\s]+$'), '')
        .trim();
  }

  static String? _extractBraceQuestion(String text) {
    final match = _bracePattern.firstMatch(text);
    if (match != null) {
      final inner = match.group(1)?.trim() ?? '';
      final trailing = match.group(2)?.trim() ?? '';
      if (inner.isEmpty) return null;
      return trailing.isNotEmpty ? '$inner  $trailing' : inner;
    }
    return null;
  }

  static String? _extractQuotedText(String text) {
    if (text.length >= 2) {
      if ((text.startsWith('\u201C') && text.endsWith('\u201D')) ||
          (text.startsWith('\u2018') && text.endsWith('\u2019'))) {
        return text.substring(1, text.length - 1).trim();
      }
      if (text.startsWith('"') && text.endsWith('"')) {
        return text.substring(1, text.length - 1).trim();
      }
      if (text.startsWith('«') && text.endsWith('»')) {
        return text.substring(1, text.length - 1).trim();
      }
    }
    return null;
  }

  /// True when the line opens a """ ... """ (triple-quoted) reading passage —
  /// it starts with three ASCII double-quotes.
  static bool _opensTripleQuote(String text) {
    return text.startsWith('"""');
  }

  /// True when the line closes a """ ... """ reading passage — it ends with
  /// three ASCII double-quotes.
  static bool _closesTripleQuote(String text) {
    return text.trimRight().endsWith('"""');
  }

  /// Extracts the whole-text inner content of a """ ... """ passage that opens
  /// and closes on the SAME line (e.g. `""" النص الكامل """`). Returns null
  /// when the line does not form a complete single-line triple-quoted passage.
  static String? _extractTripleQuotedText(String text) {
    if (!_opensTripleQuote(text) || !_closesTripleQuote(text)) return null;
    final inner = text.substring(3, text.trimRight().length - 3).trim();
    return inner.isEmpty ? null : inner;
  }
}

class DocxParseResult {
  final List<ParsedPassage> passages;
  final List<ParsedQuestion> questions;

  const DocxParseResult({required this.passages, required this.questions});

  bool get isEmpty => passages.isEmpty && questions.isEmpty;

  int get totalItems => passages.length + questions.length;
}

class ParsedPassage {
  final String content;

  const ParsedPassage({required this.content});
}

class ParsedQuestion {
  final String text;
  final List<String> options;

  /// Optional poetic/reading context (a poem's verse block) that the question
  /// refers to, when present in the source document (e.g. a "قال فلان:" intro
  /// followed by the بيت(s) above the question stem).
  final String? context;

  const ParsedQuestion({
    required this.text,
    required this.options,
    this.context,
  });
}
