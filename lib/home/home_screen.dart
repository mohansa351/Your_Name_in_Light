import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_badge_application/controllers/bluetooth_controller.dart';
import 'package:mobile_badge_application/home/device_screen.dart';
import 'package:mobile_badge_application/utils/constants.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  AnimationController? _animationController;
  Animation<double>? _animation;
  int currentIndex = 0;
  Timer? _timer;
  bool showHint = true;
  List<String> hints = [
    "John Doe                ",
    "I miss you              ",
    "Daddy's girl            ",
    "Happy Birthday          ",
    "Thinking about you      ",
    "Can I have an allowance?"
  ];

  bool leftScroll = true;
  void updateScroll(bool val) {
    leftScroll = val;
    _updateAnimation();
    _animationController!.reset();
    _animationController!.repeat();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _startHintTextAnimation();
    _controller.addListener(() {
      setState(() {
        showHint = _controller.text.isEmpty;
      });
    });

    _animationController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat();
    _updateAnimation();
  }

  void _updateAnimation() {
    _animation = Tween<double>(
            begin: leftScroll ? -1.0 : 1.0, end: leftScroll ? 1.0 : -1.0)
        .animate(
      CurvedAnimation(
        parent: _animationController!,
        curve: Curves.linear,
      ),
    );
  }

  void _startHintTextAnimation() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (showHint) {
        setState(() {
          currentIndex = (currentIndex + 1) % hints.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _animationController!.dispose();
    super.dispose();
  }

  Future<void> requestBluetoothPermissions() async {
    var bluetoothStatus = await Permission.bluetoothScan.request();

    if (bluetoothStatus.isGranted) {
      var bluetoothConnectStatus = await Permission.bluetoothConnect.request();

      if (bluetoothConnectStatus.isGranted) {
        print("Bluetooth connect permission granted");
        var locationStatus = await Permission.location.request();

        if (locationStatus.isGranted) {
          Get.to(() => const DeviceScreen());
          print("Location permission granted");
        } else {
          print("Location permission denied");
        }
      } else {
        print(
            "Bluetooth connect permission denied. Please allow it from settings.");
      }
      print("Bluetooth permission granted");
    } else {
      print("Bluetooth permission denied.");
      var locationStatus = await Permission.location.request();
      if (locationStatus.isGranted) {
        Get.to(() => const DeviceScreen());
        print("Location permission granted");
      } else {
        Get.to(() => const DeviceScreen());
        print("Location permission denied");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Image.asset("assets/images/logo.png", width: 250),
          actions: [
            GestureDetector(
                onTap: () {
                  requestBluetoothPermissions();
                },
                child: const Icon(Icons.settings)),
            const SizedBox(width: 20)
          ],
        ),
        bottomNavigationBar: Container(
            height: 130,
            color: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GetBuilder<BluetoothController>(
              builder: (BluetoothController controller) {
                return Column(
                  children: [
                    Text(
                      controller.status,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton(
                      onPressed: () {
                        if (_controller.text.isNotEmpty) {
                          if (leftScroll) {
                            controller.writeData(
                                _controller.text, "leftToRight");
                          } else {
                            controller.writeData(
                                _controller.text, "stationary");
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: SizedBox(
                        height: 45,
                        width: screenWidth(context),
                        child: const Center(
                          child: Text(
                            'Send it',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () async {
                        if (!await launchUrl(
                            Uri.parse("https://www.yniltoy.com/"))) {
                          throw Exception('Could not launch');
                        }
                      },
                      child: const Text(
                        "www.yniltoy.com",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                );
              },
            )),
        body: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 45),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Center(
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      TextFormField(
                        controller: _controller,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 15),
                          hintText: '',
                          fillColor: Colors.white,
                          focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                  color: Colors.pink, width: 2),
                              borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                          fontSize: 18,
                        ),
                      ),
                      if (showHint)
                        Positioned.fill(
                          child: GestureDetector(
                            onTap: () {
                              showHint = false;
                              setState(() {});
                            },
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 800),
                                  transitionBuilder: (Widget child,
                                      Animation<double> animation) {
                                    // Define the entry (bottom to center) and exit (center to top) transitions
                                    final slideIn = Tween<Offset>(
                                      begin: const Offset(
                                          0, 1), // Start from bottom
                                      end:
                                          const Offset(0, 0), // Center position
                                    ).animate(CurvedAnimation(
                                      parent: animation,
                                      curve: const Interval(0.0, 0.5,
                                          curve: Curves.easeOut),
                                    ));

                                    final slideOut = Tween<Offset>(
                                      begin: const Offset(
                                          0, -1), // Start from center
                                      end: const Offset(0, 0), // Exit to top
                                    ).animate(
                                      CurvedAnimation(
                                        parent: animation,
                                        curve: const Interval(0.5, 1.0,
                                            curve: Curves.easeIn),
                                      ),
                                    );

                                    return SlideTransition(
                                      position: child.key ==
                                              ValueKey(hints[currentIndex])
                                          ? slideIn
                                          : slideOut,
                                      child: FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: Text(
                                    hints[currentIndex],
                                    key: ValueKey<String>(hints[currentIndex]),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        updateScroll(true);
                      },
                      child: Container(
                        height: 95,
                        width: screenWidth(context) / 2 - 25,
                        decoration: BoxDecoration(
                          color: leftScroll
                              ? Colors.pink
                              : const Color(0xFFEAECF0),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Column(
                          children: [
                            Align(
                                alignment: Alignment.topLeft,
                                child: Icon(
                                  Icons.check_circle,
                                  color: leftScroll == false
                                      ? Colors.transparent
                                      : const Color(0xFF66C61C),
                                  //color: Color(0xFF66C61C),
                                )),
                            Text(
                              'LE',
                              style: TextStyle(
                                  color: leftScroll == false
                                      ? Colors.black
                                      : Colors.white,
                                  fontSize: 17),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Scroll Left',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: leftScroll == false
                                    ? Colors.black
                                    : Colors.white,
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    GestureDetector(
                      onTap: () {
                        updateScroll(false);
                      },
                      child: Container(
                        height: 95,
                        width: screenWidth(context) / 2 - 25,
                        decoration: BoxDecoration(
                            color: leftScroll == false
                                ? Colors.pink
                                : const Color(0xFFEAECF0),
                            borderRadius: BorderRadius.circular(10)),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Align(
                              alignment: Alignment.topLeft,
                              child: Icon(
                                Icons.check_circle,
                                color: leftScroll
                                    ? Colors.transparent
                                    : const Color(0xFF66C61C),
                                //color: Color(0xFF66C61C),
                              ),
                            ),
                            Text(
                              'ED',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: leftScroll == false
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Scroll Right',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: leftScroll == false
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 150),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                width: screenWidth(context),
                decoration: const BoxDecoration(
                  color: Colors.black,
                  border: Border.symmetric(
                    horizontal: BorderSide(color: Colors.red),
                  ),
                ),
                child: ClipRect(
                  // Ensures text stays within bounds
                  child: AnimatedBuilder(
                    animation: _animation!,
                    builder: (context, child) {
                      return Transform.translate(
                        offset:
                            Offset(_animation!.value * screenWidth(context), 0),
                        child: child,
                      );
                    },
                    child: Text(
                      _controller.text,
                      style: const TextStyle(
                        fontSize: 35,
                        fontWeight: FontWeight.w300,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ));
  }
}
