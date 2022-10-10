import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart' as fblue;

Uint8List hexToUint8List(String hex) {
  if (!(hex is String)) {
    throw 'Expected string containing hex digits';
  }
  if (hex.length % 2 != 0) {
    throw 'Odd number of hex digits';
  }
  var l = hex.length ~/ 2;
  var result = new Uint8List(l);
  for (var i = 0; i < l; ++i) {
    var x = int.parse(hex.substring(i * 2, (2 * (i + 1))), radix: 16);
    if (x.isNaN) {
      throw 'Expected hex string';
    }
    result[i] = x;
  }
  return result;
}

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'BLE Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: MyHomePage(title: 'Flutter BLE Demo'),
      );
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;
  final FlutterBlue flutterBlue = FlutterBlue.instance;
  final List<BluetoothDevice> devicesList = new List<BluetoothDevice>();
  final Map<Guid, List<int>> readValues = new Map<Guid, List<int>>();

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  BluetoothCharacteristic bCharacteristic = null;
  final _writeController = TextEditingController();
  BluetoothDevice _connectedDevice;
  List<BluetoothService> _services;
  final flutterReactiveBle = fblue.FlutterReactiveBle();
  var serviceWrite;
  _addDeviceTolist(final BluetoothDevice device) {
    if (!widget.devicesList.contains(device)) {
      setState(() {
        widget.devicesList.add(device);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    widget.flutterBlue.connectedDevices
        .asStream()
        .listen((List<BluetoothDevice> devices) {
      for (BluetoothDevice device in devices) {
        _addDeviceTolist(device);
      }
    });
    widget.flutterBlue.scanResults.listen((List<ScanResult> results) {
      for (ScanResult result in results) {
        _addDeviceTolist(result.device);
      }
    });
    widget.flutterBlue.startScan();
  }

  ListView _buildListViewOfDevices() {
    List<Container> containers = new List<Container>();
    for (BluetoothDevice device in widget.devicesList) {
      containers.add(
        Container(
          height: 50,
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  children: <Widget>[
                    Text(device.name == '' ? '(unknown device)' : device.name),
                    Text(device.id.toString()),
                  ],
                ),
              ),
              FlatButton(
                color: Colors.blue,
                child: Text(
                  'Connect',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () async {
                  widget.flutterBlue.stopScan();
                  try {
                    await device.connect();
                  } catch (e) {
                    if (e.code != 'already_connected') {
                      throw e;
                    }
                  } finally {
                    _services = await device.discoverServices();
                  }
                  setState(() {
                    _connectedDevice = device;
                  });
                },
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(8),
      children: <Widget>[
        ...containers,
      ],
    );
  }

  List<ButtonTheme> _buildReadWriteNotifyButton(
      BluetoothCharacteristic characteristic) {
    List<ButtonTheme> buttons = new List<ButtonTheme>();

    if (characteristic.properties.read) {
      buttons.add(
        ButtonTheme(
          minWidth: 10,
          height: 20,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: RaisedButton(
              color: Colors.blue,
              child: Text('READ', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                print("Check Read ${characteristic.properties.read}");
                var sub = characteristic.value.listen((value) {
                  setState(() {
                    widget.readValues[characteristic.uuid] = value;
                  });
                });
                await characteristic.read();
                sub.cancel();
              },
            ),
          ),
        ),
      );
    }
    if (characteristic.properties.write) {
      buttons.add(
        ButtonTheme(
          minWidth: 10,
          height: 20,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: RaisedButton(
              child: Text('WRITE', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text("Write"),
                        content: Row(
                          children: <Widget>[
                            Expanded(
                              child: TextField(
                                controller: _writeController,
                              ),
                            ),
                          ],
                        ),
                        actions: <Widget>[
                          FlatButton(
                            child: Text("Send"),
                            onPressed: () async {
                              //96d2bde0-07aa-e584-ec4e-b2c0c908d979
                              // print(
                              //     "Charac == ${fblue.CharacteristicValue().characteristic.characteristicId}");
                              // print(
                              //     "Charac == ${fblue.CharacteristicValue().characteristic.serviceId}");
                              // final characteristic =
                              //     fblue.QualifiedCharacteristic(
                              //         serviceId: 96d2bde0-07aa-e584-ec4e-b2c0c908d979,
                              //         characteristicId:
                              //             ,
                              //         deviceId: fblue.CharacteristicValue()
                              //             .characteristic
                              //             .deviceId);

                              // print(
                              //     "CHARAC == ${characteristic.uuid} ${characteristic.serviceUuid}");
                              // characteristic.setNotifyValue(true);
                              // print(
                              //     "Here is !isNotifying: ${!characteristic.isNotifying}");
                              // print(
                              //     "Here is characteristic.value: ${characteristic.value}");
                              // StringBuffer hex = StringBuffer();
                              // // for (int ch in asciiList) {
                              // //   hex.write(ch.toRadixString(16).padLeft(2, '0'));
                              // // }
                              // // print("HEX--${hex.toString()}");
                              // var asciiList = utf8.encode('00 4E 00');
                              //---------WRITE
                              //print("Character-> ${characteristic.uuid}");
                              var val = convertStringToUint8List(
                                  _writeController.value.text);
                              print(val);
                              List<String> inputList =
                                  _writeController.value.text.split(' ');
                              //'00 4E 00'.toString());
                              print("Inputlist-? $inputList");
                              final output = inputList
                                  .map((e) => int.parse(e, radix: 16))
                                  .toList();
                              debugPrint("output-> $output");
                              print(output.map(toHexString).toList());
                              var value = output.map(toHexString).toList();

                              List<int> numbers = value.map(int.parse).toList();
                              print("Numbers-> ${numbers}");
                              var getData = await characteristic.write(numbers,
                                  withoutResponse: false);
                              debugPrint("getData $getData");
                              var descriptors = characteristic.descriptors;
                              debugPrint("desc -- ${descriptors.length}");
                              // for (BluetoothDescriptor d in descriptors) {
                              //   List<int> value = await d.read();
                              //   print("Read Value $value from $d");
                              //   setState(() {
                              //     widget.readValues[characteristic.uuid] =
                              //         value;
                              //   });
                              // }
                              // var Dataa = (Uint8List.fromList([
                              //   0x01,
                              //   0x00,
                              //   0x4E,
                              //   0x01,
                              //   0x00,
                              // ]));
                              // print("dataa-> ${Dataa}");
                              // await characteristic.write(Uint8List.fromList([
                              //   0x01,
                              //   0x00,
                              //   0x4E,
                              //   0x01,
                              //   0x00,
                              // ]));

                              //----------READ
                              // print("Check ${characteristic.properties.read}");
                              // var res = readData(characteristic);
                              // print("res-> ${await res}");

                              // await characteristic.setNotifyValue(true);
                              bCharacteristic = characteristic;
                              readcharacteristickdata();
                              //var readvalue = await characteristic.read();
                              // await characteristic.setNotifyValue(true);
                              //characteristic.value.listen((value) {
                              //  print("readinfo -- $value");
                              // });

                              //debugPrint("readvalue-> $readvalue");
                              //---------------------------------
                              Navigator.pop(context);
                              // //-------------*****---READ---****
                              //var readvalue = await characteristic.read();
                              // print("read ->  $readvalue");
                              // if (characteristic.properties.read) {
                              //   List<int> value = await characteristic.read();
                              //   print("read -> $value");
                              //   var convert =
                              //       convertUint8ListToString(readvalue);
                              //   List<int> list = await readvalue;
                              //   print("read -> $list");
                              //   for (int i = 0; i < list.length; i++) {
                              //     print("read -> ${list[i]}");
                              //   }
                              //   ;
                              // }
                              // ;
                            },
                          ),
                          FlatButton(
                            child: Text("Cancel"),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      );
                    });
              },
            ),
          ),
        ),
      );
    }
    if (characteristic.properties.notify) {
      buttons.add(
        ButtonTheme(
          minWidth: 10,
          height: 20,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: RaisedButton(
              child: Text('NOTIFY', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                await characteristic.setNotifyValue(characteristic.isNotifying);
                characteristic.value.listen((event) {
                  print("Event -- $event");
                })
                  ..onError((error) {
                    // Cascade
                    debugPrint("ERROR -- $error");
                  })
                  ..onDone(() {
                    // Cascade
                    debugPrint("DONE");
                  })
                  ..onData((data) {
                    debugPrint("Data -- $data");
                  });
                bCharacteristic = characteristic;
                readcharacteristickdata();

                // print(
                //     "Check Notify ${characteristic.properties.notify}--${characteristic.uuid}");
                // // characteristic.value.listen((value) {
                //   print("Notify Char Value-> $value");
                // });\
                // var getReadData = await characteristic.read();
                // print("getReadData --- $getReadData");

                // Reads all descriptors
                // var descriptors = characteristic.descriptors;
                // for (BluetoothDescriptor d in descriptors) {
                //   List<int> value = await d.read();
                //   print("Read Value $value from $d");
                // }

                // await characteristic.setNotifyValue(true);
                // var getReadData = await characteristic.read();
                // print("getReadData --- $getReadData");
              },
            ),
          ),
        ),
      );
    }

    return buttons;
  }

  Uint8List convertStringToUint8List(String str) {
    final List<int> codeUnits = str.codeUnits;
    final Uint8List unit8List = Uint8List.fromList(codeUnits);

    return unit8List;
  }

  ListView _buildConnectDeviceView() {
    List<Container> containers = new List<Container>();

    for (BluetoothService service in _services) {
      List<Widget> characteristicsWidget = new List<Widget>();
      print("Characters -- ${service.uuid}");
      serviceWrite = service.uuid;

      for (BluetoothCharacteristic characteristic in service.characteristics) {
        characteristic.setNotifyValue(true);
        characteristicsWidget.add(
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(characteristic.uuid.toString(),
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                Row(
                  children: <Widget>[
                    ..._buildReadWriteNotifyButton(characteristic),
                  ],
                ),
                Row(
                  children: <Widget>[
                    Text('Value: ' +
                        widget.readValues[characteristic.uuid].toString()),
                  ],
                ),
                Divider(),
              ],
            ),
          ),
        );
      }
      containers.add(
        Container(
          child: ExpansionTile(
              title: Text(service.uuid.toString()),
              children: characteristicsWidget),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(8),
      children: <Widget>[
        ...containers,
      ],
    );
  }

  ListView _buildView() {
    if (_connectedDevice != null) {
      return _buildConnectDeviceView();
    }
    return _buildListViewOfDevices();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: _buildView(),
      );
  String convertUint8ListToString(Uint8List uint8list) {
    return String.fromCharCodes(uint8list);
  }

  Future<List<int>> readData(
      BluetoothCharacteristic targetCharacteristic) async {
    if (targetCharacteristic == null) {
      return null;
    }
    // List<int> value = await targetCharacteristic.read();
    // print("Valuee-> ${value}");
    return await targetCharacteristic.read();
  }

  Future<void> readcharacteristickdata() async {
    print("bCharacteristic - $bCharacteristic");
    if (bCharacteristic != null) {
      var data = await bCharacteristic.read();
      print("data-> $data");
      await Future.delayed(const Duration(seconds: 10));
      if (data.isEmpty) {
        readcharacteristickdata();
      }
    } else {
      bCharacteristic = null;
    }
  }

  // Uint8List convertStringToUint8List(String str) {
  //   final List<int> codeUnits = str.codeUnits;
  //   final Uint8List unit8List = Uint8List.fromList(codeUnits);
  //   return unit8List;
  String toHexString(int number) =>
      '0x${number.toRadixString(16).padLeft(2, '0')}';
}

//}
// var value = Uint8List.fromList(
//     [0x00, 0x3d, 0x04, 0x01, 0x02, 0x03, 0x04]);
