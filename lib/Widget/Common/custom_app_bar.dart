import 'package:flutter/material.dart';
import 'package:hotel_order_taking_app/Utils/Constants.dart';

class CustomAppBar extends StatelessWidget {
  final String title;
  final VoidCallback? onMenuTap;
  final VoidCallback? onBackTap;
  final Widget? trailing;
  final bool showMenu;
  final bool showBack;
  final TextAlign titleAlignment;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.onMenuTap,
    this.onBackTap,
    this.trailing,
    this.showMenu = false,
    this.showBack = false,
    this.titleAlignment = TextAlign.right,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 4,
        left: 16,
        right: 16,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        gradient: AppGradients.darkGradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left side - Menu or Back button
          if (showMenu)
            IconButton(
              icon: const Icon(Icons.menu,
                  color: AppColors.primaryGold), // ← CHANGED
              onPressed: onMenuTap,
              iconSize: AppSizes.iconM,
            )
          else if (showBack)
            IconButton(
              icon: const Icon(Icons.arrow_back,
                  color: AppColors.primaryGold), // ← CHANGED
              onPressed: onBackTap ?? () => Navigator.pop(context),
              iconSize: AppSizes.iconM,
            )
          else if (titleAlignment == TextAlign.center)
            const SizedBox(width: 48),

          // Center - Title (takes remaining space)
          Expanded(
            child: Padding(
              padding: titleAlignment == TextAlign.right
                  ? const EdgeInsets.only(right: 16)
                  : EdgeInsets.zero,
              child: Text(
                title.toUpperCase(),
                textAlign: titleAlignment,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: AppSizes.fontXL,
                  color: AppColors.primaryGold, // ← CHANGED
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),

          // Right side - Trailing widget or empty space
          if (trailing != null)
            trailing!
          else if (titleAlignment == TextAlign.center)
            const SizedBox(width: 48),
        ],
      ),
    );
  }
}
