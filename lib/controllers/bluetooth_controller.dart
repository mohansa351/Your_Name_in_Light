import 'dart:typed_data';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:get/get.dart';

class BluetoothController extends GetxController {
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  late Stream<DiscoveredDevice> _scanStream;
  List<DiscoveredDevice> devices = [];
  bool scanning = false;
  String status = "Disconnected";
  // DiscoveredDevice? selectedDevice;
  List<String> connected = [];
  List<String> disconnectedDevice = [];
  List<QualifiedCharacteristic> selectedCharacteristic = [];

  // Function to start scanning for led devices
  // Future<void> startScan() async {
  //   devices.clear();
  //   scanning = true;
  //   update();
  //
  //   _scanStream = _ble.scanForDevices(withServices: [],
  //       scanMode: ScanMode.lowLatency
  //   );
  //   _scanStream.listen((device) {
  //     if ((device.name.toLowerCase().contains("yn")) ) {
  //       if(!devices.contains(device)) {
  //         devices.add(device);
  //       }
  //       print("Discovered LED device: ${device.name} (${device.id})");
  //       update();
  //     }
  //   }, onError: (error) {
  //     scanning = false;
  //     update();
  //   }, onDone: () {
  //     scanning = false;
  //     update();
  //   });
  // }

  Future<void> startScan() async {
    // devices.clear();
    scanning = true;
    update();

    // Start scanning
    _scanStream = _ble.scanForDevices(
      withServices: [],
      scanMode: ScanMode.balanced,
    );

    // Listen to the scan stream
    _scanStream.listen((device) {
      if (device.name.toLowerCase().contains("yn")) {
        final isDeviceExists =
            devices.where((d) => d.id == device.id).isNotEmpty;

        if (!isDeviceExists) {
          devices.add(device);
          print("Discovered LED device: ${device.name} (${device.id})");
          update();
        }
      }
    }, onError: (error) {
      print(error.toString());
      scanning = false;
      update();
    }, onDone: () {
      scanning = false;
      update();
    });
  }

  // Function to connect the device
  Future<void> connectAndDiscover(DiscoveredDevice device) async {
    try {
      if (disconnectedDevice.contains(device.id.toString())) {
        // final services = await _ble.getDiscoveredServices(device.id);
        // for (var service in services) {
        //   for (var characteristic in service.characteristics) {
        //     if (characteristic.isWritableWithoutResponse ||
        //         characteristic.isWritableWithResponse) {
        //       selectedCharacteristic.add(QualifiedCharacteristic(
        //         serviceId: service.id,
        //         characteristicId: characteristic.id,
        //         deviceId: device.id,
        //       ));
        //     }
        //   }
        // }
        status = "Connected";
        connected.add(device.id.toString());
        update();
      } else {
        _ble.connectToDevice(id: device.id).listen((connectionState) async {
          final services = await _ble.getDiscoveredServices(device.id);
          for (var service in services) {
            for (var characteristic in service.characteristics) {
              if (characteristic.isWritableWithoutResponse ||
                  characteristic.isWritableWithResponse) {
                selectedCharacteristic.add(QualifiedCharacteristic(
                  serviceId: service.id,
                  characteristicId: characteristic.id,
                  deviceId: device.id,
                ));
              }
            }
          }
          status = "Connected";
          connected.add(device.id.toString());
          update();
        });
      }
    } catch (e) {
      print(e.toString());

      status = "Unable to connect";
      update();
    }
  }

  // Function to connect the device
  disconnectDevice(DiscoveredDevice device) {
   connected.removeWhere((val)=> val == device.id.toString());
    if (!disconnectedDevice.contains(device.id.toString())) {
      disconnectedDevice.add(device.id.toString());
    }
    if (connected.isEmpty) {
      status = "Disconnected";
    }
    update();
  }

  //// Write data on led device
  Future<void> writeData(String text, String movement) async {
    if (connected.isNotEmpty && selectedCharacteristic.isNotEmpty) {
      try {
        for (var characteristic in selectedCharacteristic) {
          await _ble.writeCharacteristicWithResponse(
            characteristic,
            value: buildPacket(text, movement),
          );
        }
        update();
      } catch (e) {
  
        print(e.toString());
        update();
      }
    } else {
      status = "Not connected to any device";
      update();
    }
  }

  Uint8List buildPacket(String message, String movementDirection) {
    final startIdentifier = [0x58, 0x59, 0x54, 0x44];
    final endIdentifier = [0x0D, 0x0A];

    // Map direction strings to movement codes
    final Map<String, int> directionCodes = {
      'leftToRight': 0x01,
      'rightToLeft': 0x02,
      'topToBottom': 0x03,
      'bottomToTop': 0x04,
      'stationary': 0x00,
    };

    // Fetch the movement code, default to stationary if invalid
    final movementCode = directionCodes[movementDirection] ?? 0x00;

    // Initialize an empty list to store the dot matrix data for the message
    List<int> displayFields = [];

    // Iterate over the message and add the corresponding dot matrix data
    for (int i = 0; i < message.length; i++) {
      String char = message[i];
      if (dotMatrixMappings.containsKey(char)) {
        displayFields.addAll(dotMatrixMappings[char]!);
      } else {
        // Default to space for unsupported characters
        displayFields.addAll(dotMatrixMappings[' ']!);
      }
    }

    final content = [
      0x01, // Number of Data groups
      0x0C, // Dot matrix screen type
      0x00, 0x00, // Display style
      0x00, // Display style of this group
      0x04, // Speed
      movementCode, // Movement direction code
      message
          .length, // Number of display fields (one for each character in the message)
      ...displayFields, // Fields for the message
    ];

    // Convert the length to a 2-byte array in big-endian format
    final length = intToBytes(content.length, 2, Endian.big);

    return Uint8List.fromList([
      ...startIdentifier,
      ...length,
      ...content,
      ...endIdentifier,
    ]);
  }

// Helper function to convert an integer to a byte array
  List<int> intToBytes(int value, int byteCount, Endian endian) {
    final byteData = ByteData(byteCount);
    if (byteCount == 2) {
      byteData.setInt16(0, value, endian);
    } else if (byteCount == 4) {
      byteData.setInt32(0, value, endian);
    } else {
      throw ArgumentError('Unsupported byte count: $byteCount');
    }
    return byteData.buffer.asUint8List();
  }

  // Future<void> readDeviceResponse() async {
  //   if (selectedCharacteristic != null) {
  //     try {
  //       final response = await _ble.readCharacteristic(selectedCharacteristic!);
  //       final decodedString = String.fromCharCodes(response);
  //       print("Decoded response: $decodedString");
  //       print("Response from device: $response");
  //     } catch (e) {
  //       print("Error reading device response: $e");
  //     }
  //   } else {
  //     print("No readable characteristic selected.");
  //   }
  // }

  final Map<String, List<int>> dotMatrixMappings = {
    'A': [
      0x00,
      0x78,
      0xCC,
      0xCC,
      0xFC,
      0xCC,
      0xCC,
      0xCC,
      0xCC,
      0xCC,
      0x00,
      0x00
    ],
    'B': [
      0x00,
      0xF8,
      0xCC,
      0xCC,
      0xF8,
      0xCC,
      0xCC,
      0xCC,
      0xCC,
      0xF8,
      0x00,
      0x00
    ],
    'C': [
      0x00,
      0x78,
      0xCC,
      0xC0,
      0xC0,
      0xC0,
      0xC0,
      0xC0,
      0xCC,
      0x78,
      0x00,
      0x00
    ],
    'D': [
      0x00,
      0xF8,
      0xCC,
      0xCC,
      0xCC,
      0xCC,
      0xCC,
      0xCC,
      0xCC,
      0xF8,
      0x00,
      0x00
    ],
    'E': [
      0x00,
      0xFC,
      0xC0,
      0xC0,
      0xF8,
      0xC0,
      0xC0,
      0xC0,
      0xC0,
      0xFC,
      0x00,
      0x00
    ],
    'F': [
      0x00,
      0xFC,
      0xC0,
      0xC0,
      0xF8,
      0xC0,
      0xC0,
      0xC0,
      0xC0,
      0xC0,
      0x00,
      0x00
    ],
    'G': [
      0x00,
      0x78,
      0xCC,
      0xC0,
      0xC0,
      0xDE,
      0xCC,
      0xCC,
      0xCC,
      0x78,
      0x00,
      0x00
    ],
    'H': [
      0x00,
      0xCC,
      0xCC,
      0xCC,
      0xFC,
      0xCC,
      0xCC,
      0xCC,
      0xCC,
      0xCC,
      0x00,
      0x00
    ],
    'I': [
      0x00,
      0x78,
      0x30,
      0x30,
      0x30,
      0x30,
      0x30,
      0x30,
      0x30,
      0x78,
      0x00,
      0x00
    ],
    'J': [
      0x00,
      0x3C,
      0x18,
      0x18,
      0x18,
      0x18,
      0x18,
      0x18,
      0xD8,
      0x70,
      0x00,
      0x00
    ],
    'K': [
      0x00,
      0xCC,
      0xD8,
      0xF0,
      0xE0,
      0xF0,
      0xD8,
      0xCC,
      0xCC,
      0xCC,
      0x00,
      0x00
    ],
    'L': [
      0x00,
      0xC0,
      0xC0,
      0xC0,
      0xC0,
      0xC0,
      0xC0,
      0xC0,
      0xC0,
      0xFC,
      0x00,
      0x00
    ],
    'M': [
      0x00,
      0xCC,
      0xFC,
      0xFC,
      0xEC,
      0xEC,
      0xCC,
      0xCC,
      0xCC,
      0xCC,
      0x00,
      0x00
    ],
    'N': [
      0x00,
      0xCC,
      0xCC,
      0xEC,
      0xEC,
      0xFC,
      0xDC,
      0xDC,
      0xCC,
      0xCC,
      0x00,
      0x00
    ],
    'O': [
      0x00,
      0x78,
      0xCC,
      0xCC,
      0xCC,
      0xCC,
      0xCC,
      0xCC,
      0xCC,
      0x78,
      0x00,
      0x00
    ],
    'P': [
      0x00,
      0xF8,
      0xCC,
      0xCC,
      0xCC,
      0xF8,
      0xC0,
      0xC0,
      0xC0,
      0xC0,
      0x00,
      0x00
    ],
    'Q': [
      0x00,
      0x78,
      0xCC,
      0xCC,
      0xCC,
      0xCC,
      0xCC,
      0xCC,
      0xDC,
      0x78,
      0x0C,
      0x00
    ],
    'R': [
      0x00,
      0xF8,
      0xCC,
      0xCC,
      0xCC,
      0xF8,
      0xD8,
      0xCC,
      0xCC,
      0xCC,
      0x00,
      0x00
    ],
    'S': [
      0x00,
      0x78,
      0xCC,
      0xC0,
      0x60,
      0x30,
      0x18,
      0x0C,
      0xCC,
      0x78,
      0x00,
      0x00
    ],
    'T': [
      0x00,
      0xFC,
      0x30,
      0x30,
      0x30,
      0x30,
      0x30,
      0x30,
      0x30,
      0x30,
      0x00,
      0x00
    ],
    'U': [
      0x00,
      0xCC,
      0xCC,
      0xCC,
      0xCC,
      0xCC,
      0xCC,
      0xCC,
      0xCC,
      0x78,
      0x00,
      0x00
    ],
    'V': [
      0x00,
      0xCC,
      0xCC,
      0xCC,
      0xCC,
      0xCC,
      0x78,
      0x78,
      0x30,
      0x30,
      0x00,
      0x00
    ],
    'W': [
      0x00,
      0xCC,
      0xCC,
      0xCC,
      0xCC,
      0xCC,
      0xEC,
      0xEC,
      0xFC,
      0xCC,
      0x00,
      0x00
    ],
    'X': [
      0x00,
      0xCC,
      0xCC,
      0x78,
      0x30,
      0x30,
      0x78,
      0xCC,
      0xCC,
      0xCC,
      0x00,
      0x00
    ],
    'Y': [
      0x00,
      0xCC,
      0xCC,
      0xCC,
      0xCC,
      0x78,
      0x30,
      0x30,
      0x30,
      0x30,
      0x00,
      0x00
    ],
    'Z': [
      0x00,
      0xFC,
      0x0C,
      0x18,
      0x30,
      0x60,
      0xC0,
      0xC0,
      0xC0,
      0xFC,
      0x00,
      0x00
    ],

    //lowercase alphabets
    'a': [
      0x00,
      0x00,
      0x00,
      0x00,
      0x78,
      0x0C,
      0x7C,
      0xCC,
      0xCC,
      0x76,
      0x00,
      0x00
    ],
    'b': [
      0x00,
      0xE0,
      0x60,
      0x60,
      0x7C,
      0x66,
      0x66,
      0x66,
      0x66,
      0x7C,
      0x00,
      0x00
    ],
    'c': [
      0x00,
      0x00,
      0x00,
      0x00,
      0x7C,
      0xC6,
      0xC0,
      0xC0,
      0xC6,
      0x7C,
      0x00,
      0x00
    ],
    'd': [
      0x00,
      0x1C,
      0x0C,
      0x0C,
      0x7C,
      0xCC,
      0xCC,
      0xCC,
      0xCC,
      0x7C,
      0x00,
      0x00
    ],
    'e': [
      0x00,
      0x00,
      0x00,
      0x00,
      0x78,
      0xCC,
      0xFC,
      0xC0,
      0xCC,
      0x78,
      0x00,
      0x00
    ],
    'f': [
      0x00,
      0x38,
      0x6C,
      0x60,
      0xF0,
      0x60,
      0x60,
      0x60,
      0x60,
      0x60,
      0x00,
      0x00
    ],
    'g': [
      0x00,
      0x00,
      0x00,
      0x00,
      0x76,
      0xCC,
      0xCC,
      0xCC,
      0xCC,
      0x7C,
      0x0C,
      0xF8
    ],
    'h': [
      0x00,
      0xE0,
      0x60,
      0x60,
      0x7C,
      0x66,
      0x66,
      0x66,
      0x66,
      0x66,
      0x00,
      0x00
    ],
    'i': [
      0x00,
      0x30,
      0x30,
      0x00,
      0x70,
      0x30,
      0x30,
      0x30,
      0x30,
      0x78,
      0x00,
      0x00
    ],
    'j': [
      0x00,
      0x18,
      0x18,
      0x00,
      0x38,
      0x18,
      0x18,
      0x18,
      0x18,
      0x18,
      0xD8,
      0x70
    ],
    'k': [
      0x00,
      0xE0,
      0x60,
      0x60,
      0x6C,
      0x78,
      0x70,
      0x78,
      0x6C,
      0x66,
      0x00,
      0x00
    ],
    'l': [
      0x00,
      0x70,
      0x30,
      0x30,
      0x30,
      0x30,
      0x30,
      0x30,
      0x30,
      0x78,
      0x00,
      0x00
    ],
    'm': [
      0x00,
      0x00,
      0x00,
      0x00,
      0xCC,
      0xFC,
      0xFC,
      0xEC,
      0xEC,
      0xCC,
      0x00,
      0x00
    ],
    'n': [
      0x00,
      0x00,
      0x00,
      0x00,
      0xDC,
      0x66,
      0x66,
      0x66,
      0x66,
      0x66,
      0x00,
      0x00
    ],
    'o': [
      0x00,
      0x00,
      0x00,
      0x00,
      0x78,
      0xCC,
      0xCC,
      0xCC,
      0xCC,
      0x78,
      0x00,
      0x00
    ],
    'p': [
      0x00,
      0x00,
      0x00,
      0x00,
      0xDC,
      0x66,
      0x66,
      0x66,
      0x66,
      0x7C,
      0x60,
      0xF0
    ],
    'q': [
      0x00,
      0x00,
      0x00,
      0x00,
      0x76,
      0xCC,
      0xCC,
      0xCC,
      0xCC,
      0x7C,
      0x0C,
      0x1E
    ],
    'r': [
      0x00,
      0x00,
      0x00,
      0x00,
      0xDC,
      0x76,
      0x60,
      0x60,
      0x60,
      0xF0,
      0x00,
      0x00
    ],
    's': [
      0x00,
      0x00,
      0x00,
      0x00,
      0x7C,
      0xC6,
      0x60,
      0x18,
      0xC6,
      0x7C,
      0x00,
      0x00
    ],
    't': [
      0x00,
      0x60,
      0x60,
      0x60,
      0xF0,
      0x60,
      0x60,
      0x60,
      0x6C,
      0x38,
      0x00,
      0x00
    ],
    'u': [
      0x00,
      0x00,
      0x00,
      0x00,
      0xCC,
      0xCC,
      0xCC,
      0xCC,
      0xCC,
      0x76,
      0x00,
      0x00
    ],
    'v': [
      0x00,
      0x00,
      0x00,
      0x00,
      0xCC,
      0xCC,
      0xCC,
      0xCC,
      0x78,
      0x30,
      0x00,
      0x00
    ],
    'w': [
      0x00,
      0x00,
      0x00,
      0x00,
      0xCC,
      0xCC,
      0xCC,
      0xEC,
      0xFC,
      0x48,
      0x00,
      0x00
    ],
    'x': [
      0x00,
      0x00,
      0x00,
      0x00,
      0xCC,
      0x78,
      0x30,
      0x30,
      0x78,
      0xCC,
      0x00,
      0x00
    ],
    'y': [
      0x00,
      0x00,
      0x00,
      0x00,
      0xCC,
      0xCC,
      0xCC,
      0xCC,
      0xCC,
      0x7C,
      0x0C,
      0xF8
    ],
    'z': [
      0x00,
      0x00,
      0x00,
      0x00,
      0xFC,
      0x18,
      0x30,
      0x60,
      0xC0,
      0xFC,
      0x00,
      0x00
    ],

    /// Numbers
    '0': [
      0x00,
      0x00,
      0x00,
      0x00,
      0x78,
      0xCC,
      0xCC,
      0xCC,
      0xCC,
      0x78,
      0x00,
      0x00
    ],
    '1': [
      0x00,
      0x00,
      0x00,
      0x00,
      0x30,
      0x70,
      0x30,
      0x30,
      0x30,
      0x78,
      0x00,
      0x00
    ],
    '2': [
      0x00,
      0x00,
      0x00,
      0x00,
      0x78,
      0xCC,
      0x0C,
      0x78,
      0xC0,
      0xFC,
      0x00,
      0x00
    ],
    '3': [
      0x00,
      0x00,
      0x00,
      0x00,
      0x78,
      0xCC,
      0x0C,
      0x38,
      0x0C,
      0xF8,
      0x00,
      0x00
    ],
    '4': [
      0x00,
      0x00,
      0x00,
      0x00,
      0x18,
      0x38,
      0x58,
      0x98,
      0xFC,
      0x18,
      0x00,
      0x00
    ],
    '5': [
      0x00,
      0x00,
      0x00,
      0x00,
      0xFC,
      0xC0,
      0xF8,
      0x0C,
      0xCC,
      0x78,
      0x00,
      0x00
    ],
    '6': [
      0x00,
      0x00,
      0x00,
      0x00,
      0x38,
      0x60,
      0xC0,
      0xF8,
      0xCC,
      0x78,
      0x00,
      0x00
    ],
    '7': [
      0x00,
      0x00,
      0x00,
      0x00,
      0xFC,
      0x0C,
      0x18,
      0x30,
      0x30,
      0x30,
      0x00,
      0x00
    ],
    '8': [
      0x00,
      0x00,
      0x00,
      0x00,
      0x78,
      0xCC,
      0xCC,
      0x78,
      0xCC,
      0x78,
      0x00,
      0x00
    ],
    '9': [
      0x00,
      0x00,
      0x00,
      0x00,
      0x78,
      0xCC,
      0xCC,
      0x7C,
      0x0C,
      0x78,
      0x00,
      0x00
    ],

    ' ': [
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00
    ] // Space for empty display
  };
}
