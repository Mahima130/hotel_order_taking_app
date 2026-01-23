import 'package:flutter/material.dart';
import 'package:hotel_order_taking_app/Utils/Constants.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const EmptyState({
    Key? key,
    required this.icon,
    required this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.white.withOpacity(0.7)),
          SizedBox(height: AppSizes.spaceL),
          Text(
            message,
            style: TextStyle(
              color: AppColors.white.withOpacity(0.9),
              fontSize: AppSizes.fontXL,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
