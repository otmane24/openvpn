// ignore: avoid_web_libraries_in_flutter
//import 'dart:html';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:http/http.dart' as http ;
import 'package:firebase_core/firebase_core.dart' as firebase_core;
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/material.dart';
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

  String _downLoadUrl ;
  firebase_storage.Reference _reference = firebase_storage.FirebaseStorage.instance.ref().child('norway.ovpn');

  Future downLoadServer () async {
    String downLoadAddress = await _reference.getDownloadURL();
    final http.Response  downLoadData = await http.get(downLoadAddress);
    final Directory systemTempDir = Directory.systemTemp;
    final File tempFile = File('${systemTempDir.path}/norway.ovpn');
    if (tempFile.existsSync()){
      await tempFile.delete();
    } await tempFile.create()
  }

  static Future<void> initPlatformState(String userName , String passWord) async {
    var contennt = await rootBundle.loadString('vpn/sweden.ovpn');
    await FlutterOpenvpn.lunchVpn(
      contennt,
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
    FlutterOpenvpn.init(
      localizedDescription: "ExampleVPN",
      providerBundleIdentifier:
      "com.topfreelancerdeveloper.flutterOpenvpnExample.RunnerExtension",
    ).then((value) {
      print(value);
      Fluttertoast.showToast(msg: value.toString(), textColor: Colors.blue);
    });
    FlutterVpn.prepare();
    FlutterVpn.onStateChanged.listen((s) => setState(() => state = s));
    super.initState();
  }
  var state = FlutterVpnState.disconnected;

  String valueSelected ;
  List listItem =[
    'Swadan' , 'Norway'
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin example app'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(15.0),
        children: <Widget>[
          Text('Current State: $state'),
          SizedBox(
            height: 20,
          ),
          Container(
            padding: EdgeInsets.only(left: 16,right: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey,width: 1),
              borderRadius: BorderRadius.circular(15)
            ),
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
                      value: valueItem,
                      child: Text(valueItem));
                }).toList(),
                onChanged: (newValue){
                  setState(() {
                    valueSelected = newValue ;
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
            obscureText: true,
            decoration: InputDecoration(icon: Icon(Icons.lock_outline)),
          ),
          SizedBox(
            height: 20,
          ),
          ElevatedButton(
              child: Text('Connect'),
              onPressed: () async{

                setState(() async{
                  initPlatformState(_usernameController.text,_passwordController.text);
                  var newState = await FlutterVpn.currentState;
                  setState(() => state = newState);

                });
              }
          ),
          SizedBox(
            height: 20,
          ),
          ElevatedButton(
              child: Text('Disconnect'),
              onPressed: () {
                setState(() async {
                  FlutterOpenvpn.stopVPN();
                  var newState = await FlutterVpn.currentState;
                  setState(() => state = newState);
                });
              }
          ),
          ElevatedButton(
              onPressed: (){
                setState(() {
                  downLoadServer();
                });
              },
              child: Text("DownLoad"))
        ],
      ),
    );
  }
}

