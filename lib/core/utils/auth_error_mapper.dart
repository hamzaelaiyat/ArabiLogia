String getArabicAuthError(String message) {
  final msg = message.toLowerCase();
  if (msg.contains('captcha')) {
    return 'خطأ في التحقق الأمني، يرجى المحاولة مرة أخرى';
  } else if (msg.contains('invalid login credentials') ||
      msg.contains('invalid credentials')) {
    return 'بيانات الدخول غير صحيحة';
  } else if (msg.contains('email not confirmed')) {
    return 'يرجى تأكيد البريد الإلكتروني أولاً';
  } else if (msg.contains('already registered') ||
      msg.contains('already exists') ||
      msg.contains('already in use')) {
    return 'البريد الإلكتروني مستخدم بالفعل، يرجى تسجيل الدخول';
  } else if (msg.contains('signup is disabled') ||
      msg.contains('signups for this project are disabled') ||
      msg.contains('email signups are disabled')) {
    return 'التسجيل الجديد موقف حالياً، يرجى التواصل مع الدعم';
  } else if (msg.contains('password should be at least')) {
    return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
  } else if (msg.contains('invalid email') ||
      msg.contains('unable to validate email')) {
    return 'البريد الإلكتروني غير صالح';
  } else if (msg.contains('rate limit') || msg.contains('too many requests')) {
    return 'تم إرسال محاولات كثيرة جداً، يرجى الانتظار قليلاً والمحاولة مرة أخرى';
  } else if (msg.contains('hook') ||
      msg.contains('invalid_content_type') ||
      msg.contains('hook_payload')) {
    return 'خدمة إرسال البريد الإلكتروني بحاجة لضبط الإعدادات في Supabase Dashboard (Auth Hooks)';
  }
  return message;
}

String getArabicStorageError(Object error) {
  final msg = error.toString();
  if (msg.contains('bucket') || msg.contains('Bucket')) {
    return 'خطأ في رفع الملف: تأكد من إعدادات التخزين';
  } else if (msg.contains('permission') ||
      msg.contains('denied') ||
      msg.contains('unauthorized')) {
    return 'خطأ في الصلاحيات: حسابك لا يملك صلاحية كافية';
  } else if (msg.contains('size') ||
      msg.contains('too large') ||
      msg.contains('large')) {
    return 'حجم الملف كبير جداً (الحد الأقصى 5 ميجابايت)';
  } else if (msg.contains('timeout') || msg.contains('timed out')) {
    return 'انتهت مهلة الاتصال، حاول مرة أخرى';
  } else if (msg.contains('network') || msg.contains('Connection')) {
    return 'خطأ في الاتصال، تحقق من اتصالك بالإنترنت';
  }
  return 'حدث خطأ في رفع الملف';
}

class FieldError {
  final String? field;
  final String message;

  const FieldError({this.field, required this.message});
}

FieldError getArabicAuthFieldError(String message) {
  final msg = message.toLowerCase();
  if (msg.contains('captcha')) {
    return const FieldError(
      message: 'خطأ في التحقق الأمني، يرجى المحاولة مرة أخرى',
    );
  } else if (msg.contains('invalid login credentials') ||
      msg.contains('invalid credentials')) {
    return const FieldError(message: 'بيانات الدخول غير صحيحة');
  } else if (msg.contains('email not confirmed')) {
    return const FieldError(
      field: 'email',
      message: 'يرجى تأكيد البريد الإلكتروني',
    );
  } else if (msg.contains('already registered') ||
      msg.contains('already exists') ||
      msg.contains('already in use')) {
    return const FieldError(
      field: 'email',
      message: 'البريد الإلكتروني مستخدم بالفعل، يرجى تسجيل الدخول',
    );
  } else if (msg.contains('signup is disabled') ||
      msg.contains('signups for this project are disabled') ||
      msg.contains('email signups are disabled')) {
    return const FieldError(
      message: 'التسجيل الجديد موقف حالياً، يرجى التواصل مع الدعم',
    );
  } else if (msg.contains('password should be at least')) {
    return const FieldError(
      field: 'password',
      message: 'كلمة المرور يجب أن تكون 6 أحرف على الأقل',
    );
  } else if (msg.contains('invalid email') ||
      msg.contains('unable to validate email')) {
    return const FieldError(
      field: 'email',
      message: 'البريد الإلكتروني غير صالح',
    );
  } else if (msg.contains('rate limit') || msg.contains('too many requests')) {
    return const FieldError(
      message: 'تم إرسال محاولات كثيرة، يرجى الانتظار قليلاً',
    );
  } else if (msg.contains('hook') ||
      msg.contains('invalid_content_type') ||
      msg.contains('hook_payload')) {
    return const FieldError(
      message: 'خدمة إرسال البريد بحاجة لإعادة الضبط في Supabase Dashboard',
    );
  }
  return FieldError(message: getArabicAuthError(message));
}

String getArabicDbError(String message) {
  if (message.contains('42703')) {
    return 'خطأ في قاعدة البيانات: الحقل غير موجود';
  } else if (message.contains('42501') ||
      message.contains('permission denied') ||
      message.contains('policy')) {
    return 'خطأ في الصلاحيات: حسابك لا يملك صلاحية كافية';
  } else if (message.contains('42P01')) {
    return 'خطأ في قاعدة البيانات: الجدول غير موجود';
  } else if (message.contains('unique constraint') ||
      message.contains('username')) {
    return 'اسم المستخدم هذا مستخدم بالفعل، اختر اسماً آخر';
  } else if (message.contains('duplicate key')) {
    return 'البيانات موجودة مسبقاً';
  }
  return 'حدث خطأ في تحديث البيانات';
}
