## عربيلوجيا 26.2.25 [BETA]

### 🆕 ما الجديد الذي ستلاحظه

**1. صفحة هبوط ويب جديدة كلياً** 🌐
- تم إعادة تصميم صفحة الموقع بالكامل (index.html) بلغة HTML/CSS/JS نقية لتعمل قبل تحميل التطبيق
- تصميم جذاب مع وضع داكن/فاتح، صور الخريجين، وقسم تحميل مباشر
- تم حذف صفحة الهبوط القديمة (Flutter Landing) للاستغناء عن تحميل Flutter أولاً — سرعة تحميل فورية

**2. حقل "نبذة عني" في الملف الشخصي** ✏️
- يمكنك الآن كتابة نبذة قصيرة عن نفسك (حتى 200 حرف)
- تظهر النبذة في صفحة ملفك الشخصي وفي نافذة عرض اللاعبين

**3. عرض ملف اللاعبين في لوحة المتصدرين** 👤
- اضغط على أي لاعب في لوحة التصنيف لتظهر نافذة منبثقة تعرض صورته، إحصائياته (الامتحانات، النقاط، الترتيب)، ونبذته الشخصية
- ملف جديد: `leaderboard_user_profile_sheet.dart`

**4. صور رمزية أكثر ذكاءً** 🖼️
- إذا فشل تحميل صورة المستخدم، يظهر الحرف الأول من اسمه بلون مميز بدلاً من فراغ

**5. تأكيد عند تبديل الحسابات** 🔄
- قبل تسجيل الخروج لإضافة حساب جديد، يظهر حوار تأكيد: "سيتم تسجيل الخروج من الحساب الحالي للسماح لك بتسجيل الدخول بحساب آخر."

**6. اختبارات أمان متطورة** 🛡️
- تم تطوير `loadtest.js` ليشمل اختبارات أمان متعددة: تسجيل جماعي، تخمين كلمات المرور، إرسال نتائج مزيفة، سرقة بيانات (IDOR)
- شغّل عبر `k6 run -e TEST_MODE=all loadtest.js`

### 🔧 تحسينات داخلية
- إعادة هيكلة `AuthProvider` لتهيئة أفضل للخدمات ومعالجة الأخطاء
- تحديث `web/index.html` مع تحسينات SEO و Open Graph وميتا تاجز متقدمة
- إضافة صورة المعلم في قسم البطل (teacher.png)
- إزالة `LandingService` ونقل منطق جلب الإصدار إلى `index.html`

### 📥 التحميلات
- [أندرويد ARM64](https://github.com/hamzaelaiyat/ArabiLogia/releases/download/26.2.25/arabilogia-android-arm64-v8a-26_2_25.apk) — `arabilogia-android-arm64-v8a-26_2_25.apk`
- [أندرويد ARMv7a](https://github.com/hamzaelaiyat/ArabiLogia/releases/download/26.2.25/arabilogia-android-armeabi-v7a-26_2_25.apk) — `arabilogia-android-armeabi-v7a-26_2_25.apk`
- [أندرويد x86_64](https://github.com/hamzaelaiyat/ArabiLogia/releases/download/26.2.25/arabilogia-android-x86_64-26_2_25.apk) — `arabilogia-android-x86_64-26_2_25.apk`
- [لينكس x64](https://github.com/hamzaelaiyat/ArabiLogia/releases/download/26.2.25/arabilogia-linux-x64-26_2_25.tar.xz) — `arabilogia-linux-x64-26_2_25.tar.xz`
