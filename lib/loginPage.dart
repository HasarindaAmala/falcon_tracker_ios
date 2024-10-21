import 'package:falcon_tracker/signUpScreen.dart';
import 'package:falcon_tracker/ConnectionScreen.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:get/get.dart';
import 'Controllers/FileHandlingController.dart';

class loginScreen extends StatefulWidget {
  const loginScreen({super.key});

  @override
  State<loginScreen> createState() => _loginScreenState();
}

class _loginScreenState extends State<loginScreen> {
  FileHandling fileController = Get.put(FileHandling());
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  List<String> data = [];
  @override
  void initState() {
    // TODO: implement initState

    super.initState();
  }
  Future<void> read() async{
    String details = await fileController.readFile("users",usernameController.text);
    final splitted = details?.split(",");
    data = splitted!;
    print(data);
  }
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          SizedBox(
            width: width*1.01,
            height: height,
            child: const Image(image: AssetImage("assets/loginScreen.png"),fit: BoxFit.fill,),
          ),
          Positioned(
              top: height * 0.388,
              left: width * 0.18,
              child: SizedBox(
                width: width * 0.6,
                child: TextFormField(
                  controller: usernameController,
                  style: TextStyle(
                      color: const Color(0xFF3C3C3C).withOpacity(0.73)),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    labelText: "User name",
                    labelStyle: TextStyle(
                      fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF3C3C3C).withOpacity(0.73)),
                  ),
                ),
              )),
          Positioned(
              top: height * 0.476,
              left: width * 0.18,
              child: SizedBox(
                width: width * 0.6,
                child: TextFormField(
                  obscureText: true,
                  controller: passwordController,
                  style: TextStyle(
                      color: const Color(0xFF3C3C3C).withOpacity(0.73)),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    labelText: "Password",
                    labelStyle: TextStyle(
                      fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF3C3C3C).withOpacity(0.73)),
                  ),
                  keyboardType: TextInputType.visiblePassword,
                ),
              )),
          Positioned(
            top: height*0.584,
            left: width*0.20,
            child: ElevatedButton(onPressed: () async{

              if(usernameController.text != "" && passwordController.text != ""){
                print("LOgIn");
                fileController.setUserName(usernameController.text);

               // print("splitted: $splitted");

                if(data.last == passwordController.text){
                  Navigator.pushReplacement(
                      context,
                      PageRouteBuilder(
                          transitionDuration: const Duration(milliseconds: 200),
                          pageBuilder: (context,animation,secondaryAnimation) => const connectionScreen(),
                          transitionsBuilder: (context,animation,secondaryAnimation,child){
                            return FadeTransition(
                              opacity: animation,
                              child: child,
                            );

                          }
                      )
                  );
                  //Navigator.push(context,MaterialPageRoute(builder: (context)=> FirstPage(size: widget.size ,totalTiles: widget.totalTiles,)));
                }else{
                  showErrorDialog();
                }
              }else{
                showErrorDialog();
              }









          }, child: Text(""),style: ElevatedButton.styleFrom(fixedSize: Size(width*0.65, height*0.06),backgroundColor: Colors.transparent),),
          ),
          Positioned(
            top: height * 0.655,
            left: width * 0.56,
            child: GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                    context,
                    PageRouteBuilder(
                        transitionDuration: const Duration(milliseconds: 200),
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            const signupScreen(),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        }));
              },
              child: Container(
                width: width * 0.14,
                height: height * 0.025,
                color: Colors.transparent,
              ),
            ),
          ),
        ],
      ),
    );
  }
  Future<void> showErrorDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Login Error'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text("Sorry try again"),
                // Text('Would you like to approve of this message?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('ok'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
