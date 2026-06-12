import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/theme/app_colors.dart';

class PassageAddForm extends StatefulWidget {
  final bool isDark;
  final Function(String title, String content, String imagePath) onAdd;

  const PassageAddForm({
    super.key,
    required this.isDark,
    required this.onAdd,
  });

  @override
  State<PassageAddForm> createState() => _PassageAddFormState();
}

class _PassageAddFormState extends State<PassageAddForm> {
  final titleCtrl = TextEditingController();
  final contentCtrl = TextEditingController();
  final imagePicker = ImagePicker();
  String? selectedImagePath;

  @override
  void dispose() {
    titleCtrl.dispose();
    contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fgColor = AppColors.foreground(context);
    final isDark = widget.isDark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF232527) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  'إضافة فقرة جديدة',
                  style: TextStyle(
                    fontSize: AppTokens.fontSizeXl,
                    fontWeight: FontWeight.bold,
                    color: fgColor,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: fgColor),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleCtrl,
                    style: TextStyle(color: fgColor),
                    decoration: InputDecoration(
                      labelText: 'عنوان الفقرة',
                      hintText: 'مثال: فقرة الوحدة الأولى',
                      filled: true,
                      fillColor: isDark ? const Color(0xFF111315) : const Color(0xFFF0F4F7),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.title, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final image = await imagePicker.pickImage(source: ImageSource.gallery);
                            if (image != null) {
                              setState(() => selectedImagePath = image.path);
                            }
                          },
                          icon: const Icon(Icons.image, color: AppColors.primary),
                          label: Text(
                            selectedImagePath != null ? 'تم اختيار صورة' : 'إضافة صورة',
                            style: TextStyle(
                              color: selectedImagePath != null ? AppColors.success : fgColor,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: selectedImagePath != null
                                  ? AppColors.success
                                  : AppColors.primary.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      ),
                      if (selectedImagePath != null) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => setState(() => selectedImagePath = null),
                          icon: const Icon(Icons.close, color: AppColors.error),
                        ),
                      ],
                    ],
                  ),
                  if (selectedImagePath != null) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(selectedImagePath!),
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextField(
                    controller: contentCtrl,
                    maxLines: 8,
                    style: TextStyle(color: fgColor, height: 1.6),
                    decoration: InputDecoration(
                      labelText: 'نص الفقرة (اختياري)',
                      hintText: 'أدخل النص الكامل للفقرة...',
                      alignLabelWithHint: true,
                      filled: true,
                      fillColor: isDark ? const Color(0xFF111315) : const Color(0xFFF0F4F7),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).padding.bottom + 20,
              top: 16,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF232527) : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.white10 : Colors.black12,
                ),
              ),
            ),
            child: Row(
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
                  child: FilledButton(
                    onPressed: () {
                      if (titleCtrl.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('يرجى إدخال عنوان للفقرة')),
                        );
                        return;
                      }
                      if (selectedImagePath == null && contentCtrl.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('يرجى إضافة نص أو صورة للفقرة')),
                        );
                        return;
                      }
                      widget.onAdd(titleCtrl.text, contentCtrl.text, selectedImagePath ?? '');
                      Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('إضافة'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
