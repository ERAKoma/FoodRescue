import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:food_rescue/pages/login.dart';
import 'package:food_rescue/pages/signup.dart';
import 'package:food_rescue/pages/startup.dart';
import 'package:food_rescue/provider/user_provider.dart';
import 'package:food_rescue/widgets/nav_bar.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => UserProvider(),
      child: MaterialApp(
        title: 'FoodRescue',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Color.fromARGB(255, 0, 2, 141),
          ),
          useMaterial3: true,
        ),
        initialRoute: '/', // Initial route is usually the splash or login page
        routes: {
          '/': (context) => const Startup(),
          '/login': (context) => const Login(),
          '/signup': (context) => const SignUp(),
          '/home': (context) => const CustomNavBar(), // Directs here post-login
        },
      ),
    );
  }
}
