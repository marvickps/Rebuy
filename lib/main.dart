import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'providers/auth_provider.dart';
// import 'providers/product_provider.dart';
// import 'providers/chat_provider.dart';
// import 'providers/user_provider.dart';
// import 'screens/splash_screen.dart';
// import 'screens/auth/login_screen.dart';
// import 'screens/home/home_screen.dart';
// import 'screens/auth/signup_screen.dart';
// import 'screens/product/add_product_screen.dart';
// import 'screens/product/product_detail_screen.dart';
// import 'screens/chat/chat_list_screen.dart';
// import 'screens/chat/chat_screen.dart';
// import 'screens/profile/profile_screen.dart';
// import 'screens/payment/payment_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // ChangeNotifierProvider(create: (_) => ProductProvider()),
        // ChangeNotifierProvider(create: (_) => ChatProvider()),
        // ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: MaterialApp(
        title: 'OLX Clone',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          primaryColor: const Color(0xFF002F34),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF002F34),
            brightness: Brightness.light,
          ),
          textTheme: GoogleFonts.poppinsTextTheme(),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF002F34),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF002F34),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF002F34), width: 2),
            ),
          ),
        ),
        // home: const SplashScreen(),
        routes: {
          // '/login': (context) => const LoginScreen(),
          // '/signup': (context) => const SignupScreen(),
          // '/home': (context) => const HomeScreen(),
          // '/add-product': (context) => const AddProductScreen(),
          // '/product-detail': (context) => const ProductDetailScreen(),
          // '/chat-list': (context) => const ChatListScreen(),
          // '/chat': (context) => const ChatScreen(),
          // '/profile': (context) => const ProfileScreen(),
          // '/payment': (context) => const PaymentScreen(),
        },
      ),
    );
  }
}