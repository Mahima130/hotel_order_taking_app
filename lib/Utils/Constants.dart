import 'package:flutter/material.dart';

class AppColors {
  // Primary brand colors
  static const primaryDark =
      Color(0xFF1A1A2E); // Dark Blue - Regular Order Type
  static const primaryDarkAlt = Color(0xFF1A1A2E); // Dark Blue
  static const drawerBackground =
      Color(0xFF4D0000); // Dark Red - Drawer & AppBar
  static const primaryGold = Color(0xFFE6DA77); // Light Gold - Text & Accents
  static const goldDark = Color(0xFFE6DA77); // Light Gold

  // Button colors
  static const buttonBackground =
      Color(0xFFEDD68E); // Light Yellow - Button Background
  static const buttonText = Color(0xFF000000); // Black - Button Text

  static const entColor = Color(0xFFD81B60);
  static const entBgLight = Color(0xFFFCE4EC);

  static const bgLight = Color(0xFFF5F5F5);
  static const bgCream = Color(0xFFF8F6F0);
  static const bgYellowLight = Color(0xFFFFF8E1);

  static const success = Colors.green;
  static const error = Colors.red;
  static const warning = Colors.orange;

  static const textDark = Color(0xFF1A1A2E);
  static const textBrown = Color(0xFF5D4037);
  static const textOrange = Color(0xFFF57C00);

  static const white = Colors.white;
  static const transparent = Colors.transparent;
}

class AppStrings {
  static const createOrder = 'CREATE ORDER';
  static const runningOrders = 'RUNNING ORDERS';
  static const orderSummary = 'ORDER SUMMARY';
  static const takeOrder = 'TAKE ORDER';
  static const viewOrder = 'View Orders';
  static const addOrder = 'ADD ORDER';
  static const confirmOrder = 'CONFIRM ORDER';
  static const addMoreItems = 'ADD MORE ITEMS';
  static const cancel = 'CANCEL';
  static const confirm = 'CONFIRM';
  static const ok = 'OK';
  static const discard = 'DISCARD';
  static const locationAndType = 'Location & Type';
  static const tableNo = 'Table No';
  static const contactNumber = 'Contact Number';
  static const cash = 'Cash';
  static const regular = 'Regular';
  static const ent = 'ENT';
  static const noRunningOrders = 'No Running Orders';
  static const tableOccupied = 'Table Occupied';
}

class AppSizes {
  static const buttonHeight = 48.0;
  static const radiusSmall = 6.0;
  static const radiusMedium = 10.0;
  static const radiusLarge = 16.0;
  static const spaceXS = 4.0;
  static const spaceS = 8.0;
  static const spaceM = 12.0;
  static const spaceL = 16.0;
  static const spaceXL = 20.0;
  static const iconS = 18.0;
  static const iconM = 24.0;
  static const fontXS = 11.0;
  static const fontS = 12.0;
  static const fontM = 14.0;
  static const fontL = 16.0;
  static const fontXL = 18.0;
}

class AppGradients {
  static const goldGradient = LinearGradient(
    colors: [AppColors.primaryGold, AppColors.goldDark],
  );

  static const darkGradient = LinearGradient(
    colors: [AppColors.drawerBackground, AppColors.drawerBackground],
  );
}

class AppImages {
  static const restaurantLogo =
      'https://img.freepik.com/premium-vector/restaurant-logo-design-template_79169-56.jpg';
  static const backgroundImage = 'assets/images/background.jpg';
  static const qrCodePlaceholder =
      'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=PaymentQRCode123';
}
