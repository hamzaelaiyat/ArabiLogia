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
