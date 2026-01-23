import 'package:flutter/material.dart';
import 'package:hotel_order_taking_app/Utils/Constants.dart';

class CustomDropdownField extends StatelessWidget {
  final String hint;
  final String? value;
  final IconData icon;
  final VoidCallback onTap;
  final bool isLoading;
  final Color? backgroundColor;

  const CustomDropdownField({
    Key? key,
    required this.hint,
    required this.icon,
    required this.onTap,
    this.value,
    this.isLoading = false,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        height: AppSizes.buttonHeight,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          // USE the backgroundColor parameter, default to white
          color: backgroundColor ?? AppColors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          border: Border.all(
            color: value != null
                ? AppColors.buttonBackground
                : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            isLoading
                ? SizedBox(
                    width: AppSizes.iconS,
                    height: AppSizes.iconS,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryGold,
                    ),
                  )
                : Icon(icon,
                    size: AppSizes.iconS, color: AppColors.primaryGold),
            SizedBox(width: AppSizes.spaceS),
            Expanded(
              child: Text(
                value ?? hint,
                style: TextStyle(
                  fontSize: AppSizes.fontM,
                  color: value != null ? AppColors.textDark : Colors.grey[600],
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down,
                size: 20, color: AppColors.textDark),
          ],
        ),
      ),
    );
  }
}
