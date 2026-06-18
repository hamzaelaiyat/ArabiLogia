String getArabicAuthError(String message) {
  if (message.contains('Invalid login credentials')) {
    return 'بيانات الدخول غير صحيحة';
  } else if (message.contains('Email not confirmed')) {
    return 'يرجى تأكيد البريد الإلكتروني';
  } else if (message.contains('User already registered')) {
    return 'البريد الإلكتروني مستخدم بالفعل';
  } else if (message.contains('Password should be at least')) {
    return 'كلمة المرور ضعيفة جداً';
  } else if (message.contains('Invalid email')) {
    return 'البريد الإلكتروني غير صالح';
  }
  return message;
}

String getArabicStorageError(Object error) {
  final msg = error.toString();
  if (msg.contains('bucket') || msg.contains('Bucket')) {
    return 'خطأ في رفع الملف: تأكد من إعدادات التخزين';
  } else if (msg.contains('permission') || msg.contains('denied') || msg.contains('unauthorized')) {
    return 'خطأ في الصلاحيات: حسابك لا يملك صلاحية كافية';
  } else if (msg.contains('size') || msg.contains('too large') || msg.contains('large')) {
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
  if (message.contains('Invalid login credentials')) {
    return const FieldError(message: 'بيانات الدخول غير صحيحة');
  } else if (message.contains('Email not confirmed')) {
    return const FieldError(field: 'email', message: 'يرجى تأكيد البريد الإلكتروني');
  } else if (message.contains('User already registered')) {
    return const FieldError(field: 'email', message: 'البريد الإلكتروني مستخدم بالفعل');
  } else if (message.contains('Password should be at least')) {
    return const FieldError(field: 'password', message: 'كلمة المرور ضعيفة جداً');
  } else if (message.contains('Invalid email')) {
    return const FieldError(field: 'email', message: 'البريد الإلكتروني غير صالح');
  }
  return FieldError(message: message);
}

String getArabicDbError(String message) {
  if (message.contains('42703')) {
    return 'خطأ في قاعدة البيانات: الحقل غير موجود';
  } else if (message.contains('42501') || message.contains('permission denied') || message.contains('policy')) {
    return 'خطأ في الصلاحيات: حسابك لا يملك صلاحية كافية';
  } else if (message.contains('42P01')) {
    return 'خطأ في قاعدة البيانات: الجدول غير موجود';
  } else if (message.contains('unique constraint') || message.contains('username')) {
    return 'اسم المستخدم هذا مستخدم بالفعل، اختر اسماً آخر';
  } else if (message.contains('duplicate key')) {
    return 'البيانات موجودة مسبقاً';
  }
  return 'حدث خطأ في تحديث البيانات';
}
