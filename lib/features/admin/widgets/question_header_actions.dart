import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/theme/app_colors.dart';

class QuestionHeaderActions extends StatelessWidget {
  final int index;
  final int currentPoints;
  final bool isDark;
  final VoidCallback onPreview;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final VoidCallback onPointsTap;

  const QuestionHeaderActions({
    super.key,
    required this.index,
    required this.currentPoints,
    required this.isDark,
    required this.onPreview,
    required this.onDuplicate,
    required this.onDelete,
    required this.onPointsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onPreview,
          icon: Icon(
            Icons.visibility_outlined,
            size: 20,
            color: isDark ? Colors.white38 : Colors.black26,
          ),
          tooltip: 'معاينة',
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: AppTokens.radiusFullAll,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'سؤال ${index + 1}',
                style: const TextStyle(
                  fontSize: AppTokens.fontSizeMd,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 1,
                height: 12,
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onPointsTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$currentPoints نقاط',
                        style: const TextStyle(
                          fontSize: AppTokens.fontSizeSm,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.edit,
                        size: 12,
                        color: AppColors.primary.withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: onDuplicate,
          icon: Icon(
            Icons.copy_rounded,
            size: 18,
            color: isDark ? Colors.white38 : Colors.black26,
          ),
          tooltip: 'نسخ',
        ),
        IconButton(
          onPressed: onDelete,
          icon: Icon(
            Icons.delete_outline_rounded,
            size: 18,
            color: isDark ? Colors.white38 : Colors.black26,
          ),
          tooltip: 'حذف',
        ),
      ],
    );
  }
}

class QuestionPointsDialogs {
  static void showSheet(BuildContext context, int currentPoints, ValueChanged<int> onSave) {
    final controller = TextEditingController(text: currentPoints.toString());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF232527) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _PointsBody(controller: controller, onSave: onSave),
          ),
        ),
      ),
    );
  }

  static void showDesktopDialog(BuildContext context, int currentPoints, ValueChanged<int> onSave) {
    final controller = TextEditingController(text: currentPoints.toString());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF232527) : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: _PointsBody(controller: controller, onSave: onSave),
        ),
      ),
    );
  }
}

class _PointsBody extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<int> onSave;

  const _PointsBody({required this.controller, required this.onSave});

  void _save(BuildContext context) {
    final parsed = double.tryParse(controller.text);
    if (parsed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال رقم صحيح')),
      );
      return;
    }
    final clampedPoints = parsed.clamp(0.5, 10.0);
    final intPoints = clampedPoints.round();
    onSave(intPoints);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.star, color: AppColors.primary, size: 24),
            const SizedBox(width: 12),
            Text(
              'تعديل النقاط',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.foreground(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'أدخل عدد النقاط للسؤال (من 0.5 إلى 10)',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.mutedColor(context),
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.center,
          autofocus: true,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          decoration: const InputDecoration(
            hintText: '0.5 - 10',
            suffixText: 'نقطة',
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
          onSubmitted: (val) => _save(context),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _quickButton(0.5)),
            const SizedBox(width: 8),
            Expanded(child: _quickButton(1)),
            const SizedBox(width: 8),
            Expanded(child: _quickButton(2)),
            const SizedBox(width: 8),
            Expanded(child: _quickButton(5)),
            const SizedBox(width: 8),
            Expanded(child: _quickButton(10)),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('إلغاء'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _save(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('حفظ'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _quickButton(double points) {
    return OutlinedButton(
      onPressed: () => controller.text = points.toString(),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 8),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        points.toStringAsFixed(points == points.toInt() ? 0 : 1),
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}
