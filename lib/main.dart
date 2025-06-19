import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rebuy/providers/favorite_provider.dart';
import 'package:rebuy/providers/offer_provider.dart';
import 'package:rebuy/screens/home/components/listing_screen.dart';
import 'package:rebuy/screens/product/offer_management.dart';

import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/user_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/product/add_product_screen.dart';
import 'screens/product/product_detail_screen.dart';
import 'screens/chat/screen/chat_list_screen.dart';
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
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => OfferProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
      ],
      child: MaterialApp(
        title: 'Rebuy',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          primaryColor: const Color(0xFF078893),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF078893),
            brightness: Brightness.light,
          ),
          textTheme: GoogleFonts.poppinsTextTheme(),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF078893),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF078893),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF078893), width: 2),
            ),
          ),
        ),
        home: const SplashScreen(),
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/login':
              return MaterialPageRoute(
                builder: (context) => const LoginScreen(),
              );
            case '/signup':
              return MaterialPageRoute(
                builder: (context) => const SignupScreen(),
              );
            case '/home':
              return MaterialPageRoute(
                builder: (context) => const HomeScreen(),
              );
            case '/add-product':
              return MaterialPageRoute(
                builder: (context) => const AddProductScreen(),
              );
            case '/product-detail':
              // Handle ProductDetailScreen with arguments
              final args = settings.arguments as Map<String, dynamic>?;
              if (args != null && args.containsKey('productId')) {
                return MaterialPageRoute(
                  builder: (context) => ProductDetailScreen(
                    productId: args['productId'] as String,
                    product: args['product'], // Optional product object
                  ),
                );
              }
              // Fallback to home if no proper arguments
              return MaterialPageRoute(
                builder: (context) => const HomeScreen(),
              );
            // Add other routes as needed
            case '/chat-list':
              return MaterialPageRoute(
                builder: (context) => const ChatListScreen(),
              );
            // case '/chat':
            //   return MaterialPageRoute(builder: (context) => const ChatScreen());
            // case '/profile':
            //   return MaterialPageRoute(builder: (context) => const ProfileScreen());
            // case '/payment':
            //   return MaterialPageRoute(builder: (context) => const PaymentScreen());
            default:
              return MaterialPageRoute(
                builder: (context) => const HomeScreen(),
              );
          }
        },
        routes: {
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
          '/home': (context) => const HomeScreen(),
          '/add-product': (context) => const AddProductScreen(),
          '/offers': (context) => const OffersScreen(),
          // Remove the simple product-detail route since we're using onGenerateRoute
          '/my_product': (context) => MyListingScreen(),
          '/chat-list': (context) => const ChatListScreen(),
          // '/chat': (context) => const ChatScreen(),
          // '/profile': (context) => const ProfileScreen(),
          // '/payment': (context) => const PaymentScreen(),
        },
      ),
    );
  }
}
