import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loyalty_app/Auth/CustomBottomNav.dart';
import 'package:loyalty_app/Auth/scan_receipt_screen.dart';
import 'package:loyalty_app/Controller/NavController.dart';
import 'package:loyalty_app/screen/home_screen.dart';
import 'package:loyalty_app/screen/notifications_screen.dart';
import 'package:loyalty_app/screen/rewards_screen.dart';
import 'package:loyalty_app/Auth/Profile.dart';



class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final NavController navController = Get.put(NavController());
  final PageController pageController = PageController();

  @override
  void initState() {
    super.initState();

    // Listen to navController changes and sync with PageView
    navController.selectedIndex.listen((index) {
      if (pageController.hasClients &&
          pageController.page?.round() != index) {
        pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() => PageView(
            controller: pageController,
            onPageChanged: (index) {
              navController.changePage(index);
            },
            children: [
              HomeScreen(
                onNavItemTapped: (index) =>
                    navController.changePage(index),
                currentIndex: navController.selectedIndex.value,
              ),
              const RewardsScreen(),
              ScanReceiptScreen(),
              const NotificationsScreen(),
              const Profile(),
            ],
          )),
      bottomNavigationBar: Obx(() => CustomBottomNav(
            currentIndex: navController.selectedIndex.value,
            onTap: (index) {
              if (index != navController.selectedIndex.value) {
                navController.changePage(index);
              }
            },
          )),
    );
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }
}
