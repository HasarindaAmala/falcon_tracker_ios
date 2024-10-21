import 'dart:async';
import 'dart:io';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
//import 'package:latlong2/latlong.dart';
//import 'mapHistory.dart';

class FileHandling extends GetxController {

  String username = "";
  //List<LatLng> coordinates = [];
  //List<String> time_list = [];

  Future<String> localPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> localFile(String Dname,String Fname) async {
    final path = await localPath();
    final directory = Directory('$path/$Dname');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
      print("Directory created at ${directory.path}");
    }

    // Create the file within the folder
    final file = File('${directory.path}/$Fname.txt');
    print("File created $file");
    return file;

  }

  Future<String> readFile(String Dname,String Fname) async {

    try {
      //coordinates = [];
      //time_list = [];
      final file = await localFile(Dname,Fname);

      // Read the file
      final contents = await file.readAsString();


      final lines = contents.split('\n');
      for (var line in lines) {
        if (line.isNotEmpty) {
          final parts = line.split(',');
          // print(parts);
          if (parts.length >= 5) {

            final latitude = double.parse(parts[3]);
            final longitude = double.parse(parts[4]);
            final Time = "${parts[0]}-${parts[1]}-${parts[2]}";

            // Debugging: Print the timeString
            //print(Time);
            //coordinates.add(LatLng(latitude, longitude));
            //update();
            //time_list.add(Time);
            //update();


          }
        }
      }
      if (contents.trim().isEmpty) {
        return ""; // Indicate that the file is empty
      }else{
        print(contents);
      }

      return contents;
    } catch (e) {
      // If encountering an error, return 0
      return "";
    }
  }

  void setUserName(String name){
    username= name;
    update();
  }

  Future<File> writeLoginFile(String details,String Fname) async {
    final file = await localFile("users",Fname);

    // Write the file
    return file.writeAsString(details + '\n',mode: FileMode.append);
  }
  Future<File> writeCountryFile(String Fname) async {
    final file = await localFile("Country","Country");

    // Write the file

    return file.writeAsString(Fname + '\n',mode: FileMode.append);
  }
  Future<bool> readCountryFile(String Fname) async {
 bool exists = false;
    try {
      //coordinates = [];
      //time_list = [];
      final file = await localFile("Country","Country");

      // Read the file
      final contents = await file.readAsString();


      final lines = contents.split('\n');
      for (var line in lines) {
        if (line.isNotEmpty) {
         if(line == Fname){
           exists = true;
         }
         else{

         }
        }

      }

    } catch (e) {
      // If encountering an error, return 0
      return false;
    }
    return exists;
  }
  Future<Future<FileSystemEntity>> deleteCountryFile(String Fname) async {
    final file = await localFile("Country","Country");

    // delete the file
    return file.delete();
  }
  Future<File> writeRememberLoginFile(String details,String Fname) async {
    final file = await localFile("RememberUsers",Fname);

    // Write the file
    return file.writeAsString(details + '\n',mode: FileMode.append);
  }

  Future<bool> RememberExist() async{
    final path = await localPath();
    const Dname = "RememberUsers";
    final directory = Directory('$path/$Dname');

    if(await directory.exists()){
      return true;
    }else{
      return false;
    }
  }

  // Future<List<Widget>> listFiles(String Dname, BuildContext dialogContext) async {
  //   final path = await localPath();
  //   final directory = Directory('$path/$Dname');
  //
  //   if (await directory.exists()) {
  //     List<FileSystemEntity> entities = directory.listSync();
  //     List<Widget> fileNames = [];
  //
  //     for (FileSystemEntity entity in entities) {
  //       if (entity is File && entity.path.split('/').last != "$username.txt") {
  //         var name = entity.path.split('/').last;
  //         var content = await readFile(Dname, name.replaceRange(name.length-4, name.length, ""));
  //         if(content.trim().isNotEmpty){
  //           try {
  //             fileNames.add(ListTile(
  //
  //               onTap: () async {
  //                 Navigator.of(dialogContext, rootNavigator: true).pop();
  //                 await readFile(Dname,
  //                     name.replaceRange(name.length - 4, name.length, ""));
  //                 Navigator.push(dialogContext,
  //                     MaterialPageRoute(builder: (context) => MapHistory()));
  //               },
  //               title: Text(
  //                   name.replaceRange(name.length - 4, name.length, "")),
  //             ));
  //           }catch (e){
  //             print(e);
  //           }
  //         }
  //       }
  //     }
  //
  //     return fileNames;
  //   } else {
  //     print("Directory does not exist");
  //     return [];
  //   }
  // }


}