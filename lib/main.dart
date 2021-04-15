import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import "package:http/http.dart" as http;
import 'package:firebase_core/firebase_core.dart' as firebase_core;
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter_openvpn/flutter_openvpn.dart';
import 'package:flutter_vpn/flutter_vpn.dart';
import 'package:fluttertoast/fluttertoast.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await firebase_core.Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  String valueSelected;
  ListResult list;
  List listItem = [];

  Future downLoadServer(String vpnSelected) async {
    Reference reference = firebase_storage.FirebaseStorage.instance
        .ref()
        .child('$vpnSelected.ovpn');
    String url = await reference.getDownloadURL();
    final http.Response downLoadData = await http.get(url);
    final Directory systemTempDir = Directory.systemTemp;
    final File tempFile = File('${systemTempDir.path}/$vpnSelected.ovpn');
    if (tempFile.existsSync()) {
      await tempFile.delete();
    }
    await tempFile.create();
    await tempFile.writeAsStringSync(downLoadData.body);
   // String name = reference.name;
   /* print(
        "name : $name\n list : ${list.items.asMap().values.elementAt(0).fullPath.replaceAllMapped(".ovpn", (match) => "")}")*/
    ;
  }

  static Future<void> initPlatformState(
      String userName, String passWord, String vpnSelected) async {
    final Directory systemTempDir = Directory.systemTemp;
    final File tempFile = File('${systemTempDir.path}/$vpnSelected.ovpn');
    var content = await tempFile.readAsStringSync();
    print('content: $content');
    await FlutterOpenvpn.lunchVpn(
      content,
      (isProfileLoaded) {
        print('isProfileLoaded : $isProfileLoaded');
      },
      (vpnActivated) {
        print('vpnActivated : $vpnActivated');
      },
      user: userName,
      pass: passWord,
      onConnectionStatusChanged:
          (duration, lastPacketRecieve, byteIn, byteOut) => print(byteIn),
      expireAt: DateTime.now().add(
        Duration(
          seconds: 180,
        ),
      ),
    );
  }

  @override
  void initState() {
    firebase_storage.FirebaseStorage.instance.ref().listAll().then((value) {
      setState(() {
        list = value;
        //print("index : ${list.items.length}");
        for (int index = 0; index < list.items.length; index++) {
          listItem.add(list.items
              .asMap()
              .values
              .elementAt(index)
              .fullPath
              .replaceAll(".ovpn", ""));
        }
        //print(listItem);
        for (String item in listItem) {
          downLoadServer(item);
        }
      });
    });

    FlutterOpenvpn.init(
      localizedDescription: "ExampleVPN",
      providerBundleIdentifier:
          "com.topfreelancerdeveloper.flutterOpenvpnExample.RunnerExtension",
    ).then((value) {
      print(value);
      //Fluttertoast.showToast(msg: value.toString(), textColor: Colors.blue);

      /////////////////////////////////////////
      // CircularProgressIndicator(
      //   value: value,
      // );
    });
    FlutterVpn.prepare();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin example app'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(15.0),
        children: <Widget>[
         // Text('Current State: '),
          SizedBox(
            height: 20,
          ),
          Container(
            padding: EdgeInsets.only(left: 16, right: 16),
            decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 1),
                borderRadius: BorderRadius.circular(15)),
            child: DropdownButton(
              hint: Text('Selectioner un serveur'),
              icon: Icon(Icons.wifi),
              isExpanded: true,
              iconSize: 32,
              style: TextStyle(
                color: Colors.black,
                fontSize: 22,
              ),
              value: valueSelected,
              items: listItem.map((valueItem) {
                return DropdownMenuItem(
                    value: valueItem, child: Text(valueItem));
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  valueSelected = newValue;
                  print("valueSelected: $valueSelected");
                });
              },
              // dropdownColor: Colors.red,
              //  onTap:(){} ,
            ),
          ),
          SizedBox(
            height: 20,
          ),
          TextFormField(
            controller: _usernameController,
            decoration: InputDecoration(icon: Icon(Icons.person_outline)),
          ),
          SizedBox(
            height: 20,
          ),
          TextFormField(
            controller: _passwordController,
            obscureText: false,
            decoration: InputDecoration(icon: Icon(Icons.lock_outline)),
          ),
          SizedBox(
            height: 20,
          ),
          ElevatedButton(
              child: Text('Connect'),
              onPressed: () => initPlatformState(_usernameController.text,
                  _passwordController.text, valueSelected)),
          SizedBox(
            height: 20,
          ),
          ElevatedButton(
              child: Text('Disconnect'),
              onPressed: () => FlutterOpenvpn.stopVPN()),
        ],
      ),
    );
  }
}

