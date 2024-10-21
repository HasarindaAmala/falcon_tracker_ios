import 'dart:async';
import 'dart:math';
import 'package:falcon_tracker/ConnectionScreen.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:gif/gif.dart';
import 'package:country/country.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/geo/latlng_bounds.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:latlong2/latlong.dart';

import 'Controllers/FileHandlingController.dart';


LatLng north = LatLng(0.0, 0.0);
LatLng south = LatLng(0.0, 0.0);
late StreamController<double> progressController;

class downloadScreen extends StatefulWidget {

  String country;

   downloadScreen({super.key,required this.country});

  @override
  State<downloadScreen> createState() => _downloadScreenState();
}
double progressVal = 0.0;
class _downloadScreenState extends State<downloadScreen> with TickerProviderStateMixin{
  FileHandling fileController = Get.put(FileHandling());
  late GifController background;
  late GifController eagle;
  int minZoomLevel = 7;
  int maxZoomLevel = 14;
  bool download = false;
  double storeSize = 0;
  double estimatedSize = 0;


  @override
  void initState() {
    // TODO: implement initState
    progressController = StreamController<double>();
    background = GifController(vsync: this);
    eagle = GifController(vsync: this);
    initializeStore();
    estimatedSizeCalculate(widget.country, minZoomLevel, maxZoomLevel);
    super.initState();
  }
  @override
  void dispose() {
    // TODO: implement dispose
    background.dispose();
    eagle.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: width,
            height: height,
            child: Image(image: AssetImage("assets/downloading.png"),),
          ),
          Positioned(
            top: height*0.15,
            left: width*0,
            child: Gif(
              width: width,
              image: AssetImage("assets/downBack.gif"),
              controller: background,
              fps: 50,
              autostart: Autostart.loop,

              onFetchCompleted: (){
                background.reset();
                background.forward();
              },
            ),
          ),
          Positioned(
            top: height*0.53,
              left: width*0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(width: width*0.25,height: height*0.01,),
                      Text("Country: ${widget.country}",style: TextStyle(fontSize: width*0.04,fontWeight: FontWeight.bold),),
                    ],
                  ),
                  SizedBox(height: height*0.04,),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(width: width*0.08,),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text("Minimum Zoom"),
                          SizedBox(height: height*0.01,),
                          Row(
                            children: [

                              ElevatedButton(onPressed: (){
                                setState(()  {
                                  minZoomLevel++;
                                  estimatedSizeCalculate(widget.country,minZoomLevel,maxZoomLevel);
                                });
                              }, child: Text("+")),
                              SizedBox(width: width*0.04,),
                              Text("$minZoomLevel"),
                              SizedBox(width: width*0.04,),
                              ElevatedButton(onPressed: (){
                                setState(() {
                                  minZoomLevel--;
                                  estimatedSizeCalculate(widget.country,minZoomLevel,maxZoomLevel);
                                });
                              }, child: Text("-")),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(width: width*0.05,),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text("Maximum Zoom"),
                          SizedBox(height: height*0.01,),
                          Row(
                            children: [

                              ElevatedButton(onPressed: (){
                                setState(() {
                                  maxZoomLevel++;
                                   estimatedSizeCalculate(widget.country,minZoomLevel,maxZoomLevel);
                                });
                              }, child: Text("+")),
                              SizedBox(width: width*0.04,),
                              Text("$maxZoomLevel"),
                              SizedBox(width: width*0.04,),
                              ElevatedButton(onPressed: (){
                                setState(()  {
                                  maxZoomLevel--;
                                  estimatedSizeCalculate(widget.country,minZoomLevel,maxZoomLevel);
                                });
                              }, child: Text("-")),
                            ],
                          ),
                        ],
                      ),

                    ],
                  ),
                ],
              )),
          download==false?
          Positioned(
            top: height*0.75,
              left: width*0.4,
              child: ElevatedButton(onPressed: (){
            setState(() {
              download = true;
            });
            mapDownload(widget.country,minZoomLevel,maxZoomLevel);
          },style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent,foregroundColor: Colors.white), child: const Text("Download ")) ):Text(""),

          download == true?
          Positioned(
            top: height*0.8,
            left: width*0.1,
            child: StreamBuilder<double>(
              stream: progressController.stream,
              builder: (context, snapshot) {
                if(snapshot.data == 100.00){
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Download complete !",style: TextStyle(color: Colors.redAccent,fontSize: width*0.08),),
                      SizedBox(height: height*0.02,),
                      ElevatedButton(onPressed: (){
                        setState(() {
                          fileController.writeCountryFile(widget.country);
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => const connectionScreen()));
                        });
                      },style:ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                        fixedSize: Size(width*0.3, width*0.15),
                        iconColor: Colors.white,
                      ), child: const Icon(Icons.done_all,color: Colors.white,),)
                    ],
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Row(
                    children: [
                      SizedBox(width: width*0.4,),
                      SizedBox(
                          width: width*0.1,
                          height: width*0.1,
                          child: CircularProgressIndicator(
                            color: Colors.redAccent,
                          )),
                    ],
                  ); // Display a loading indicator when waiting for data.
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}'); // Display an error message if an error occurs.
                } else if (!snapshot.hasData) {
                  return Text('No data available'); // Display a message when no data is available.
                } else {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("${snapshot.data.toString()} %",style: TextStyle(
                        color: Colors.blueGrey,
                        fontSize: width*0.045,
                      ),),
                      SizedBox(
                        height: height*0.01,
                      ),
                      SizedBox(
                        width: width*0.8,
                        height: height*0.05,
                        child: LinearProgressIndicator(
                          semanticsValue: snapshot.data.toString(),
                          value: snapshot.data!/100,
                          color: Colors.redAccent,
                          backgroundColor: Colors.white54,
                          minHeight: height*0.05,
                        ),
                      ),
                    ],
                  ); // Display the latest number when data is available.
                }
              },
            ),
          ): Text(""),
          Positioned(
            top: height*0.15,
            left: width*0.3,
            child: Gif(
              width: width*0.5,
              image: AssetImage("assets/eagle.gif"),
              controller: eagle,
              fps: 60,
              autostart: Autostart.loop,

              onFetchCompleted: (){
                eagle.reset();
                eagle.forward();
              },
            ),
          ),

          Positioned(
            height: height*0.2,
              left: width*0.1,
              child: IconButton(onPressed: (){
            Navigator.of(context).pop();
          }, icon: Icon(Icons.arrow_back))),
          Positioned(
              top: height*0.09,
              left: width*0.55,
              child: Text("Total Size: ${storeSize.toStringAsFixed(2)} MB",style: TextStyle(),)),

          Positioned(
              top: height*0.7,
              left: width*0.32,
              child: Text("Estimated Size: ${estimatedSize.toStringAsFixed(2)} MB",style: TextStyle(),)),

          Positioned(
            top: height*0.075,
              left: width*0.875,
              child: IconButton(onPressed: (){
            reset();
            fileController.deleteCountryFile(widget.country);

          }, icon: const Icon(Icons.delete)))

        ],
      ),
    );
  }
  Future<void> initializeStore() async {
    try {
      const store = FMTCStore('mapStore');
      final mng =  store.manage;

      Future<bool> exist = mng.ready;
      bool result = await exist;
     // print(result);




      if (result==false) {
        // Store doesn't exist, create it
        await store.manage.create();
        // print("metadata: $metadata");
        print('Store created successfully.');
      } else {
        final metadata = await store.metadata.read;
        getSize();
        print('Store already exists with metadata: $metadata');
      }
    } catch (e) {
      print('Store creation failed: $e');

      // Handle store creation failure if needed
    }
  }
  Future<void> getSize() async{
    try {
      const store = FMTCStore('mapStore');
      final stats = store.stats;
      setState(() async {
        storeSize = await stats.size/1024;
      });

    } catch (e) {
      print('Reset failed: $e');
      // Handle store creation failure if needed
    }


  }
  Future<void> reset() async {
    try {
      const store = FMTCStore('mapStore');
      final mng =  store.manage;
      //final stats = store.stats;

      await mng.reset();
      print('Reset successfully:');
      getSize();
      setState(() {

      });

    } catch (e) {
      print('Reset failed: $e');
      // Handle store creation failure if needed
    }
  }
  Future<void> estimatedSizeCalculate(String country,int min, int max) async {

    if(country == "Sri Lanka"){

      north = LatLng(9.842957, 79.695423);
      south = LatLng(5.916396, 81.787602);


    }
    else if(country == "United States"){

      north = LatLng(49.384358, -125.000000);
      south = LatLng(24.396308, -66.934570);


    }
    else if(country == "United Kingdom"){

      north = LatLng(60.860916, -8.649357);
      south = LatLng(49.909613, 1.762709);


    }
    else if(country == "UAE") {
       north = LatLng(26.084159, 51.999672);
       south = LatLng(22.633329, 56.383331);

    }
    else if(country == "Gulf") {
       north = LatLng(30.240086, 48.570570);
       south = LatLng(24.000000, 56.370000);

    }


    else{

    }


   estimateDownloadSize(north: north,south: south,maxZoom: max,minZoom: min);

  }
  Future<void> estimateDownloadSize({
    required LatLng north,
    required LatLng south,
    required int minZoom,
    required int maxZoom,
    double tileSizeInMB = 0.00922, // Estimated size of a single tile in MB
  }) async {
    double totalSize = 0.0;

    for (int zoom = minZoom; zoom <= maxZoom; zoom++) {
      int xTiles = _calculateTilesAtZoom(north.longitude, south.longitude, zoom);
      int yTiles = _calculateTilesAtZoom(north.latitude, south.latitude, zoom);

      int totalTiles = xTiles * yTiles;
      double sizeForZoomLevel = totalTiles * tileSizeInMB;

      print('Zoom level: $zoom, Total tiles: $totalTiles, Estimated size: ${sizeForZoomLevel.toStringAsFixed(5)} MB');
      totalSize += sizeForZoomLevel;
    }

    print('Total estimated download size: ${totalSize.toStringAsFixed(2)} MB');
    setState(() {
      estimatedSize = totalSize;
    });


  }

  int _calculateTilesAtZoom(double min, double max, int zoom) {
    int numTiles = ((max - min) * (pow(2, zoom) / 360)).abs().ceil();
    return numTiles;
  }

}
void mapDownload(String country,int min, int max){
  StoreService str = StoreService();



  if(country == "Sri Lanka"){

    north = LatLng(9.842957, 79.695423);
    south = LatLng(5.916396, 81.787602);
    str.downloadTiles(maxZoom: max,minZoom: min,downloadForeground: true,north: north,south: south);

  }
  else if(country == "United States"){

    north = LatLng(49.384358, -125.000000);
    south = LatLng(24.396308, -66.934570);
    str.downloadTiles(maxZoom: max,minZoom: min,downloadForeground: true,north: north,south: south);

  }
  else if(country == "United Kingdom"){

    north = LatLng(60.860916, -8.649357);
    south = LatLng(49.909613, 1.762709);
    str.downloadTiles(maxZoom: max,minZoom: min,downloadForeground: true,north: north,south: south);

  }
  else if(country == "UAE") {
    LatLng north = LatLng(26.084159, 51.999672);
    LatLng south = LatLng(22.633329, 56.383331);
    str.downloadTiles(maxZoom: max, minZoom: min, downloadForeground: true, north: north, south: south);
  }
  else if(country == "Gulf") {
    LatLng north = LatLng(30.240086, 48.570570);
    LatLng south = LatLng(24.000000, 56.370000);
    str.downloadTiles(maxZoom: max, minZoom: min, downloadForeground: true, north: north, south: south);
  }


  else{

  }




}
class StoreService {
  final FMTCStore store = const FMTCStore("mapStore");
  Future<void> cancel()async {
    store.download.cancel();
  }
  Future<void> pause()async {
    print("paused");
    store.download.pause();
  }
  Future<void> resume()async {
    print("resume");
    store.download.resume();
  }
  Future<void> downloadTiles({
    required int minZoom,
    required int maxZoom,
    required bool downloadForeground,
    required LatLng north,
    required LatLng south,

  }) async {
    final northWest = north; // Example coordinates
    final southEast = south;

    final region = RectangleRegion(
      LatLngBounds(northWest, southEast), // North West coordinate
    );

    final downloadableRegion = region.toDownloadable(
      minZoom: minZoom,
      maxZoom: maxZoom,
      options: TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName: 'com.example.mapfinaltest',
      ),
    );




    // final LatLngBounds bounds = LatLngBounds(LatLng (37.7749, -122.4194), LatLng (37.7049, -122.3394));
    // final metadata = await store.metadata.read;
    //final region = RegionService().getBaseMapRegionFromCoordinates(bounds);

    // if (region == null) {
    //   throw Exception('Region could not be determined.');
    // }

    if (downloadForeground) {
      setDownloadProgress(
          store.download
              .startForeground(
            region: downloadableRegion,
            skipSeaTiles: false,
            skipExistingTiles: true,
            parallelThreads: 40,
          )
              .asBroadcastStream()
      );
    }

  }

  Future<void> setDownloadProgress(Stream<DownloadProgress> progressStream) async {
    double _percentage = 0.0;
    await for (var progress in progressStream){
      _percentage = progress.percentageProgress.toDouble();
      var rate = progress.tilesPerSecond;
      if(rate<70.00){
        pause();
        Future.delayed(const Duration(
          milliseconds: 500,
        ));
        resume();
      }
      progressVal = _percentage.roundToDouble();
      progressController.sink.add(progressVal);
      print('Download rate: ${rate.toStringAsFixed(2)}%');

    }
  }


}