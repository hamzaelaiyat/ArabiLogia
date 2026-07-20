String escapeHtml(String text) {
  return text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');
}

String generateResultHtml({
  required String studentName,
  required String gradeText,
  required int score,
  required int accuracy,
  required int speedBonus,
  required int correctCount,
  required String examTitle,
  required int passPercentage,
}) {
  final isPassed = score >= passPercentage;
  final passText = isPassed ? '✅ تم الاجتياز' : '❌ لم يتم الاجتياز';
  return '''
<!DOCTYPE html>
<html dir="rtl" lang="ar">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>نتيجة الاختبار - عربيلوجيا</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:'Segoe UI',Tahoma,sans-serif;background:#f5f5f5;display:flex;justify-content:center;align-items:center;min-height:100vh;padding:20px;direction:rtl}
.card{background:#191B1D;border-radius:24px;padding:40px 32px;max-width:420px;width:100%;text-align:center;box-shadow:0 8px 32px rgba(0,0,0,0.3);border:1px solid rgba(255,255,255,0.08)}
.logo{width:60px;height:60px;margin:0 auto 12px;background:#EB8A00;border-radius:16px;display:flex;align-items:center;justify-content:center;font-size:28px;color:#fff;font-weight:bold;line-height:1}
.brand-text h1{color:#EB8A00;font-size:20px;font-weight:bold;margin:0}
.brand-text p{color:rgba(255,255,255,0.6);font-size:11px;margin:4px 0 0}
.achievement{color:#fff;font-size:18px;margin:20px 0 4px;font-weight:bold}
.exam-title{color:#EB8A00;font-size:22px;font-weight:bold;margin:0 0 28px;line-height:1.3}
.score-wrap{width:130px;height:130px;border-radius:50%;background:conic-gradient(#EB8A00 ${score}%,rgba(255,255,255,0.08) ${score}%);display:flex;flex-direction:column;align-items:center;justify-content:center;margin:0 auto 24px;position:relative}
.score-wrap::before{content:'';position:absolute;inset:5px;border-radius:50%;background:#191B1D}
.score-number{font-size:34px;font-weight:bold;color:#fff;position:relative;z-index:1;line-height:1}
.score-label{font-size:10px;color:rgba(255,255,255,0.7);position:relative;z-index:1;margin-top:2px}
.stats{background:rgba(255,255,255,0.04);border-radius:14px;padding:16px 20px;display:flex;justify-content:space-around;margin-bottom:24px;border:1px solid rgba(255,255,255,0.08)}
.stat{text-align:center}
.stat-value{color:#EB8A00;font-size:18px;font-weight:bold}
.stat-label{color:rgba(255,255,255,0.5);font-size:11px;margin-top:2px}
.stat-divider{width:1px;background:rgba(255,255,255,0.15);margin:0 8px}
.info{margin-bottom:8px}
.student-name{color:#fff;font-size:16px;font-weight:500}
.grade-text{color:rgba(255,255,255,0.5);font-size:12px;margin-top:2px}
.badge{display:inline-block;padding:6px 16px;border-radius:20px;font-size:13px;font-weight:600;margin-top:16px;${isPassed ? 'background:#34C75920;color:#34C759;border:1px solid #34C75940' : 'background:#FF3B3020;color:#FF3B30;border:1px solid #FF3B3040'}}
.footer{color:rgba(255,255,255,0.25);font-size:10px;margin-top:24px}
</style>
</head>
<body>
<div class="card">
<div class="logo">ع</div>
<div class="brand-text"><h1>عربيلوجيا</h1><p>مجموعة وليد قطب</p></div>
<div class="achievement">لقد أتممت الاختبار بنجاح!</div>
<div class="exam-title">${escapeHtml(examTitle)}</div>
<div class="score-wrap"><div class="score-number">${score}%</div><div class="score-label">الدرجة النهائية</div></div>
<div class="stats">
<div class="stat"><div class="stat-value">${accuracy}%</div><div class="stat-label">الدقة</div></div>
<div class="stat-divider"></div>
<div class="stat"><div class="stat-value">+${speedBonus}</div><div class="stat-label">النقاط</div></div>
<div class="stat-divider"></div>
<div class="stat"><div class="stat-value">${correctCount}</div><div class="stat-label">الإجابات الصحيحة</div></div>
</div>
<div class="info"><div class="student-name">${escapeHtml(studentName)}</div><div class="grade-text">$gradeText</div></div>
<div class="badge">$passText</div>
<div class="footer">عربيلوجيا — مجموع وليد قطب</div>
</div>
</body>
</html>''';
}
