import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import 'package:flutter_openvpn/flutter_openvpn.dart';
import 'package:flutter_vpn/flutter_vpn.dart';
import 'package:fluttertoast/fluttertoast.dart';

void main() {
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

  static Future<void> initPlatformState(String userName , String passWord) async {
    var contennt=await rootBundle.loadString('vpn/sweden.ovpn');
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

          TextFormField(
            controller: _usernameController,
            decoration: InputDecoration(icon: Icon(Icons.person_outline)),
          ),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(icon: Icon(Icons.lock_outline)),
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
        ],
      ),
    );
  }
}

