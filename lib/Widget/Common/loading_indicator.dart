import 'package:flutter/material.dart';
import 'package:hotel_order_taking_app/Utils/Constants.dart';

class LoadingIndicator extends StatelessWidget {
  final String? message;

  const LoadingIndicator({Key? key, this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGold),
          ),
          if (message != null) ...[
            SizedBox(height: AppSizes.spaceL),
            Text(
              message!,
              style:
                  TextStyle(color: Colors.grey[600], fontSize: AppSizes.fontL),
            ),
          ],
        ],
      ),
    );
  }
}
