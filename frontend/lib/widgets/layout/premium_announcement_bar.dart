import 'package:flutter/material.dart';

import '../../app/app_design_tokens.dart';

class PremiumAnnouncementBar extends StatelessWidget {
  const PremiumAnnouncementBar({super.key});

  @override
  Widget build(BuildContext context) {
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final sidePadding = AppLayout.horizontalPadding(viewportWidth);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.bgSoftPink,
            AppColors.bgLavender,
            AppColors.bgBlue,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: sidePadding, vertical: 9),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: AppLayout.contentMaxWidth(viewportWidth),
          ),
          child: Wrap(
            spacing: 18,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: const [
              _AnnouncementItem(
                icon: Icons.local_shipping_outlined,
                text: 'Entrega local coordinada',
              ),
              _AnnouncementItem(
                icon: Icons.verified_outlined,
                text: 'Compra segura',
              ),
              _AnnouncementItem(
                icon: Icons.receipt_long_outlined,
                text: 'IVA Ecuador 15%',
              ),
              _AnnouncementItem(
                icon: Icons.inventory_2_outlined,
                text: 'Stock visible en tiempo real',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnnouncementItem extends StatelessWidget {
  const _AnnouncementItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.primaryHover),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
