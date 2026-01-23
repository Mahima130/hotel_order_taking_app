import 'package:flutter/material.dart';
import 'package:hotel_order_taking_app/Utils/Constants.dart';

class BackgroundContainer extends StatelessWidget {
  final Widget child;

  const BackgroundContainer({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background image layer
        Positioned.fill(
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.white.withOpacity(
                  0.1), // ← Adjust this to lighten (0.5 = lighter, 0.9 = much lighter)
              BlendMode.lighten, // This lightens the image
            ),
            child: Image.asset(
              AppImages.backgroundImage,
              fit: BoxFit.cover,
            ),
          ),
        ),
        // Content on top
        child,
      ],
    );
  }
}
