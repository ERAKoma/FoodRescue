import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:food_rescue/provider/user_provider.dart';
import 'package:food_rescue/pages/homepage.dart';
import 'package:food_rescue/pages/profile.dart';



class CustomNavBar extends StatefulWidget {
  const CustomNavBar({super.key});

  @override
  State<CustomNavBar> createState() => _CustomNavBarState();
}

class _CustomNavBarState extends State<CustomNavBar> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    // final user = Provider.of<UserProvider>(context).user;
    final List<Widget> _widgetOptions = [
      const Homepage(),
      const Profile(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.fastfood), label: 'Rescues'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}

