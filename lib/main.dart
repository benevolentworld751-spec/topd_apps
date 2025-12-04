import 'package:topd_apps/auth/auth_service.dart';
import 'package:topd_apps/screens/admin/add_menu_item_page.dart';
import 'package:topd_apps/screens/admin/admin_dashboard.dart';
import 'package:topd_apps/screens/admin/edit_menu_item_page.dart';
import 'package:topd_apps/screens/auth/login_screen.dart';
import 'package:topd_apps/screens/auth/signup_screen.dart';
import 'package:topd_apps/screens/main/home_screen.dart';
import 'package:topd_apps/services/cart_service.dart';
import 'package:topd_apps/services/firestore_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart'; // FlutterFire CLI generated


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => CartService()),
        Provider(create: (_) => FirestoreService()),
      ],
      child: Builder(
        builder: (context) {
          return const MyApp();
        },
      ),
    ),
  );
}




class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Teste of purani Dilli',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.deepOrange,
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.deepOrange.shade700,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.deepOrange.shade700,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepOrange.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.deepOrange.shade700,
            side: BorderSide(color: Colors.deepOrange.shade700),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.deepOrange.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.deepOrange.shade700, width: 2),
          ),
          labelStyle: TextStyle(color: Colors.deepOrange.shade700),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/home': (context) => const HomeScreen(),
        '/admin': (context) => const AdminDashboard(),
        '/add-menu-item': (context) => const AddMenuItemPage(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return StreamBuilder<User?>(
      stream: authService.user,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;

          if (user == null) {
            return const LoginScreen();
          }

          // ✅ Use custom claims instead of email
          return FutureBuilder<IdTokenResult>(
            future: user.getIdTokenResult(true), // refresh token for updated claims
            builder: (context, tokenSnapshot) {
              if (!tokenSnapshot.hasData) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final claims = tokenSnapshot.data!.claims;
              final isAdmin = claims?['admin'] == true;

              if (isAdmin) {
                return const AdminDashboard();
              }

              return const HomeScreen();
            },
          );
        }

        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
