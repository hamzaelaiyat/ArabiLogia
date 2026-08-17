import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';

class PassageSelector extends StatefulWidget {
  final List<Map<String, String>> passages;
  final String? currentPassage;
  final String? Function(String?) getPassageValue;
  final String? Function(String?) getPassageContent;
  final bool Function(String?) isSavedPassage;
  final Function(String?) onChanged;

  const PassageSelector({
    super.key,
    required this.passages,
    required this.currentPassage,
    required this.getPassageValue,
    required this.getPassageContent,
    required this.isSavedPassage,
    required this.onChanged,
  });

  @override
  State<PassageSelector> createState() => _PassageSelectorState();
}

class _PassageSelectorState extends State<PassageSelector> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentPassage ?? '');
  }

  @override
  void didUpdateWidget(covariant PassageSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentPassage != oldWidget.currentPassage &&
        widget.currentPassage != _controller.text) {
      _controller.text = widget.currentPassage ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.passages.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final passageId = widget.getPassageValue(widget.currentPassage);
    final isWithoutPassage =
        passageId == '' && (widget.currentPassage == null || widget.currentPassage!.isEmpty);
    final savedPassage = widget.isSavedPassage(passageId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: passageId,
          decoration: InputDecoration(
            hintText: 'اختر مقروء أو أكتب جديد',
            prefixIcon: const Icon(Icons.book_outlined, size: 20),
            filled: true,
            fillColor: isDark
                ? Colors.white10
                : Colors.black.withValues(alpha: 0.03),
            border: OutlineInputBorder(
              borderRadius: AppTokens.radiusMdAll,
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
          ),
          items: [
            const DropdownMenuItem(value: '', child: Text('-- بدون مقروء --')),
            ...widget.passages.map(
              (p) => DropdownMenuItem(
                value: p['id'],
                child: Text(
                  p['title'] ?? 'بدون عنوان',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const DropdownMenuItem(
              value: '__custom__',
              child: Text('+ كتابة مقروء جديد'),
            ),
          ],
          onChanged: (val) {
            if (val == null || val.isEmpty) {
              widget.onChanged(null);
            } else if (val == '__custom__') {
              widget.onChanged('');
            } else {
              widget.onChanged(widget.getPassageContent(val));
            }
          },
        ),
        if (!isWithoutPassage) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: _controller,
            maxLines: 4,
            readOnly: savedPassage,
            style: savedPassage
                ? TextStyle(
                    color: isDark ? Colors.blue.shade200 : Colors.blue.shade700,
                  )
                : null,
            decoration: InputDecoration(
              hintText: savedPassage
                  ? 'هذا المقروء مرتبط من المقروءات (readonly)'
                  : 'أدخل نص الفقرة أو المقتطف...',
              prefixIcon: const Icon(Icons.article_outlined),
              filled: true,
              fillColor: savedPassage
                  ? (isDark
                        ? Colors.blue.withValues(alpha: 0.1)
                        : Colors.blue.withValues(alpha: 0.05))
                  : (isDark
                        ? Colors.white10
                        : Colors.black.withValues(alpha: 0.03)),
              border: OutlineInputBorder(
                borderRadius: AppTokens.radiusMdAll,
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
            ),
            onChanged: savedPassage
                ? null
                : (v) {
                    if (v.isEmpty) {
                      widget.onChanged(null);
                    } else {
                      widget.onChanged(v);
                    }
                  },
          ),
        ],
      ],
    );
  }
}
