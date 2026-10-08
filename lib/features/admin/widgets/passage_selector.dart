import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/widgets/responsive_overlay.dart';

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

  Future<void> _pickPassage(BuildContext context) async {
    final isEmpty =
        widget.currentPassage == null || widget.currentPassage!.isEmpty;
    final selected = await ResponsiveOverlay.show<String>(
      context: context,
      title: 'اختر مقروء',
      mobileBuilder: (_) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: _buildSelector(context, isEmpty),
      ),
      desktopBuilder: (_) => _buildSelector(context, isEmpty),
    );

    if (!mounted || selected == null) return;
    if (selected.isEmpty || selected == '__none__') {
      widget.onChanged(null);
    } else if (selected == '__custom__') {
      widget.onChanged('');
    } else {
      widget.onChanged(widget.getPassageContent(selected));
    }
  }

  Widget _buildSelector(BuildContext context, bool isEmpty) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          ListTile(
            leading: const Icon(Icons.do_not_disturb_on_outlined),
            title: const Text('-- بدون مقروء --'),
            onTap: () => Navigator.pop(context, ''),
          ),
          for (final p in widget.passages) ...[
            ListTile(
              leading: const Icon(Icons.article_outlined),
              title: Text(
                p['title'] ?? 'بدون عنوان',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => Navigator.pop(context, p['id']),
            ),
          ],
          const Divider(),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('+ كتابة مقروء جديد'),
            onTap: () => Navigator.pop(context, '__custom__'),
          ),
          if (!isEmpty)
            ListTile(
              leading: const Icon(
                Icons.remove_circle_outline,
                color: Colors.red,
              ),
              title: const Text(
                '-- إزالة المقروء --',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () => Navigator.pop(context, '__none__'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.passages.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final passageId = widget.getPassageValue(widget.currentPassage);
    final isWithoutPassage =
        passageId == '' &&
        (widget.currentPassage == null || widget.currentPassage!.isEmpty);
    final savedPassage = widget.isSavedPassage(passageId);

    final selectedTitle = widget.passages
        .where((p) => p['id'] == passageId)
        .map((p) => p['title'] ?? '')
        .firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: AppTokens.radiusMdAll,
          onTap: () => _pickPassage(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white10
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: AppTokens.radiusMdAll,
            ),
            child: Row(
              children: [
                const Icon(Icons.book_outlined, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    selectedTitle ?? 'اختر مقروء أو أكتب جديد',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selectedTitle != null
                          ? (isDark ? Colors.white : Colors.black87)
                          : (isDark ? Colors.white38 : Colors.black38),
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
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
