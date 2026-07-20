import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_colors.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/widgets/animated_wrapper.dart';

class HomeWelcomeCard extends StatelessWidget {
  final String name;
  final String gradeText;
  final int rank;

  const HomeWelcomeCard({
    super.key,
    required this.name,
    required this.gradeText,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    final subTitle = rank > 0
        ? _getMotivationalMessages(rank)[DateTime.now().minute % _getMotivationalMessages(rank).length]
        : 'طريقك إلى التفوق في اللغة العربية يبدأ هنا';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTokens.spacing16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: AppTokens.radius2xlAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedWrapper(
                      addAnimation: true,
                      delay: Duration.zero,
                      child: Text(
                        'مرحباً بك، $name',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    const SizedBox(height: AppTokens.spacing4),
                    AnimatedWrapper(
                      addAnimation: true,
                      delay: const Duration(milliseconds: 80),
                      child: Text(
                        subTitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<String> _getMotivationalMessages(int rank) {
    if (rank <= 3) {
      return [
        "خارق! أنت من الصفوة",
        "بطل حقيقي! حافظ على القمة",
        "أداؤك مذهل، أنت قدوة للجميع",
      ];
    } else if (rank <= 10) {
      return [
        "أنت في المركز العاشر، حافظ على مكانك",
        "اقتربت من الثلاثة الأوائل! استمر",
        "أداء مذهل، المنافسة قوية وأنت أقوى",
        "أنت ضمن العشرة الذهبيين!",
        "مكانك في القمة محجوز، شد حيلك",
        "رائع! أنت من عمالقة هذا الأسبوع",
      ];
    } else if (rank <= 20) {
      return [
        "أنت ضمن أفضل 20، جود!",
        "باقي القليل للمنافسة في المركز العاشر",
        "رائع، استمر في الصعود",
        "خطوات واثقة نحو العشرة الأوائل",
        "أداؤك ثابت ومميز، لا تتوقف",
        "أنت تقترب من قائمة النخبة",
      ];
    } else if (rank <= 50) {
      return [
        "أداء جيد، لكن يمكنك الوصول للأفضل",
        "استعد للاختبار القادم بقوة",
        "المنافسة تشتد، كن مستعداً",
        "أنت في منطقة الأمان، انطلق للأمام",
        "لا يزال هناك الكثير لتقدمه، نحن نثق بك",
        "كل درجة ترفعك مراكز كثيرة، ركز!",
      ];
    } else {
      return [
        "بداية موفقة، استمر في التدرب",
        "كل اختبار يقربك من المتصدرين",
        "ثق في قدراتك! القادم أفضل",
        "رحلة الألف ميل تبدأ باختبار",
        "لا تستسلم، غداً ستكون من الثلاثة الأوائل",
        "التكرار يعلم الشطار، استمر في المحاولة",
      ];
    }
  }
}
