// lib/app.dart
import 'package:flutter/material.dart';
import 'package:hotel_order_taking_app/Screen/home_screen.dart';
import 'package:hotel_order_taking_app/Screen/order_summary_screen.dart';
import 'package:hotel_order_taking_app/Screen/qr_screen.dart';
// Assuming you named it qr_scanner_screen.dart

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Restaurant Order System',
      debugShowCheckedModeBanner: false,

      // --- Global Theme ---
      theme: ThemeData(
        // Use a primary color suitable for a restaurant/food app
        primaryColor: Colors.red.shade700,
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.red,
        ).copyWith(
          secondary: Colors.teal.shade400, // Accent color for buttons/FABs
          // Define a green color for success/confirm actions
          surface: Colors.green.shade600,
        ),
        scaffoldBackgroundColor: Colors.grey.shade50,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.red.shade700,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),

      // --- Route Management ---
      initialRoute: '/',
      routes: {
        // The main ordering screen (Table selection, Menu search)
        '/': (context) => HomeScreen(),

        // The screen to review and confirm the current order
        '/order-summary': (context) => OrderSummaryScreen(),

        // The screen for scanning table QR codes
        '/qr-scanner': (context) => QrScannerScreen(),
      },
    );
  }
}
