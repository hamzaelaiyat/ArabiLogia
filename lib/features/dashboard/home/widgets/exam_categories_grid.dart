import 'package:flutter/material.dart';
import 'package:arabilogia/core/theme/app_tokens.dart';
import 'package:arabilogia/core/constants/routes.dart';
import 'package:arabilogia/features/dashboard/exams/models/category_metadata.dart';
import 'package:arabilogia/providers/potato_mode_provider.dart';
import 'package:arabilogia/core/widgets/animated_wrapper.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ExamCategoriesGrid extends StatelessWidget {
  const ExamCategoriesGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = CategoryMetadata.categories;
    final potato = context.watch<PotatoModeProvider>();
    final displayCategories = potato.lazyLoadingEnabled
        ? categories.take(potato.maxListItems).toList()
        : categories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedWrapper(
          addAnimation: true,
          delay: Duration.zero,
          child: Text(
            'الامتحانات',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: AppTokens.spacing8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: AppTokens.isMobile(context) ? 2 : 3,
            crossAxisSpacing: AppTokens.spacing8,
            mainAxisSpacing: AppTokens.spacing8,
            childAspectRatio: 1.2,
          ),
          itemCount: displayCategories.length,
          itemBuilder: (context, index) {
            final category = displayCategories[index];
            return Container(
              decoration: BoxDecoration(
                color: category.color,
                borderRadius: AppTokens.radiusLgAll,
              ),
              child: InkWell(
                onTap: () => context.go(
                  AppRoutes.exams,
                  extra: {'initialTabIndex': index},
                ),
                borderRadius: AppTokens.radiusLgAll,
                child: Padding(
                  padding: const EdgeInsets.all(AppTokens.spacing8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        category.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
