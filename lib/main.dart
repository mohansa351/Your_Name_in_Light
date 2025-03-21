import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_badge_application/controllers/bluetooth_controller.dart';
import 'package:mobile_badge_application/intro_screens/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Your Name in LED',
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      initialBinding: BindingsBuilder(() {
        Get.put(BluetoothController());
      }),
      home: const SplashScreen(),
    );
  }
}
