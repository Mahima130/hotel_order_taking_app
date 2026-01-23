import 'package:flutter/material.dart';
import 'package:hotel_order_taking_app/Utils/Constants.dart';
import 'package:hotel_order_taking_app/Model/order.dart' as app_order;
import 'package:hotel_order_taking_app/Widget/order/order_type_badge.dart';

class OrderCardV2 extends StatelessWidget {
  final app_order.Order order;
  final VoidCallback onAddToOrder;
  final VoidCallback onViewOrder;
  final double? tableTypeFontSize;
  final double? tableNumberFontSize;
  final double? viewOrderFontSize;
  final double? orderCountFontSize;

  const OrderCardV2({
    Key? key,
    required this.order,
    required this.onAddToOrder,
    required this.onViewOrder,
    this.tableTypeFontSize,
    this.tableNumberFontSize,
    this.viewOrderFontSize,
    this.orderCountFontSize,
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
            padding: const EdgeInsets.all(6), // ✅ Consistent padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Order Type Badge - Left Aligned
                Align(
                  alignment: Alignment.center,
                  child: OrderTypeBadge(
                    orderType: order.orderType ?? AppStrings.regular,
                  ),
                ),
                const SizedBox(height: 6), // ✅ Consistent spacing

                // Table Type
                Text(
                  order.tableType,
                  style: TextStyle(
                    fontSize: tableTypeFontSize ?? 14, // ✅ Slightly smaller
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 0),

                // Table Number
                Text(
                  '${order.tableNo}',
                  style: TextStyle(
                    fontSize: tableNumberFontSize ?? 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 0),

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
                        fontSize: viewOrderFontSize ?? 13, // ✅ Slightly smaller
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // // Orders Count Container - Right Side (Half Outside)
        // Positioned(
        //   top: 8,
        //   right: -10,
        //   child: Container(
        //     padding: const EdgeInsets.symmetric(
        //         horizontal: 10, vertical: 4), // ✅ Reduced padding
        //     decoration: BoxDecoration(
        //       color: Colors.white,
        //       borderRadius: BorderRadius.circular(6),
        //       border: Border.all(color: Colors.black, width: 2),
        //       boxShadow: [
        //         BoxShadow(
        //           color: Colors.black.withOpacity(0.2),
        //           blurRadius: 6,
        //           offset: const Offset(0, 2),
        //         ),
        //       ],
        //     ),
        //     child: Text(
        //       '${order.orderCount}',
        //       style: TextStyle(
        //         fontSize: orderCountFontSize ?? 12, // ✅ Smaller font
        //         fontWeight: FontWeight.bold,
        //         color: Colors.black,
        //       ),
        //     ),
        //   ),
        // ),

        // Add Button at Bottom
        Positioned(
          bottom: -12,
          left: 0,
          right: 0,
          child: Center(
            child: InkWell(
              onTap: onAddToOrder,
              child: Container(
                width: 42, // ✅ Slightly smaller
                height: 42, // ✅ Slightly smaller
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
                  border: Border.all(
                      color: AppColors.white, width: 2), // ✅ Thinner border
                  boxShadow: [
                    BoxShadow(
                      color: isEntOrder
                          ? AppColors.entColor.withOpacity(0.5)
                          : AppColors.buttonBackground.withOpacity(0.5),
                      blurRadius: 6, // ✅ Smaller shadow
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add,
                  color: AppColors.buttonText,
                  size: 30, // ✅ Smaller icon
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
