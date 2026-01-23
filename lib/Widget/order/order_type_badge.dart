import 'package:flutter/material.dart';
import 'package:hotel_order_taking_app/Utils/Constants.dart';

class OrderTypeBadge extends StatelessWidget {
  final String orderType;

  const OrderTypeBadge({Key? key, required this.orderType}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isENT = orderType.toUpperCase() == 'ENT';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: isENT ? AppColors.entColor : AppColors.primaryDark,
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
      ),
      child: Text(
        orderType,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: AppSizes.fontXS,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
