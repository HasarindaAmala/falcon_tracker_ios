import 'dart:async';

import 'package:falcon_tracker/Controllers/connectionController.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'Controllers/FileHandlingController.dart';
import 'downloadScreen.dart';
import 'package:flutter_beep/flutter_beep.dart';



List<Marker> markers = [];

class connectionScreen extends StatefulWidget {
  const connectionScreen({super.key});

  @override
  State<connectionScreen> createState() => _connectionScreenState();
}

class _connectionScreenState extends State<connectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _animation;
  StreamSubscription? connectionStateSubscription;
  FileHandling fileController = Get.put(FileHandling());
  connectionController connectionControll = Get.put(connectionController());
  late StreamController<bool> modeChange;
  Position? location;
  late String _country;

  MapController mapController = MapController();

  late final tileProvider = const FMTCStore('mapStore').getTileProvider(
      settings: FMTCTileProviderSettings(
    behavior: CacheBehavior.onlineFirst,
  ));

  @override
  void initState() {
    // TODO: implement initState
    modeChange = StreamController<bool>.broadcast();
    connectionControll.destController = StreamController<LatLng>.broadcast();
    connectionControll.ValuesController = StreamController<List<double>>.broadcast();
    connectionControll.RxfoundController = StreamController<bool>.broadcast();
    // Create the AnimationController
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    // Define the color animation (from white to red and back to white)
    _animation = ColorTween(
      begin: Colors.white,
      end: Color(0xFFFF5061).withOpacity(0.6),
    ).animate(_controller)
      ..addListener(() {
        setState(() {}); // Update UI whenever animation value changes
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _controller.reverse(); // Reverse animation when complete
        } else if (status == AnimationStatus.dismissed) {
          _controller.forward(); // Start animation again when dismissed
        }
      });

    // Start the animation
    _controller.forward();
    getCurrentLocation();
    connectionControll.isEnableBluetooth();
    //getCurrentCountry(location);
    _initializeConnectivity();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    connectionControll.dispose();
    mapController.dispose();
    super.dispose();
  }

  Future<void> _initializeConnectivity() async {
    await connectionControll.checkConnectivity();
  }

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    precacheImage(const AssetImage("assets/downBack.gif"), context);
    precacheImage(const AssetImage("assets/eagle.gif"), context);
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      // appBar: AppBar(
      //   actions: [
      //     Text("Falcon",style: TextStyle(color: Colors.black,fontSize: 20.0,fontWeight: FontWeight.bold),),
      //     Text("Tracker",style: TextStyle(color: Colors.red,fontSize: 20.0,fontWeight: FontWeight.bold),),
      //     SizedBox(width: width*0.04,)
      //   ],
      //   leading: Padding(
      //     padding: EdgeInsets.fromLTRB(width*0.03, 0.0, 0.0, 0.0),
      //     child: Container(
      //       width: width*0.05,
      //       height: width*0.05,
      //       decoration: BoxDecoration(
      //         shape: BoxShape.circle,
      //         color: _animation.value ?? Colors.white,
      //       ),
      //     ),
      //   ),
      //
      // ),
      body: Stack(
        children: [
          FlutterMap(
              options: MapOptions(
                backgroundColor: Colors.black,
                initialZoom: 13,
                initialCenter: LatLng(location!.latitude, location!.longitude),
                //widget.data == "Sri lanka" ?  LatLng(6.8361301, 79.9216126):(widget.data == "UAE" ? LatLng(23.2365, 54.5549):LatLng(35.2365, -100.5549)),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  // Other config parameters
                  tileProvider: tileProvider,
                ),
                // MarkerLayer(
                //   markers: [
                //     Marker(
                //       width: 80.0,
                //       height: 80.0,
                //       point: LatLng(location!.latitude,
                //           location!.longitude), // Example marker at Dubai, UAE
                //       child: const Icon(
                //         Icons.not_listed_location,
                //         color: Colors.blue,
                //         size: 40.0,
                //       ),
                //     ),
                //   ],
                // ),
                StreamBuilder(
                    stream: connectionControll.destController?.stream,
                    builder: (context, snapshot) {

                      if (snapshot.hasData) {
                        FlutterBeep.playSysSound(iOSSoundIDs.KeyPressed1);
                        if (snapshot.data!.longitude == 0 &&
                            snapshot.data!.latitude == 0) {
                          return Center(
                            child: Container(
                              color: Colors.red.withOpacity(0.4),
                              width: width * 0.8,
                              height: height * 0.1,
                              child: const Center(
                                child: Text("GPS is not Locked!"),
                              ),
                            ),
                          );
                        } else {
                          markerAdd(snapshot.data!.latitude,
                              snapshot.data!.longitude);
                          return StreamBuilder(
                              stream: modeChange.stream,
                              initialData: true,
                              builder: (context, data) {
                                print(data.data);
                                if (data.data == true || data.data == null) {
                                  return Stack(
                                    children: [
                                      PolylineLayer(
                                        polylines: [
                                          Polyline(
                                            points: [
                                              LatLng(location!.latitude, location!.longitude),
                                              LatLng(snapshot.data!.latitude,
                                                  snapshot.data!.longitude),
                                            ],
                                            pattern:
                                                const StrokePattern.dotted(),
                                            strokeWidth: 3.0,
                                            color: Colors.black,
                                          ),
                                        ],
                                      ),
                                      MarkerLayer(
                                        markers: [
                                          Marker(
                                            width: 80.0,
                                            height: 80.0,
                                            point: LatLng(location!.latitude,
                                                location!.longitude), // Example marker at Dubai, UAE
                                            child:Image(image: AssetImage("assets/arrow.png"))
                                          ),

                                          Marker(
                                              width: 80.0,
                                              height: 80.0,
                                              point: LatLng(
                                                  snapshot.data!.latitude,
                                                  snapshot.data!.longitude),
                                              child: StreamBuilder(
                                                  stream: connectionControll
                                                      .ValuesController.stream,
                                                  builder: (context, snapshot) {
                                                    if (snapshot.hasData) {
                                                      return Transform.rotate(
                                                        angle:
                                                            snapshot.data![2] *
                                                                (pi / 180),
                                                        child: Icon(
                                                          Icons
                                                              .circle,
                                                          size: width * 0.08,
                                                          color:
                                                              Colors.blue,
                                                        ),
                                                      );
                                                    } else {
                                                      return Icon(
                                                        Icons
                                                            .circle,
                                                        size: width * 0.08,
                                                        color: Colors.blue,
                                                      );
                                                    }
                                                  })),

                                          // Add more markers here
                                        ],
                                      ),
                                    ],
                                  );
                                } else {
                                  return Stack(
                                    children: [
                                      // PolylineLayer(
                                      //   polylines: [
                                      //     Polyline(
                                      //       points: [
                                      //         LatLng(originLat, originLng),
                                      //         LatLng(snapshot.data!.latitude, snapshot.data!.longitude),
                                      //
                                      //       ],
                                      //       pattern: const StrokePattern.dotted(),
                                      //       strokeWidth: 3.0,
                                      //       color: Colors.black,
                                      //     ),
                                      //   ],
                                      // ),

                                      MarkerLayer(
                                        markers: markers,
                                      ),
                                    ],
                                  );
                                }
                              });
                        }
                      } else {
                        return MarkerLayer(
                          markers: [
                            Marker(
                              width: 80.0,
                              height: 80.0,
                              point: LatLng(
                                  location!.latitude,
                                  location!
                                      .longitude), // Example marker at Dubai, UAE
                              child: const Icon(
                                Icons.not_listed_location,
                                color: Colors.blue,
                                size: 40.0,
                              ),
                            ),
                          ],
                        );
                      }
                    }),
              ]),
          // Container(
          //   width: width,
          //   height: height,
          //   color: Colors.blue,
          //   child: Center(
          //     child: GetBuilder<connectionController>(
          //       builder: (controller) {
          //         return Text(
          //           controller.isBluetoothOn == true
          //               ? "Bluetooth on"
          //               : "Bluetooth off",
          //           style: TextStyle(
          //               color: Colors.white,
          //               fontSize: 24), // Added style for visibility
          //         );
          //       },
          //     ),
          //   ),
          // ),
          Positioned(
            child: Container(
              width: width,
              height: height * 0.15,
              color: Colors.white,
            ),
          ),
          Positioned(
              top: height * 0.09,
              left: width * 0.63,
              child: GestureDetector(
                onTap: (){
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => downloadScreen(
                        country: _country,
                      )));
                },
                child: Row(
                  children: [
                    Text(
                      "Falcon",
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Tracker",
                      style: TextStyle(
                          color: Colors.red,
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              )),
          Positioned(
            top: height * 0.08,
            left: width * 0.05,
            child: GetBuilder<connectionController>(builder: (controller) {
              return Container(
                width: width * 0.13,
                height: width * 0.13,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: controller.RX_found == false
                      ? _animation.value ?? Colors.white
                      : Colors.greenAccent,
                ),
              );
            }),
          ),
          Positioned(
              top: height * 0.07,
              left: width * 0.09,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _controller.stop();
                    showDoneDialog(width, height);
                  });
                },
                child: Container(
                    width: width * 0.05,
                    child: Image(
                      image: AssetImage("assets/reciver.png"),
                    )),
              )),
        ],
      ),
    );
  }

  Future<void> getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        location = position;
        print(location?.latitude);
      });
      getCurrentCountry(location!);
    } catch (e) {}
  }

  Future<void> getCurrentCountry(Position position) async {
    try {
      // Get current location
      //Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      // Retrieve placemarks from coordinates
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        // Get the country from the first placemark
        String country = placemarks[0].country ?? "Unknown country";
        setState(() {
          _country = country;
        });
        if(await fileController.readCountryFile(country)==true){

        }else{
          showDownloded(MediaQuery.of(context).size.width,
              MediaQuery.of(context).size.height, country);
        }


        print('Country: $country'); // Print country to console
      } else {}
    } catch (e) {
      print(e);
      setState(() {
        _country = 'Error getting country: $e';
      });
    }
  }

  Future<void> showDownloded(double width, double height, String county) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Center(child: const Text('Offline Maps')),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Your current location is $county'),
                Text('Would you like to download this map'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('ok'),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => downloadScreen(
                          country: _country,
                        )));
              },
            ),
            TextButton(
              child: const Text('cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }



  Future<void> showDoneDialog(double width, double height) async {
    connectionControll.RX_found == false ? connectionControll.startScan() : ();
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Text('Connect to Wings'),
              IconButton(
                  onPressed: () {
                    connectionControll.startScan();
                  },
                  icon: Icon(Icons.restart_alt))
            ],
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Container(
                    width: width * 0.2,
                    height: height * 0.2,
                    // color: Colors.red,
                    child: Image(
                      image: AssetImage("assets/reciver.png"),
                      width: width * 0.07,
                      height: width * 0.07,
                    )),
                SizedBox(
                  height: height * 0.05,
                ),
                Container(
                  width: width * 0.2,
                  height: height * 0.2,
                  color: Colors.transparent,
                  child: GetBuilder<connectionController>(
                    builder: (controller) {
                      if (controller.isBluetoothOn == false) {
                        return const Text(
                          "Turn on bluetooth..",
                          style: TextStyle(
                              color: Colors.blueGrey,
                              fontSize: 18), // Added style for visibility
                        );
                      } else {
                        return ListView.builder(
                          itemCount: controller.foundDevices.length,
                          itemBuilder: (context, index) {
                            final device = controller.foundDevices[index];
                            return Card(
                              child: ListTile(
                                title: Text(device.name.isNotEmpty
                                    ? device.name
                                    : "Unknown"),
                                subtitle: Text(device.id),
                                trailing: controller.ConnectedId == device.id
                                    ? Icon(
                                        Icons.bluetooth_connected,
                                        color: Colors.greenAccent,
                                      )
                                    : Icon(
                                        Icons.bluetooth_disabled,
                                        color: Colors.black,
                                      ),
                                onTap: () {
                                  // controller.ble.discoverAllServices(device.id);

                                  print('clicked ${device.name}');
                                  print(
                                      'clicked service data ${device.serviceData}');
                                  print(
                                      'clicked manufacture data ${device.manufacturerData}');
                                  print('clicked rssi data ${device.rssi}');
                                  print(
                                      'clicked serviceUUID data ${device.serviceUuids}');

                                  if (controller.RX_found == false) {
                                    controller.connectToDevice(
                                        device.id, device);
                                  } else {
                                    controller.disconnect();
                                    _controller.forward();
                                  }

                                  setState(() {});
                                  Navigator.of(context).pop();
                                },
                              ),
                            );
                          },
                        );
                      }
                    },
                  ),
                ),

                // Text('Would you like to approve of this message?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('cancel'),
              onPressed: () {
                _controller.forward();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
  void markerAdd(double lat, double lng) {
    print("added data");
    markers.add(
      Marker(
        width: 30.0,
        height: 30.0,
        point: LatLng(lat, lng), // Example marker at Dubai, UAE
        child: const Icon(
          Icons.circle,
          color: Colors.redAccent,
          size: 10.0,
        ),
      ),
    );
  }
}
