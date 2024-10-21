import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';


class connectionController extends GetxController{
  late StreamController<bool> deviceBluetoothController;
  StreamSubscription<DiscoveredDevice>? scanSub;
  StreamSubscription<ConnectionStateUpdate>? connectSub;
  StreamSubscription<ConnectionStateUpdate>? connectSub_2;
  StreamController<LatLng>? destController;
  StreamSubscription<List<int>>? _notifySub;
  List<DiscoveredDevice> foundDevices = [];
  bool isBluetoothOn = false;
  String ConnectedId = "";
  bool RX_found = false;
  double Altitude = 0.0;
  double Velocity =0.0;
  double distance_cal = 0.0;
  double distance= 0;
  late StreamController<bool> RxfoundController;
  late StreamController<List<double>> ValuesController;
  late List<DiscoveredService> discoveredServices;
  late Uuid characteristicId;
  List<int> completeMessage = [];
  List<int> finalResult = [];
  List<double> values = [];
  List<int> finalResultDecypher = [
    0, 1,
    35, 20,
    7,  13,
    31, 11,
    28, 3,
    16, 24,
    41, 32,
    10, 2,
    27, 9,
    22, 18,
    36, 38,
    6,  8,
    4,  34,
    21, 5,
    29, 30,
    14, 42,
    46,  26,
    33, 19,
    12, 40,
    17, 23,
    37, 15,
    25, 39,
    44, 45,
    43, 47,
    48, 49];
  List<int> cypher = [
    0, 1,
    35, 20,
    7,  13,
    31, 11,
    28, 3,
    16, 24,
    41, 32,
    10, 2,
    27, 9,
    22, 18,
    36, 38,
    6,  8,
    4,  34,
    21, 5,
    29, 30,
    14, 42,
    46,  26,
    33, 19,
    12, 40,
    17, 23,
    37, 15,
    25, 39,
    44, 45,
    43, 47,
    48, 49
  ];
   String connectionStatus= '';
   bool bluetoth_connected = false;
   final FlutterReactiveBle ble = FlutterReactiveBle();
  //final Connectivity _connectivity = Connectivity();

  Future<void> checkConnectivity() async {

    final connectivityResult = await Connectivity().checkConnectivity();


      switch (connectivityResult) {
        case ConnectivityResult.wifi:
          connectionStatus = 'Connected to Wi-Fi';

          break;
        case ConnectivityResult.mobile:
          connectionStatus = 'Connected to Cellular';

          break;
        case ConnectivityResult.none:
          connectionStatus = 'Not connected';

          break;
        default:
          connectionStatus = 'Unknown';

          break;
      }
    update();

  }
   void isEnableBluetooth() {
     ble.statusStream.listen((status) {
       if(status == BleStatus.ready){
         isBluetoothOn = true;
       }else{
         isBluetoothOn = false;
       }
       // isBluetoothOn = status == BleStatus.ready;
       // deviceBluetoothController.sink.add(isBluetoothOn);
       update();

     });

   }

   void startScan() {
    print("Start scan");
     scanSub?.cancel();
     update();
     foundDevices = [];
     update();
     // Cancel any previous scan
     // connectSub?.cancel();
     scanSub = ble.scanForDevices(withServices: []).listen(
           (device) {
         if (!foundDevices.any((d) => d.id == device.id) &&
             device.name.isNotEmpty) {
           foundDevices.add(device);
           update();
           print("device: $device");
           print("device array: ${foundDevices.first}");
         }
       },
       onError: (error) {
         if (error is GenericFailure<ScanFailure>) {
           // Handle the scan failure and retry if necessary
           print("Scan failed with code: ${error.code}, message: ${error
               .message}");
           if (error.code == ScanFailure.unknown) {
             DateTime retryDate = DateTime.parse(
                 error.message!.split("date is ")[1]);
             Duration retryDuration = retryDate.difference(DateTime.now());
             Timer(retryDuration, startScan);
           }
         }
       },
     );
     update();
   }

   void connectToDevice(String foundDeviceId,DiscoveredDevice device) {
     //scanSub?.cancel();
     connectSub?.cancel();
     update();
     connectSub = ble.connectToDevice(
       id: foundDeviceId,
       //servicesWithCharacteristicsToDiscover: {serviceId: [char1, char2]},
       connectionTimeout: const Duration(seconds: 2),
     ).listen((connectionState) {
       if (connectionState.connectionState == DeviceConnectionState.connected) {
         print("connected");
         Uuid service = device.serviceUuids.first;
         getChar(device.id,service);
         ConnectedId = foundDeviceId;
         update();
         RX_found = true;
         update();
         RxfoundController.sink.add(RX_found);
         update();
       } else if (connectionState.connectionState ==
           DeviceConnectionState.disconnected) {
         print("disconnected");
         ConnectedId = "";
         update();
         RX_found = false;
         update();
         RxfoundController.sink.add(RX_found);
         update();
         //ConnectedId = foundDeviceId;
         connectToDevice(foundDeviceId,device);
       } else {
         print(connectionState.toString());
       }

       // Handle connection state updates
     }, onError: (Object error) {
       // Handle a possible error
     });
   }


   void getChar(String deviceId, Uuid Service) async {
     discoveredServices = await ble.discoverServices(deviceId);
     for (var service in discoveredServices) {
       print("Service UUID: ${service.serviceId}");
       if (service.serviceId == Service) {
         characteristicId = service.characteristics.first.characteristicId;
         update();
         print("Char uuid :${service.characteristics.first.characteristicId}");
       }
     }
     final characteristic = QualifiedCharacteristic(
       deviceId: deviceId,
       serviceId: Service,
       characteristicId: characteristicId,
     );
     ble.subscribeToCharacteristic(characteristic).listen((data)  {
       completeMessage.addAll(data);
       print(data);
       if (completeMessage.length == 50) {
         // print("comes = 60");
         finalResult = completeMessage.sublist(0, 49);

         if (finalResult.first == 88) {
           print("finalResult : $finalResult");
           List<int> byteArray = finalResult.sublist(0,2);
           List<int> packetId = finalResult.sublist(2,4);
           List<int> byteArraylong = finalResult.sublist(4,12);
           List<int> byteArraylat = finalResult.sublist(12,20);
           List<int> altitude = finalResult.sublist(20,24);
           List<int> velocity = finalResult.sublist(24,28);
           List<int> heading = finalResult.sublist(28,30);
           List<int> Rssi = finalResult.sublist(30,34);
           List<int> SNR = finalResult.sublist(34,38);
           List<int> BatteryTX = finalResult.sublist(38,40);
           List<int> BatteryRX = finalResult.sublist(40,42);

           List<int> Lora_device_id = finalResult.sublist(42,44);
           List<int> Lora_data_id = finalResult.sublist(44,46);
           List<int> Lora_status = finalResult.sublist(46,48);
           // Example bytes
           int id = bytesToInt16(packetId, Endian.little);
           int value = bytesToInt16(byteArray, Endian.little);
           double doubleValuelng = bytesToDouble(byteArraylong);
           double doubleValuelat = bytesToDouble(byteArraylat);
           Altitude = bytesToInt32(altitude, Endian.little);
           update();
           Velocity = bytesToInt32(velocity, Endian.little);
           update();
           int Heading = bytesToInt16(heading, Endian.little);
           double RSSI = bytesToInt32(Rssi, Endian.little);
           double SnR = bytesToInt32(SNR, Endian.little);
           int BatteryTx = bytesToInt16(BatteryTX, Endian.little);
           int BatteryRx = bytesToInt16(BatteryRX, Endian.little);

           int LoRa_device_ID = bytesToInt16(Lora_device_id, Endian.little);
           int LoRa_data_ID = bytesToInt16(Lora_data_id, Endian.little);
           int LoRa_status = bytesToInt16(Lora_status, Endian.little);



           values = [id.toDouble(),Altitude,Heading.toDouble(),Velocity,doubleValuelng,doubleValuelat,BatteryRx.toDouble(),BatteryTx.toDouble(),RSSI];

           // Output the integer value
           ValuesController.sink.add(values);
           //finalResult.sublist(13,21);
           print("id: $id");
           print("longitude: $doubleValuelng");
           print("latitude: $doubleValuelat");
           print("Altitude: $Altitude");
           print("Velocity: $Velocity");
           print("Heading: $Heading");
           print("Rssi: $RSSI");
           print("SNR: $SnR");
           print("Battery RX: $BatteryRx");
           print("Battery TX: $BatteryTx");
           print("LoRa Device ID: $LoRa_device_ID");
           print("LoRa Data ID: $LoRa_data_ID");
           print("LoRa Status: $LoRa_status");
           LatLng destination = LatLng(doubleValuelat, doubleValuelng);
           destController?.sink.add(destination);




           //cypherConvert(finalResult);
           if (finalResult[33] != null) {
             //_
           }
         } else {}
         completeMessage = [];
       }else{

       }
       // else if (completeMessage.length == 20) {
       //   // print("comes < 60");
       //   if (completeMessage.first != 88) {
       //     completeMessage = [];
       //   }
       // }
       //print(data);
     }, onError: (dynamic error) {
       // code to handle errors
     });
   }

   void disconnect() {
     connectSub?.cancel();
     scanSub?.cancel();
     RX_found = false;
     RxfoundController.sink.add(RX_found);
     ConnectedId = "";
     values.clear();
     ValuesController.sink.add(values);
     update();

   }

   void cypherConvert(List<int> finalResult)  {
     for (int x = 0; x < finalResult.length; x ++) {
       var buffer;
       var first = cypher[x];
       var second = finalResult[x];
       finalResultDecypher[first] = second;


     }

     print("cypher result: $finalResultDecypher");
   }
   double bytesToDouble(List<int> byteArray) {
     // Ensure the list is exactly 8 bytes
     if (byteArray.length != 8) {
       throw ArgumentError('Byte array must be exactly 8 bytes long');
     }

     // Create a Uint8List from the byte array
     Uint8List uint8List = Uint8List.fromList(byteArray);

     // Create a ByteData view on the Uint8List
     ByteData byteData = ByteData.sublistView(uint8List);

     // Read the double value from the ByteData
     return byteData.getFloat64(0, Endian.little);
   }
   int bytesToInt16(List<int> byteArray, Endian endian) {
     // Ensure the list is exactly 2 bytes
     if (byteArray.length != 2) {
       throw ArgumentError('Byte array must be exactly 2 bytes long');
     }

     // Create a Uint8List from the byte array
     Uint8List uint8List = Uint8List.fromList(byteArray);

     // Create a ByteData view on the Uint8List
     ByteData byteData = ByteData.sublistView(uint8List);

     // Read the 16-bit integer value from the ByteData
     return byteData.getInt16(0, endian);
   }
   double bytesToInt32(List<int> byteArray, Endian endian) {
     // Ensure the list is exactly 2 bytes
     if (byteArray.length != 4) {
       throw ArgumentError('Byte array must be exactly 2 bytes long');
     }

     // Create a Uint8List from the byte array
     Uint8List uint8List = Uint8List.fromList(byteArray);

     // Create a ByteData view on the Uint8List
     ByteData byteData = ByteData.sublistView(uint8List);

     // Read the 16-bit integer value from the ByteData
     return byteData.getFloat32(0, endian);
   }
   double calculateDistance(
       double originLng, double originLat, double desLat, double desLng) {
     const double radius = 6371; // Earth's radius in kilometers
     double lat1 = degreesToRadians(originLat);
     double lon1 = degreesToRadians(originLng);
     double lat2 = degreesToRadians(desLat);
     double lon2 = degreesToRadians(desLng);

     double dLat = lat2 - lat1;
     double dLon = lon2 - lon1;

     double a = sin(dLat / 2) * sin(dLat / 2) +
         cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
     double c = 2 * atan2(sqrt(a), sqrt(1 - a));

     distance = radius * c;
     distance_cal = distance;

     return double.parse(distance_cal.toStringAsFixed(2));
     // print("distance in Km: $distance");
   }
   double degreesToRadians(double degrees){
    return degrees*pi/180;
   }


}