import 'dart:io';
import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/services/device_info_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;

class ReportProblemBottomSheet extends StatefulWidget {
  const ReportProblemBottomSheet({super.key});

  static void show(BuildContext context) {
    final isMobile = AppTokens.isMobile(context);

    if (isMobile) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Theme.of(context).bottomSheetTheme.modalBackgroundColor,
        barrierColor: Colors.black.withValues(alpha: 0.5),
        isScrollControlled: true,
        enableDrag: true,
        useRootNavigator: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        builder: (context) => const ReportProblemBottomSheet(),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          child: const ReportProblemBottomSheet(),
        ),
      );
    }
  }

  @override
  State<ReportProblemBottomSheet> createState() =>
      _ReportProblemBottomSheetState();
}

class _ReportProblemBottomSheetState extends State<ReportProblemBottomSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _stepsController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _phoneController = TextEditingController();
  final _picker = ImagePicker();
  final List<XFile> _attachments = [];
  bool _isSubmitting = false;
  bool _submitted = false;
  String? _error;

  Future<void> _pickAttachment() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 80,
    );
    if (image != null && _attachments.length < 5) {
      setState(() {
        _attachments.add(image);
      });
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  Future<List<String>> _uploadAttachments() async {
    if (_attachments.isEmpty) return [];

    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    final uploadedUrls = <String>[];

    for (final attachment in _attachments) {
      try {
        final file = File(attachment.path);
        final extension = p.extension(attachment.path);
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final userId = user?.id ?? 'anonymous';
        final fileName = 'report_${userId}_$timestamp$extension';

        await supabase.storage.from('reports').upload(fileName, file);
        final publicUrl =
            supabase.storage.from('reports').getPublicUrl(fileName);
        uploadedUrls.add(publicUrl);
      } catch (e) {
        debugPrint('Failed to upload attachment: $e');
      }
    }

    return uploadedUrls;
  }

  Future<void> _submitReport() async {
    if (_titleController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty ||
        _whatsappController.text.trim().isEmpty) {
      setState(() {
        _error = 'الرجاء إدخال عنوان المشكلة ووصفها ورقم الواتساب';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      final deviceInfo = await DeviceInfoService.getDeviceInfoString();
      final appVersion = await DeviceInfoService.getAppVersion();
      final attachmentUrls = await _uploadAttachments();

      final reportData = {
        if (user != null) 'user_id': user.id,
        'title': _titleController.text.trim(),
        'issue': _descriptionController.text.trim(),
        'steps_to_reproduce': _stepsController.text.trim().isNotEmpty
            ? _stepsController.text.trim()
            : null,
        'whatsapp': _whatsappController.text.trim(),
        'phone': _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        'device_info': deviceInfo,
        'app_version': appVersion,
        'platform': Platform.operatingSystem,
        'attachment_urls': attachmentUrls,
        'status': 'new',
      };

      await supabase.from('reports').insert(reportData);

      if (mounted) {
        setState(() {
          _submitted = true;
          _isSubmitting = false;
        });
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'فشل إرسال التقرير: $e';
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _stepsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final maxHeight = MediaQuery.of(context).size.height * 0.92;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Container(
            padding: EdgeInsets.fromLTRB(
              AppTokens.spacing24,
              0,
              AppTokens.spacing24,
              AppTokens.spacing32,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: _submitted ? _buildSuccessView() : _buildFormView(),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDragHandle(),
        const SizedBox(height: AppTokens.spacing24),
        const Icon(
          Icons.check_circle,
          size: 80,
          color: AppColors.success,
        ),
        const SizedBox(height: AppTokens.spacing24),
        Text(
          'تم إرسال التقرير بنجاح',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTokens.spacing8),
        Text(
          'شكراً لمساعدتنا في تحسين التطبيق، سنتعامل مع المشكلة في أقرب وقت.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.mutedColor(context),
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTokens.spacing24),
      ],
    );
  }

  Widget _buildFormView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDragHandle(),
        Text(
          'الإبلاغ عن مشكلة',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFFEB8A00),
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTokens.spacing8),
        Text(
          'سيتم جمع معلومات الجهاز والتطبيق تلقائياً لمساعدتنا في تشخيص المشكلة.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.mutedColor(context),
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTokens.spacing24),
        Flexible(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(
                  controller: _titleController,
                  label: 'عنوان المشكلة',
                  hint: 'مثال: مشكلة في تسجيل الدخول',
                  maxLines: 1,
                ),
                const SizedBox(height: AppTokens.spacing20),
                _buildTextField(
                  controller: _descriptionController,
                  label: 'وصف المشكلة',
                  hint: 'صف ما حصل بالتفصيل...',
                  maxLines: 3,
                ),
                const SizedBox(height: AppTokens.spacing20),
                _buildTextField(
                  controller: _whatsappController,
                  label: 'رقم الواتساب *',
                  hint: 'أدخل رقم الواتساب',
                  maxLines: 1,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: AppTokens.spacing20),
                _buildTextField(
                  controller: _phoneController,
                  label: 'رقم الهاتف',
                  hint: 'أدخل رقم الهاتف',
                  maxLines: 1,
                  keyboardType: TextInputType.phone,
                  optional: true,
                ),
                const SizedBox(height: AppTokens.spacing20),
                _buildTextField(
                  controller: _stepsController,
                  label: 'كيفية إعادة إنتاج المشكلة',
                  hint: '1. افتح الإعدادات\n2. اضغط على زر X\n3. يظهر الخطأ...',
                  maxLines: 3,
                  optional: true,
                ),
                const SizedBox(height: AppTokens.spacing20),
                _buildAttachmentsSection(),
                if (_error != null) ...[
                  const SizedBox(height: AppTokens.spacing16),
                  Text(
                    _error!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: AppTokens.fontSizeSm,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: AppTokens.spacing16),
        SizedBox(
          width: double.infinity,
          height: AppTokens.buttonHeightMd,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitReport,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEB8A00),
              disabledBackgroundColor: Colors.grey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTokens.radiusFull),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'إرسال التقرير',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        SizedBox(height: MediaQuery.of(context).padding.bottom),
      ],
    );
  }

  Widget _buildDragHandle() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: isDark ? Colors.white30 : Colors.black26,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required int maxLines,
    bool optional = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: AppTokens.fontSizeMd,
              ),
            ),
            if (optional) ...[
              const SizedBox(width: 4),
              Text(
                '(اختياري)',
                style: TextStyle(
                  fontSize: AppTokens.fontSizeXs,
                  color: AppColors.mutedColor(context),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          minLines: 1,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: AppColors.mutedColor(context),
            ),
            filled: true,
            fillColor: isDark
                ? Colors.white10
                : Colors.black.withValues(alpha: 0.03),
            border: OutlineInputBorder(
              borderRadius: AppTokens.radiusMdAll,
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttachmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'مرفقات (لقطات شاشة أو فيديو)',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: AppTokens.fontSizeMd,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '(${_attachments.length}/5)',
              style: TextStyle(
                fontSize: AppTokens.fontSizeXs,
                color: AppColors.mutedColor(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ..._attachments.asMap().entries.map((entry) {
              final index = entry.key;
              final file = entry.value;
              return Stack(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: AppTokens.radiusMdAll,
                      color: Colors.black12,
                    ),
                    child: ClipRRect(
                      borderRadius: AppTokens.radiusMdAll,
                      child: Image.file(
                        File(file.path),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.image,
                          size: 32,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    left: 4,
                    child: GestureDetector(
                      onTap: () => _removeAttachment(index),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
            if (_attachments.length < 5)
              GestureDetector(
                onTap: _pickAttachment,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: AppTokens.radiusMdAll,
                    border: Border.all(
                      color: AppColors.mutedColor(context),
                    ),
                  ),
                  child: const Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 32,
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
