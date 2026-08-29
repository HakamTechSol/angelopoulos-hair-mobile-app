import 'package:loyalty_app/Auth/scan_receipt_screen.dart';
import 'package:loyalty_app/screen/notifications_screen.dart';
import 'package:loyalty_app/screen/rewards_screen.dart';
import 'package:loyalty_app/Auth/profile.dart';
import 'package:get/get.dart';


class NavController extends GetxController {
  var selectedIndex = 0.obs; // Observable Index for Page Selection
  var showGradient = false.obs; // Observable for Gradient Visibility

  final pages = [
    // const HomeScreen(),
    const RewardsScreen(),
    const RewardsScreen(),
    const ScanReceiptScreen(),
    const NotificationsScreen(),
    const Profile(),
  ];

  // Method to change the page
  void changePage(int index) {
    selectedIndex.value = index;
  }

  // Method to toggle the gradient visibility
  void toggleGradient() {
    showGradient.value = !showGradient.value;
  }
}
