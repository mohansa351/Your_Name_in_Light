import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import '../controllers/bluetooth_controller.dart';

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({super.key});

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  bool _startTimer = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => Get.find<BluetoothController>().startScan());
  }

  void killTimer() {
    Timer(const Duration(seconds: 10), () {
      _startTimer = false;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: GetBuilder<BluetoothController>(
        builder: (BluetoothController controller) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    "Searching for Badge Device",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  Center(
                    child: Lottie.asset(
                      'assets/gif/bluetooth_animation.json',
                      fit: BoxFit.cover,
                    ),
                  ),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(width: 10),
                      Text(
                        "Devices",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      SizedBox(width: 20),
                      // GestureDetector(
                      //   onTap: () {
                      //     controller.startScan();
                      //     _startTimer = true;
                      //     setState(() {});
                      //     killTimer();
                      //   },
                      //   child: const Text(
                      //     "Refresh",
                      //     style: TextStyle(fontSize: 12, color: Colors.blue),
                      //   ),
                      // ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ListView.builder(
                      itemCount: controller.devices.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        final device = controller.devices[index];
                        return GestureDetector(
                            onTap: () {
                              if (controller.connected.contains(device.id)) {
                                controller.disconnectDevice(device);
                              } else {
                                controller.connectAndDiscover(device);
                              }
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.grey),
                                  color: Colors.transparent.withOpacity(.3)),
                              child: ListTile(
                                title: Text(
                                  device.name.isNotEmpty
                                      ? device.name
                                      : "Unknown Device",
                                  style: const TextStyle(
                                      fontSize: 16, color: Colors.white),
                                ),
                                subtitle: Text(
                                  device.id,
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.white),
                                ),
                                trailing: Text(
                                  controller.connected.contains(device.id)
                                      ? "Connected"
                                      : "",
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ));
                      }),
                  const SizedBox(height: 25),
                  _startTimer
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white))
                      : const SizedBox()
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
