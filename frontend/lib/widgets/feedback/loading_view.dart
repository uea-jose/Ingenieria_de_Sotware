import 'package:flutter/material.dart';

import '../../app/app_design_tokens.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: TopNavigationSkeleton()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 34, 24, 18),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1280),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      _SkeletonBox(width: 260, height: 32),
                      SizedBox(height: 12),
                      _SkeletonBox(width: 520, height: 18),
                      SizedBox(height: 28),
                      _SkeletonBox(width: double.infinity, height: 84),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 48),
            sliver: SliverLayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.crossAxisExtent;
                final columns = width >= 1180
                    ? 4
                    : width >= 860
                    ? 3
                    : width >= 560
                    ? 2
                    : 1;
                return SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => const _SkeletonProductCard(),
                    childCount: columns * 2,
                  ),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: 18,
                    crossAxisSpacing: 18,
                    mainAxisExtent: 430,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class TopNavigationSkeleton extends StatelessWidget {
  const TopNavigationSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Row(
                children: [
                  _SkeletonBox(width: 52, height: 52, radius: 16),
                  SizedBox(width: 14),
                  _SkeletonBox(width: 180, height: 26),
                  Spacer(),
                  _SkeletonBox(width: 360, height: 38, radius: 999),
                ],
              ),
              SizedBox(height: 18),
              _SkeletonBox(width: double.infinity, height: 54, radius: 999),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkeletonProductCard extends StatelessWidget {
  const _SkeletonProductCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _SkeletonBox(width: double.infinity, height: 210, radius: 0),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonBox(width: 90, height: 14),
                SizedBox(height: 12),
                _SkeletonBox(width: 210, height: 24),
                SizedBox(height: 10),
                _SkeletonBox(width: 130, height: 14),
                SizedBox(height: 72),
                _SkeletonBox(width: 120, height: 28),
                SizedBox(height: 16),
                _SkeletonBox(width: double.infinity, height: 44, radius: 999),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    required this.width,
    required this.height,
    this.radius = 10,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.bgLavender,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
