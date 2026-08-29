import 'package:flutter/material.dart';
import 'package:loyalty_app/Auth/SignIn.dart';
import 'package:loyalty_app/screen/MainScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthChecker extends StatefulWidget {
  const AuthChecker({super.key});

  @override
  State<AuthChecker> createState() => _AuthCheckerState();
}

class _AuthCheckerState extends State<AuthChecker> {
  String? phone;
  String? usrPhone;
  String? usrname;
  String? usrtrdr;

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final userPhone = prefs.getString('user_phone');
    final usname = prefs.getString('NAME');
    final usPhone = prefs.getString('PHONE');
    final ustrdr = prefs.getString('TRDR');

    setState(() {
      phone = userPhone;
      usrPhone = usPhone;
      usrname = usname;
      usrtrdr = ustrdr;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (phone != null ||
        usrPhone != null ||
        usrname != null ||
        usrtrdr != null) {
      return const MainScreen(); // ✅ User is logged in
    } else {
      return const SignInScreen(); // ❌ User is not logged in
    }
  }
}
