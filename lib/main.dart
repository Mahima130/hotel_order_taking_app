import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hotel_order_taking_app/services/firestore_service.dart';
import 'Provider/order_provider.dart';
import 'Screen/SplashScreen.dart';
import 'Screen/login_screen.dart';
import 'Screen/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // ✅ Seed data on first launch + ensure today's data exists
  await _initializeAppData();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => OrderProvider()),
      ],
      child: const RestaurantApp(), // Changed from MyApp
    ),
  );
}

// ✅ Initialize app data (runs on every launch)
Future<void> _initializeAppData() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final firestoreService = FirestoreService();

    // ============================================
    // 1️⃣ SEED TABLE DATA (Only once ever)
    // ============================================
    final hasSeededTables = prefs.getBool('tables_seeded') ?? false;

    if (!hasSeededTables) {
      print('🌱 First launch detected - Seeding table data...');
      await firestoreService.seedTableData();
      await prefs.setBool('tables_seeded', true);
      print('✅ Table data seeded successfully!');
    } else {
      print('✅ Table data already exists - skipping');
    }

    // ============================================
    // 2️⃣ ENSURE TODAY'S ORDER STATUS DATA EXISTS
    // (Runs every day to create fresh demo data)
    // ============================================
    print('📅 Checking if today\'s order status data exists...');
    await firestoreService.ensureTodayDataExists();
    print('✅ Today\'s data is ready!');
  } catch (e) {
    print('❌ Error in _initializeAppData: $e');
  }
}

class RestaurantApp extends StatelessWidget {
  const RestaurantApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Restaurant POS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFFD4AF37),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      ),
      // Define routes
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
