import 'package:falcon_tracker/loginPage.dart';
import 'package:flutter/material.dart';
//import 'package:path_provider/path_provider.dart';
import 'package:get/get.dart';

import 'Controllers/FileHandlingController.dart';

class signupScreen extends StatefulWidget {
  const signupScreen({super.key});

  @override
  State<signupScreen> createState() => _signupScreenState();
}

class _signupScreenState extends State<signupScreen> {
  FileHandling fileController = Get.put(FileHandling());
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final passwordConfirmController = TextEditingController();
  bool checkValue = false;
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          SizedBox(
            width: width,
            height: height,
            child: const Image(
              image: AssetImage("assets/signup1.png"),
              fit: BoxFit.fill,
            ),
          ),
          Positioned(
              top: height * 0.275,
              left: width * 0.15,
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
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF3C3C3C).withOpacity(0.73)),
                  ),
                ),
              )),
          Positioned(
              top: height * 0.362,
              left: width * 0.15,
              child: SizedBox(
                width: width * 0.6,
                child: TextFormField(
                  controller: passwordController,
                  style: TextStyle(
                      color: const Color(0xFF3C3C3C).withOpacity(0.73)),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    labelText: "Password",
                    labelStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF3C3C3C).withOpacity(0.73)),
                  ),
                ),
              )),
          Positioned(
              top: height * 0.45,
              left: width * 0.15,
              child: SizedBox(
                width: width * 0.6,
                child: TextFormField(
                  controller: passwordConfirmController,
                  style: TextStyle(
                      color: const Color(0xFF3C3C3C).withOpacity(0.73)),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    labelText: "Confirm Password",
                    labelStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF3C3C3C).withOpacity(0.73)),
                  ),
                  keyboardType: TextInputType.visiblePassword,
                ),
              )),
          Positioned(
              top: height * 0.05,
              left: width * 0.05,
              child: IconButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                        context,
                        PageRouteBuilder(
                            transitionDuration:
                                const Duration(milliseconds: 100),
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    const loginScreen(),
                            transitionsBuilder: (context, animation,
                                secondaryAnimation, child) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            }));
                  },
                  icon: Icon(
                    Icons.arrow_back,
                    size: width * 0.07,
                  ))),
          Positioned(
            top: height * 0.575,
            left: width * 0.18,
            child: ElevatedButton(
              onPressed: () {
                print("pressed");
                if (usernameController.text != '' &&
                    passwordController.text != '' &&
                    (passwordController.text ==
                        passwordConfirmController.text)) {

                  String details =
                      "${usernameController.text},${passwordController.text}";
                  // checkValue == true ? fileController.writeRememberLoginFile(details, usernameController.text):
                  // fileController.writeLoginFile(details,
                  //     usernameController.text);
                  if(checkValue==true){
                    fileController.writeRememberLoginFile(details, usernameController.text);
                    fileController.writeLoginFile(details, usernameController.text);
                  }else{
                    fileController.writeLoginFile(details, usernameController.text);
                  }
                  showDoneDialog();
                } else {
                  showErrorDialog();
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  elevation: 1.0,
                  fixedSize: Size(width * 0.64, height * 0.06)),
              child: const Text(""),
            ),
          ),
          Positioned(
              top: height * 0.51,
              left: width * 0.52,
              child: Row(
                children: [
                  Checkbox(
                    value: checkValue,
                    onChanged: (bool? value) {
                      setState(() {
                        checkValue = value ?? false; // Update state
                        print(checkValue);
                      });
                    },
                    activeColor: Colors.blueGrey,
                    checkColor: Colors.white,
                  ),
                  Text(
                    "Remember me",
                    style: TextStyle(
                        color: Color(0xFF3C3C3C).withOpacity(0.73),
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ))
        ],
      ),
    );
  }

  Future<void> showDoneDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sign up'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text("Account Created!"),
                // Text('Would you like to approve of this message?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Done'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> showErrorDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('SignUp Error'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text("Error!"),
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

void createUser(var username, var password) {}
