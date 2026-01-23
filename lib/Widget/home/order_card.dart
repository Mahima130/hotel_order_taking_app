import 'package:flutter/material.dart';
import 'package:hotel_order_taking_app/Utils/Constants.dart';
import 'package:hotel_order_taking_app/Model/order.dart' as app_order;
import 'package:hotel_order_taking_app/Widget/order/order_type_badge.dart';

class OrderCard extends StatelessWidget {
  final app_order.Order order;
  final VoidCallback onAddToOrder;
  final VoidCallback onViewOrder;

  const OrderCard({
    Key? key,
    required this.order,
    required this.onAddToOrder,
    required this.onViewOrder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isEntOrder = order.orderType == AppStrings.ent;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            color: isEntOrder
                ? AppColors.entBgLight.withOpacity(0.95)
                : AppColors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            border: isEntOrder
                ? Border.all(color: AppColors.entColor, width: 2)
                : null,
            boxShadow: [
              BoxShadow(
                color: isEntOrder
                    ? AppColors.entColor.withOpacity(0.2)
                    : Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Order Type Badge
                OrderTypeBadge(
                  orderType: order.orderType ?? AppStrings.regular,
                ),
                SizedBox(height: AppSizes.spaceS),

                // Table Location (if available)
                if (order.location != null && order.location!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      order.location!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Table Type
                Text(
                  order.tableType,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSizes.spaceXS),

                // Table Number
                Text(
                  'Table ${order.tableNo}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSizes.spaceS),

                // View Order Button
                InkWell(
                  onTap: onViewOrder,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                      border: Border.all(
                        color: isEntOrder
                            ? AppColors.entColor
                            : AppColors.buttonBackground,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      AppStrings.viewOrder,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.buttonText,
                        fontSize: AppSizes.fontXS,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: AppSizes.spaceS),

                // Orders Count
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Orders- ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      '${order.items.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSizes.spaceXS / 2),

                // // Total Amount
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.center,
                //   children: [
                //     Text(
                //       '₹${order.totalPrice.toStringAsFixed(2)}',
                //       style: TextStyle(
                //         fontSize: 13,
                //         fontWeight: FontWeight.bold,
                //         color: isEntOrder
                //             ? AppColors.entColor
                //             : AppColors.textDark,
                //       ),
                //     ),
                //   ],
                // ),
                // SizedBox(height: AppSizes.spaceS + 4),
              ],
            ),
          ),
        ),

        // Add Button at Bottom
        Positioned(
          bottom: -12,
          left: 0,
          right: 0,
          child: Center(
            child: InkWell(
              onTap: onAddToOrder,
              child: Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: isEntOrder ? null : AppColors.buttonBackground,
                  gradient: isEntOrder
                      ? LinearGradient(
                          colors: [
                            AppColors.entColor,
                            AppColors.entColor.withOpacity(0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: isEntOrder
                          ? AppColors.entColor.withOpacity(0.5)
                          : AppColors.buttonBackground.withOpacity(0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add,
                  color: AppColors.buttonText,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
