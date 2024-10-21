import 'package:falcon_tracker/ConnectionScreen.dart';
import 'package:falcon_tracker/loginPage.dart';
import 'package:flutter/material.dart';
import 'package:gif/gif.dart';
import 'package:get/get.dart';
import 'Controllers/FileHandlingController.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await FMTCObjectBoxBackend().initialise();

    runApp(const homeScreen());
  } catch (e) {
    print('Initialization failed: $e');
    // Handle initialization failure if needed
  }


}


class homeScreen extends StatefulWidget {
  const homeScreen({super.key});

  @override
  State<homeScreen> createState() => _homeScreenState();
}

class _homeScreenState extends State<homeScreen> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: splashScreen(),
    );
  }
}
class splashScreen extends StatefulWidget {
  const splashScreen({super.key});

  @override
  State<splashScreen> createState() => _splashScreenState();
}

class _splashScreenState extends State<splashScreen> with TickerProviderStateMixin{
  late GifController splashController;
  FileHandling fileController = Get.put(FileHandling());
  bool exists = false;
  void checkDirectory() async {
     exists = await fileController.RememberExist();
    print(exists);
     if(exists == true){

       Future.delayed(const Duration(milliseconds: 2100),(){
         setState(() {

           //Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => loginScreen()));
           Navigator.pushReplacement(
               context,
               PageRouteBuilder(
                   transitionDuration: const Duration(milliseconds: 100),
                   pageBuilder: (context,animation,secondaryAnimation) => connectionScreen(),
                   transitionsBuilder: (context,animation,secondaryAnimation,child){
                     return FadeTransition(
                       opacity: animation,
                       child: child,
                     );

                   }
               )
           );


         });
       });
     }else{
       Future.delayed(const Duration(milliseconds: 2900),(){
         setState(() {

           //Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => loginScreen()));
           Navigator.pushReplacement(
               context,
               PageRouteBuilder(
                   transitionDuration: const Duration(milliseconds: 300),
                   pageBuilder: (context,animation,secondaryAnimation) => loginScreen(),
                   transitionsBuilder: (context,animation,secondaryAnimation,child){
                     return FadeTransition(
                       opacity: animation,
                       child: child,
                     );

                   }
               )
           );


         });
       });
     }
  }
  @override
  void initState() {
    // TODO: implement initState
    splashController = GifController(vsync: this);
    checkDirectory();



    super.initState();
  }
  @override
  void dispose() {
    // TODO: implement dispose
    splashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Container(
        width: width,
        height: height,
        color: Colors.white,
        child: Gif(
          fit: BoxFit.fill,
            width: width,
            height: height,
            image: AssetImage("assets/enhanced_splash.gif"),
          controller: splashController,
         fps: 40,
          autostart: Autostart.no,

          onFetchCompleted: (){
            splashController.reset();
            splashController.forward();
          },
        ),

      ),
    );
  }
}

