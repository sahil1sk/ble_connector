import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:blue_demo/BatteryLevel.dart';
import 'package:blue_demo/utils/helper.dart';
import 'package:blue_demo/models/BlueModel.dart';
import 'package:blue_demo/utils/widget_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:liquid_progress_indicator_ns/liquid_progress_indicator.dart';

import 'widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FlutterBlueApp());
}

class FlutterBlueApp extends StatelessWidget {
  const FlutterBlueApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      color: Colors.lightBlue,
      home: StreamBuilder<BluetoothState>(
          stream: FlutterBluePlus.instance.state,
          initialData: BluetoothState.unknown,
          builder: (c, snapshot) {
            final state = snapshot.data;
            if (state == BluetoothState.on) {
              return const LogoScreen();
            }
            return BluetoothOffScreen(state: state);
          }),
    );
  }
}

ButtonStyle bs() => ElevatedButton.styleFrom(
      primary: Colors.blue,
      onPrimary: Colors.white,
      minimumSize: const Size.fromHeight(50), // SETTING THE FULL SIZED BUTTON
    );

class LogoScreen extends StatefulWidget {
  const LogoScreen({Key? key}) : super(key: key);

  @override
  State<LogoScreen> createState() => _LogoScreenState();
}

class _LogoScreenState extends State<LogoScreen> {
  @override
  void initState() {
    super.initState();
    FlutterBluePlus.instance.startScan(timeout: const Duration(seconds: 4));

    Future.delayed(const Duration(seconds: 4), () {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => FindDevicesScreen(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset("assets/splashba.png"),
            // /*ElevatedButton(
            //   child: const Text("Search Devices"),
            //   style: ElevatedButton.styleFrom(
            //     primary: const Color.fromARGB(237, 5, 12, 83),
            //     onPrimary: Colors.white,
            //   ),
            //   onPressed: () {
            //
            //   },
            // */)
          ]),
    );
  }
}

class BluetoothOffScreen extends StatelessWidget {
  const BluetoothOffScreen({Key? key, this.state}) : super(key: key);

  final BluetoothState? state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.bluetooth_disabled,
              size: 200.0,
              color: Colors.white54,
            ),
            Text(
              'Bluetooth Adapter is ${state != null ? state.toString().substring(15) : 'not available'}.',
              style: Theme.of(context)
                  .primaryTextTheme
                  .subtitle2
                  ?.copyWith(color: Colors.white),
            ),
            ElevatedButton(
              child: const Text('TURN ON'),
              onPressed: Platform.isAndroid
                  ? () => FlutterBluePlus.instance.turnOn()
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class FindDevicesScreen extends StatefulWidget {
  FindDevicesScreen({Key? key}) : super(key: key);

  @override
  State<FindDevicesScreen> createState() => _FindDevicesScreenState();
}

class _FindDevicesScreenState extends State<FindDevicesScreen> {
  List<BlueModel> blueList = [];
  List data = [];
  bool isPairedDevices = false;
  bool includeAPIDATA = true;
  bool havingBatTest = false;
  bool loading = true;
  TextEditingController changeNameController = TextEditingController();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  String? selectedNotificationPayload;

  Future<void> _requestPermissions() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  List<String> notificationIds = [];

  @override
  void initState() {
    //Setting blue list from local data
    Future.delayed(const Duration(microseconds: 1), () async {
      await _requestPermissions();

      final NotificationAppLaunchDetails? notificationAppLaunchDetails =
          !kIsWeb && Platform.isLinux
              ? null
              : await flutterLocalNotificationsPlugin
                  .getNotificationAppLaunchDetails();

      // If someone lanuch app using notification
      String initialRoute = "/";
      if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
        selectedNotificationPayload = notificationAppLaunchDetails!.payload;
        initialRoute = "/";
      }

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      final IOSInitializationSettings initializationSettingsIOS =
          IOSInitializationSettings(
              requestAlertPermission: false,
              requestBadgePermission: false,
              requestSoundPermission: false,
              onDidReceiveLocalNotification: (
                int id,
                String? title,
                String? body,
                String? payload,
              ) async {});

      const MacOSInitializationSettings initializationSettingsMacOS =
          MacOSInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      final LinuxInitializationSettings initializationSettingsLinux =
          LinuxInitializationSettings(
        defaultActionName: 'Open notification',
        defaultIcon: AssetsLinuxIcon('icons/app_icon.png'),
      );

      final InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
        macOS: initializationSettingsMacOS,
        linux: initializationSettingsLinux,
      );

      // When any notification will be selected by the user, this callback will
      await flutterLocalNotificationsPlugin.initialize(initializationSettings,
          onSelectNotification: (String? payload) async {
        debugPrint("Notification payload selected ======");
        if (payload != null) {
          debugPrint('notification payload: $payload');
        }
        selectedNotificationPayload = payload;
      });

      blueList = await getBlueList();
      // data = await loadData();
      // print("data $data");
      includeAPIDATA = await getAPIResponseBool();
      loading = false;
      setState(() {});

      await setAPIBool();
      setState(() {
        includeAPIDATA = !includeAPIDATA;
      });
    });

    // FlutterBluePlus.instance.bondedDevices.asStream().listen((devices) {
    // devices.forEach((d) {
    //   debugPrint("devices");
    //   debugPrint(d.name);
    //
    //   try {
    //     d.services.listen((event) {
    //       event.forEach((service) {
    //         print(
    //             "====== HERE ARE SOME SERVICES ===== initstate");
    //         print(
    //             service.uuid.toString());
    //
    //         print(
    //             "inside services for each initstate");
    //
    //         service.characteristics
    //             .forEach((c) async {
    //
    //           c.value.listen((event) {
    //             print(
    //                 "Here is the event initState");
    //             print(event);
    //
    //             if (event.isNotEmpty) {
    //
    //               if(event[0] > 20 && !notificationIds.contains(d.id.toString())) {
    //                 notificationIds.add(d.id.toString());
    //                 _showNotification(device: d.name);
    //                 // and send the notification of battery low.
    //               } else {
    //                 if(notificationIds.contains(d.id.toString())) {
    //                   notificationIds.remove(d.id.toString());
    //                 }
    //               }
    //
    //               // setBatteryLevelById(
    //               //     d.id.toString(),
    //               //     event[0]
    //               //         .toString());
    //             }
    //           });
    //         });
    //       });
    //     });
    //
    //   } catch(e) {
    //     print("Error $e");
    //   }
    //
    //
    // });
    // });

    // Listen the devices to show notification
    Stream.periodic(const Duration(seconds: 600))
        .asyncMap((_) => FlutterBluePlus.instance.bondedDevices)
        .listen((devices) {
      devices.forEach((d) {
        debugPrint("devices");
        debugPrint(d.name);

        try {
          d.services.listen((event) {
            event.forEach((service) {
              print("====== HERE ARE SOME SERVICES ===== initState");
              print(service.uuid.toString());

              print("inside services for each initstate");

              if ('0x${service.uuid.toString().toUpperCase().substring(4, 8)}' ==
                  '0x180F') {
                service.characteristics.forEach((c) async {
                  c.read();
                  c.value.listen((event) {
                    print("Here is the event initState");
                    print(event);
                    print(notificationIds);

                    if (event.isNotEmpty) {
                      if (event[0] < 20 &&
                          !notificationIds.contains(d.id.toString())) {
                        notificationIds.add(d.id.toString());
                        _showNotification(
                            device: d.name, batteryLevel: event[0].toString());
                        // and send the notification of battery low.
                      } else {
                        if (notificationIds.contains(d.id.toString())) {
                          notificationIds.remove(d.id.toString());
                        }
                      }

                      // setBatteryLevelById(
                      //     d.id.toString(),
                      //     event[0]
                      //         .toString());
                    }
                  });
                });
              }
            });
          });
        } catch (e) {
          print("Error msg is here $e");
        }
      });
    });

    super.initState();
  }

  Future<void> _showNotification(
      {String device = "Battery Device", String batteryLevel = "20"}) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails('channelId', 'channelName',
            channelDescription: 'Notifications From Blue',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker');

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
        0,
        'Battery Low $device',
        'Battery Level is $batteryLevel%, Please connect your charger',
        platformChannelSpecifics,
        payload: 'data in payload');
  }

  void editNameDialog(String deviceId, String name) {
    changeNameController.text = name;
    AlertDialog alert = AlertDialog(
      title: const Text("Edit Name"),
      content: customTextField(
          controller: changeNameController,
          size: MediaQuery.of(context).size,
          onChange: (e) {}),
      actions: [
        ElevatedButton(
            child: const Text('DONE'),
            style: bs(),
            onPressed: () async {
              if (changeNameController.text.trim() != "" &&
                  changeNameController.text.trim().isNotEmpty) {
                int index = blueList.indexWhere((e) => e.id == deviceId);
                await changeNameOfModel(
                    deviceId,
                    changeNameController
                        .text); // Setting element in local db that it is removed now
                setState(() {
                  blueList.elementAt(index).name = changeNameController.text;
                });
              }

              Navigator.pop(context);
            })
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  List<Map<String, String>> batteries = [];

  String getBatteryLevelById(String id) {
    String level = "N/A";

    if (batteries.isNotEmpty) {
      for (int i = 0; i < batteries.length; i++) {
        if (batteries[i]["id"] == id) {
          print("INSIDE FOR LOOP IF 1");
          level = batteries[i]["level"] ?? "N/A";
        }
      }
    }
    return level;
  }

  bool checkIsHavingIdInBatteries(String id) {
    bool check = false;

    for (int i = 0; i < batteries.length; i++) {
      if (batteries[i]["id"] == id) {
        print("INSIDE FOR LOOP IF 2222");
        check = true;
      }
    }

    return check;
  }

  Widget getIconFromBatteryLevel(String id) {
    Widget widget = Container();
    if (getBatteryLevelById(id) == "N/A") {
      return widget;
    } else if (int.parse(getBatteryLevelById(id)) < 20) {
      return const Icon(Icons.battery_alert, color: Colors.red);
    } else {
      return const Icon(Icons.battery_full, color: Colors.green);
    }
  }

  void setBatteryLevelById(String id, String level) {
    if (batteries.isEmpty) {
      batteries.add({"id": id, "level": level});
      return;
    }

    bool havingId = false;

    for (int i = 0; i < batteries.length; i++) {
      if (batteries[i]["id"] == id) {
        print("INSIDE FOR LOOP IF 3333");
        havingId = true;
        batteries[i]["level"] = level;
      }
    }

    if (!havingId) {
      batteries.add({"id": id, "level": level});
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      // drawer: getDrawer(), // getting drawer
      appBar: AppBar(
        title: const Text('Bluetooth Demo'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.power_settings_new),
          onPressed: Platform.isAndroid
              ? () async {
                  batteries.clear();
                  await FlutterBluePlus.instance.turnOff();
                  Navigator.of(context).pop();
                }
              : null,
        ),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: () => FlutterBluePlus.instance
                  .startScan(timeout: const Duration(seconds: 4)),
              child: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    const SizedBox(height: 15),
                    // TO SHOW CONNECTED DEVICE DATA
                    // StreamBuilder<List<BluetoothDevice>>(
                    //   stream: Stream.periodic(const Duration(seconds: 2))
                    //       .asyncMap(
                    //           (_) => FlutterBluePlus.instance.connectedDevices),
                    //   initialData: const [],
                    //   builder: (c, snapshot) {
                    //     if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    //       return Column(
                    //         children: snapshot.data!.map((d) {
                    //           // Checking if the object is available in list if not available then add this into list
                    //           // and then also set into local DB
                    //           bool check = blueList.any((e) => e.id == d.id.id);
                    //           BlueModel model = BlueModel(
                    //               name: d.name, id: d.id.id, isRemoved: false);
                    //           if (check) {
                    //             model = blueList
                    //                 .where((e) => e.id == d.id.id)
                    //                 .single;
                    //           } else {
                    //             setBlueModelData(model);
                    //             blueList.add(model);
                    //           }
                    //
                    //
                    //           Widget widget = (model.isRemoved! ||
                    //               model.name != "BAT TEST")
                    //           //      Widget widget = (model.isRemoved!)
                    //               ? Container()
                    //               : Column(children: [
                    //             ListTile(
                    //               onTap: () async {
                    //                 print("tapping the data ........");
                    //                 try {
                    //                   if (!checkIsHavingIdInBatteries(
                    //                       d.id.toString())) {
                    //                     print("Data is here 000000");
                    //
                    //
                    //                     try {
                    //                       await d.connect();
                    //                     } catch(e) {
                    //                       print("Connect error $e");
                    //                     }
                    //
                    //
                    //
                    //                     print("Data is here 111111");
                    //                     try {
                    //                       await d.discoverServices();
                    //                     } catch (e) {
                    //                       print(
                    //                           "error discover services");
                    //                       print(e);
                    //                     }
                    //
                    //                     print("Data is here 22222");
                    //
                    //                     d.services.listen((event) {
                    //                       event.forEach((service) {
                    //                         print(
                    //                             "====== HERE ARE SOME SERVICES =====");
                    //                         print(
                    //                             service.uuid.toString());
                    //
                    //                         if ('0x${service.uuid.toString().toUpperCase().substring(4, 8)}' ==
                    //                             '0x180F') {
                    //                           print(
                    //                               "inside services for each");
                    //
                    //                           service.characteristics
                    //                               .forEach((c) async {
                    //                             c.read();
                    //                             c.value.listen((event) {
                    //                               print(
                    //                                   "Here is the event");
                    //                               print(event);
                    //
                    //                               if (event.isNotEmpty) {
                    //                                 setBatteryLevelById(
                    //                                     d.id.toString(),
                    //                                     event[0]
                    //                                         .toString());
                    //                               }
                    //                               print(
                    //                                   "battereis are here");
                    //                               print(batteries);
                    //                             });
                    //                           });
                    //                         }
                    //                       });
                    //                     });
                    //                   } else {
                    //                     print("in else tapping");
                    //                     print(batteries);
                    //                   }
                    //                 } catch (e) {
                    //                   print("here error is $e");
                    //                 }
                    //               },
                    //               title: Text(model.name!),
                    //               trailing:
                    //               StreamBuilder<BluetoothDeviceState>(
                    //                 stream: d.state,
                    //                 initialData:
                    //                 BluetoothDeviceState.disconnected,
                    //                 builder: (c, snapshot) {
                    //                   if (snapshot.data ==
                    //                       BluetoothDeviceState
                    //                           .connected) {
                    //                     d.discoverServices();
                    //
                    //                     return SizedBox(
                    //                       width: 70,
                    //                       height: 70,
                    //                       child: Row(
                    //                         crossAxisAlignment:
                    //                         CrossAxisAlignment.center,
                    //                         mainAxisAlignment:
                    //                         MainAxisAlignment
                    //                             .spaceBetween,
                    //                         children: [
                    //                           if (getBatteryLevelById(
                    //                               d.id.toString()) !=
                    //                               "N/A")
                    //                             Text(getBatteryLevelById(
                    //                                 d.id.toString()) +
                    //                                 "%"),
                    //                           getIconFromBatteryLevel(
                    //                               d.id.toString()),
                    //                           if (getBatteryLevelById(
                    //                               d.id.toString()) ==
                    //                               "N/A")
                    //                             const Icon(
                    //                                 Icons.touch_app,
                    //                                 color: Colors.blue),
                    //                         ],
                    //                       ),
                    //                     );
                    //                   }
                    //                   return const Icon(Icons.touch_app,
                    //                       color: Colors.blue);
                    //                   // return IconButton(
                    //                   //     onPressed: () async {
                    //                   //       await addFirstIfNotAvailable(
                    //                   //           model);
                    //                   //       editNameDialog(
                    //                   //           d.id.id, model.name!);
                    //                   //     },
                    //                   //     icon: const Icon(Icons.edit,
                    //                   //         color: Colors
                    //                   //             .blue)); // snapshot.data.toString()
                    //                 },
                    //               ),
                    //             ),
                    //             if (getBatteryLevelById(
                    //                 d.id.toString()) !=
                    //                 "N/A")
                    //               Padding(
                    //                 padding: const EdgeInsets.all(5),
                    //                 child: SizedBox(
                    //                   height: 7,
                    //                   child:
                    //                   LiquidLinearProgressIndicator(
                    //                     value: int.parse(
                    //                       getBatteryLevelById(
                    //                           d.id.toString()),
                    //                     ) /
                    //                         100,
                    //
                    //                     // Defaults to 0.5.
                    //                     valueColor:
                    //                     const AlwaysStoppedAnimation(
                    //                         Colors.green),
                    //                     // Defaults to the current Theme's accentColor.
                    //                     backgroundColor: Colors.white,
                    //                     // Defaults to the current Theme's backgroundColor.
                    //                     borderColor: const Color.fromARGB(
                    //                         100, 118, 196, 123),
                    //                     borderWidth: 1,
                    //                     direction: Axis.horizontal,
                    //                     // The direction the liquid moves (Axis.vertical = bottom to top, Axis.horizontal = left to right). Defaults to Axis.vertical.
                    //                     center: const Text(""),
                    //                     borderRadius: 0,
                    //                   ),
                    //                 ),
                    //               )
                    //           ]);
                    //
                    //           if (includeAPIDATA) {
                    //             // Checking if the element is removed now no need to show that element
                    //             return data.contains(model.id)
                    //                 ? widget
                    //                 : Container();
                    //           } else {
                    //             return widget;
                    //           }
                    //         }).toList(),
                    //       );
                    //     }
                    //     return const Center(
                    //         child: Text("NO CONNECTED DEVICES FOUND!!"));
                    //   },
                    // ),

                    // Show Scan results
//                     StreamBuilder<List<ScanResult>>(
//                         stream: FlutterBluePlus.instance.scanResults,
//                         initialData: const [],
//                         builder: (c, snapshot) {
//                           if (snapshot.hasData && snapshot.data!.isNotEmpty) {
//                             return Column(
//                               children: snapshot.data!.map(
//                                 (r) {
// // Checking if the object is available in list if not available then add this into list
// // and then also set into local DB
//                                   bool check = blueList
//                                       .any((e) => e.id == r.device.id.id);
//                                   BlueModel model = BlueModel(
//                                       name: r.device.name,
//                                       id: r.device.id.id,
//                                       isRemoved: false);
//                                   if (check) {
//                                     model = blueList
//                                         .where((e) => e.id == r.device.id.id)
//                                         .single;
//                                   } else {
//                                     setBlueModelData(model);
//                                     blueList.add(model);
//                                   }
//
//                                   Widget widget = (model.isRemoved! ||
//                                           model.name != "BAT TEST")
// // Widget widget = model.isRemoved!
//                                       ? Container()
//                                       : ScanResultTile(
//                                           deviceName: model.name!,
//                                           result: r,
//                                           edit: () async {
//                                             await addFirstIfNotAvailable(model);
//                                             editNameDialog(
//                                                 r.device.id.id, model.name!);
//                                           },
//                                           remove: () async {
//                                             await addFirstIfNotAvailable(model);
//                                             int index = blueList.indexWhere(
//                                                 (e) => e.id == r.device.id.id);
//                                             await setIsRemoved(r.device.id
//                                                 .id); // Setting element in local db that it is removed now
//                                             setState(() {
//                                               blueList
//                                                   .elementAt(index)
//                                                   .isRemoved = true;
//                                             });
//                                           },
//                                           onTap: () {
//                                             Navigator.of(context).push(
//                                               MaterialPageRoute(
//                                                   builder: (context) {
//                                                 r.device.connect();
//                                                 return DeviceScreen(
//                                                     device: r.device,
//                                                     deviceName: model.name);
//                                               }),
//                                             );
//                                           },
//                                         );
//
//                                   if (includeAPIDATA) {
// // Checking if the element is removed now no need to show that element
//                                     return data.contains(model.id)
//                                         ? widget
//                                         : Container();
//                                   } else {
//                                     return widget;
//                                   }
//                                 },
//                               ).toList(),
//                             );
//                           }
//                           return const Center(
//                               child: Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text(
//                                 "NO CONNECTABLE DEVICES FOUND - PRESS SCAN BUTTON !!"),
//                           ));
//                         }),

                    // TO SHOW BONDED OR PAIRED DEVICE DATA
                    StreamBuilder<List<BluetoothDevice>>(
                      stream: Stream.periodic(const Duration(seconds: 2))
                          .asyncMap(
                              (_) => FlutterBluePlus.instance.bondedDevices),
                      initialData: const [],
                      builder: (c, snapshot) {
                        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                          return Column(
                            children: snapshot.data!.map((d) {
                              // Checking if the object is available in list if not available then add this into list
                              // and then also set into local DB
                              bool check = blueList.any((e) => e.id == d.id.id);
                              BlueModel model = BlueModel(
                                  name: d.name, id: d.id.id, isRemoved: false);
                              if (check) {
                                model = blueList
                                    .where((e) => e.id == d.id.id)
                                    .single;
                              } else {
                                setBlueModelData(model);
                                blueList.add(model);
                              }

                              // print("Here we are having the services data 22222");
                              // d.connect().then((value) {
                              //   d.discoverServices().then((value) {
                              //
                              //     // getting services and there data
                              //     d.services.listen((servicesList) {
                              //       print("Here all the services list ================ 22");
                              //       List<BluetoothService> sl = servicesList;
                              //       sl.forEach((service) {
                              //         print("============= INSIDE FOR EACH =========== 22");
                              //
                              //         if ('0x${service.uuid.toString().toUpperCase().substring(4, 8)}' ==
                              //             '0x180F') {
                              //           service.characteristics.forEach((c) async {
                              //
                              //
                              //             c.value.listen((event) {
                              //               print("Here is the event ======== 2222");
                              //               print(event);
                              //               if(event.isNotEmpty) {
                              //                 //batteryLevelIs = event[0];
                              //               }
                              //
                              //             });
                              //
                              //             // final val = await c.read();
                              //             // if ('0x${c.uuid.toString().toUpperCase().substring(4, 8)}' ==
                              //             //     '0x2A19') {
                              //             //   final batteryLevel = await c.value.toList();
                              //             //   Fluttertoast.showToast(
                              //             //       msg: "Battery Level taken $batteryLevel");
                              //             //   batteryLevelIs = batteryLevel[0][0];
                              //             // }
                              //           });
                              //         }
                              //       });
                              //     });
                              //   });
                              //
                              // });

                              // Widget widget = (model.isRemoved! ||
                              //         model.name != "BAT TEST")
                              // Widget widget = (model.isRemoved!) ? Container() :

                              Widget widget = (model.name != "BAT TEST") ? Container() : Column(children: [
                                ListTile(
                                  onTap: () async {
                                    print("tapping the data ........");
                                    try {
                                      if (!checkIsHavingIdInBatteries(
                                          d.id.toString())) {
                                        print("Data is here 000000");

                                        try {
                                          await d.connect().timeout(
                                              const Duration(seconds: 5),
                                              onTimeout: () {
                                            Fluttertoast.showToast(
                                                msg:
                                                    "Not able to connect ${d.name}");
                                          });
                                        } catch (e) {
                                          print("Connect error $e");
                                        }

                                        print("Data is here 111111");
                                        try {
                                          await d.discoverServices();
                                        } catch (e) {
                                          print("error discover services");
                                          print(e);
                                        }

                                        print("Data is here 22222");

                                        d.services.listen((event) {
                                          event.forEach((service) {
                                            print(
                                                "====== HERE ARE SOME SERVICES =====");
                                            print(service.uuid.toString());

                                            if ('0x${service.uuid.toString().toUpperCase().substring(4, 8)}' ==
                                                '0x180F') {
                                              print("inside services for each");

                                              service.characteristics
                                                  .forEach((c) async {
                                                c.read();
                                                c.value.listen((event) {
                                                  print("Here is the event");
                                                  print(event);

                                                  if (event.isNotEmpty) {
                                                    setBatteryLevelById(
                                                        d.id.toString(),
                                                        event[0].toString());
                                                  }
                                                  print("battereis are here");
                                                  print(batteries);
                                                });
                                              });
                                            }
                                          });
                                        });
                                      } else {
                                        print("in else tapping");
                                        print(batteries);
                                      }
                                    } catch (e) {
                                      print("here error is $e");
                                    }
                                  },
                                  title: Text(model.name!),
                                  trailing: StreamBuilder<BluetoothDeviceState>(
                                    stream: d.state,
                                    initialData:
                                        BluetoothDeviceState.disconnected,
                                    builder: (c, snapshot) {
                                      if (snapshot.data ==
                                          BluetoothDeviceState.connected) {
                                        d.discoverServices();

                                        return SizedBox(
                                          width: 70,
                                          height: 70,
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              if (getBatteryLevelById(
                                                      d.id.toString()) !=
                                                  "N/A")
                                                Text(getBatteryLevelById(
                                                        d.id.toString()) +
                                                    "%"),
                                              getIconFromBatteryLevel(
                                                  d.id.toString()),
                                              if (getBatteryLevelById(
                                                      d.id.toString()) ==
                                                  "N/A")
                                                const Icon(Icons.touch_app,
                                                    color: Colors.blue),
                                            ],
                                          ),
                                        );
                                      }
                                      return const Icon(Icons.touch_app,
                                          color: Colors.blue);
                                      // return IconButton(
                                      //     onPressed: () async {
                                      //       await addFirstIfNotAvailable(
                                      //           model);
                                      //       editNameDialog(
                                      //           d.id.id, model.name!);
                                      //     },
                                      //     icon: const Icon(Icons.edit,
                                      //         color: Colors
                                      //             .blue)); // snapshot.data.toString()
                                    },
                                  ),
                                ),
                                if (getBatteryLevelById(d.id.toString()) !=
                                    "N/A")
                                  Padding(
                                    padding: const EdgeInsets.all(5),
                                    child: SizedBox(
                                      height: 7,
                                      child: LiquidLinearProgressIndicator(
                                        value: int.parse(
                                              getBatteryLevelById(
                                                  d.id.toString()),
                                            ) /
                                            100,

                                        // Defaults to 0.5.
                                        valueColor:
                                            const AlwaysStoppedAnimation(
                                                Colors.green),
                                        // Defaults to the current Theme's accentColor.
                                        backgroundColor: Colors.white,
                                        // Defaults to the current Theme's backgroundColor.
                                        borderColor: const Color.fromARGB(
                                            100, 118, 196, 123),
                                        borderWidth: 1,
                                        direction: Axis.horizontal,
                                        // The direction the liquid moves (Axis.vertical = bottom to top, Axis.horizontal = left to right). Defaults to Axis.vertical.
                                        center: const Text(""),
                                        borderRadius: 0,
                                      ),
                                    ),
                                  )
                              ]);

                              // if (includeAPIDATA) {
                              //   // Checking if the element is removed now no need to show that element
                              //   return data.contains(model.id)
                              //       ? widget
                              //       : Container();
                              // } else {
                              return widget;
                              // }
                            }).toList(),
                          );
                        }
                        return const Center(
                            child: Text("NO CONNECTED DEVICES FOUND!!"));
                      },
                    ),
                  ],
                ),
              ),
            ),
      floatingActionButton: StreamBuilder<bool>(
        stream: FlutterBluePlus.instance.isScanning,
        initialData: false,
        builder: (c, snapshot) {
          if (snapshot.data!) {
            return FloatingActionButton(
              child: const Icon(Icons.stop),
              onPressed: () => FlutterBluePlus.instance.stopScan(),
              backgroundColor: Colors.red,
            );
          } else {
            return FloatingActionButton(
                child: const Icon(Icons.refresh),
                onPressed: () => FlutterBluePlus.instance
                    .startScan(timeout: const Duration(seconds: 4)));
          }
        },
      ),
    );
  }

  Drawer getDrawer() {
    return Drawer(
      child: Container(
        margin:
            EdgeInsets.fromLTRB(0, MediaQuery.of(context).padding.top, 0, 0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  ElevatedButton(
                    child: const Text('TURN OFF'),
                    style: bs(),
                    onPressed: Platform.isAndroid
                        ? () async {
                            await FlutterBluePlus.instance.turnOff();
                            Navigator.of(context).pop();
                            Navigator.of(context).pop();
                          }
                        : null,
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    child: const Text('PAIRED DEVICES'),
                    style: bs(),
                    onPressed: () {
                      setState(() {
                        isPairedDevices = true;
                      });
                      Fluttertoast.showToast(msg: "PAIRED DEVICES AVAILABLE");
                    },
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    child: const Text('CONNECTABLE DEVICES'),
                    style: bs(),
                    onPressed: () {
                      setState(() {
                        isPairedDevices = false;
                      });
                      Fluttertoast.showToast(
                          msg: "CONNECTABLE DEVICES AVAILABLE");
                    },
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    child: const Text('SHOW REMOVED DEVICES'),
                    style: bs(),
                    onPressed: () async {
                      blueList.map((e) => e.isRemoved = false).toList();
                      await setAllDevicesVisible();
                      setState(() {});
                      Fluttertoast.showToast(msg: "ALL DEVICES VISIBLE");
                    },
                  ),
                  // const SizedBox(height: 15),
                  // ElevatedButton(
                  //   child: Text(includeAPIDATA
                  //       ? "SHOW ALL ID's"
                  //       : "SHOW API ID's ONLY"),
                  //   style: bs(),
                  //   onPressed: () async {
                  //     await setAPIBool();
                  //     setState(() {
                  //       includeAPIDATA = !includeAPIDATA;
                  //     });
                  //     Fluttertoast.showToast(
                  //         msg: includeAPIDATA
                  //             ? "AVAILABLE API ID's ONLY"
                  //             : "AVAILABLE ALL ID's");
                  //   },
                  // ),
                  const SizedBox(height: 25),
                  //Showing simple note
                  const Text(
                    "Note: Only paired devices will be showing here if not paired, then paired from your settings.",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DeviceScreen extends StatefulWidget {
  const DeviceScreen(
      {Key? key, required this.device, this.deviceName, this.scanResult})
      : super(key: key);

  final BluetoothDevice device;
  final ScanResult? scanResult;
  final String? deviceName;

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  List<int> _getRandomBytes() {
    final math = Random();
    return [
      math.nextInt(255),
      math.nextInt(255),
      math.nextInt(255),
      math.nextInt(255)
    ];
  }

  int batteryLevelIs = 25;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      try {
        widget.device.discoverServices();

        // List<BluetoothService> services = widget.device.services;
        widget.device.services.listen((servicesList) {
          List<BluetoothService> sl = servicesList;
          sl.forEach((service) {
            if ('0x${service.uuid.toString().toUpperCase().substring(4, 8)}' ==
                '0x180F') {
              service.characteristics.forEach((c) async {
                c.value.listen((event) {
                  print("Here is the event");
                  print(event);
                  if (event.isNotEmpty) {
                    batteryLevelIs = event[0];
                  }
                });

                // final val = await c.read();
                // if ('0x${c.uuid.toString().toUpperCase().substring(4, 8)}' ==
                //     '0x2A19') {
                //   final batteryLevel = await c.value.toList();
                //   Fluttertoast.showToast(
                //       msg: "Battery Level taken $batteryLevel");
                //   batteryLevelIs = batteryLevel[0][0];
                // }
              });
            }
          });
        });

        // services.map((s) {
        //   print('Service found: ${s.uuid}');
        //   s.characteristics.forEach((characteristic) {
        //     print(
        //         'Characteristic found: ${characteristic.uuid} ${characteristic.properties}');
        //   });
        // });
      } catch (e) {
        print("Here is the error");
        print(e);
      }
    });
  }

  List<Widget> _buildServiceTiles(List<BluetoothService> services) {
    return services
        .map(
          (s) => ServiceTile(
            service: s,
            characteristicTiles: s.characteristics
                .map(
                  (c) => CharacteristicTile(
                    characteristic: c,
                    onReadPressed: () async {
                      Fluttertoast.showToast(msg: "READING DATA PRESSED");
                      final val = await c.read();
                      // Fluttertoast.showToast(
                      //     msg: "READING DATA PRESSED ${val.toString()}");
                    },
                    onWritePressed: () async {
                      Fluttertoast.showToast(msg: "WRITING DATA PRESSED");
                      final val1 = await c.write(_getRandomBytes(),
                          withoutResponse: true);
                      final val2 = await c.read();
                      Fluttertoast.showToast(
                          msg:
                              "WRITING DATA PRESSED ${val1.toString()} ${val2.toString()}");
                    },
                    onNotificationPressed: () async {
                      Fluttertoast.showToast(msg: "NOTIFICATION PRESSED");
                      final val1 = await c.setNotifyValue(!c.isNotifying);
                      final val2 = await c.read();
                      Fluttertoast.showToast(
                          msg:
                              "NOTIFICATION PRESSED ${val1.toString()} ${val2.toString()}");
                    },
                    descriptorTiles: c.descriptors
                        .map(
                          (d) => DescriptorTile(
                            descriptor: d,
                            onReadPressed: () async {
                              Fluttertoast.showToast(
                                  msg: "DESCRIPTOR READING PRESSED");
                              final val1 = await d.read();
                              Fluttertoast.showToast(
                                  msg:
                                      "DESCRIPTOR READING PRESSED ${val1.toString()}");
                            },
                            onWritePressed: () async {
                              Fluttertoast.showToast(
                                  msg: "DESCRIPTOR WRITING PRESSED");
                              final val = await d.write(_getRandomBytes());
                              Fluttertoast.showToast(
                                  msg:
                                      "DESCRIPTOR WRITING PRESSED ${val.toString()}");
                            },
                          ),
                        )
                        .toList(),
                  ),
                )
                .toList(),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.deviceName ?? widget.device.name),
        actions: <Widget>[
          StreamBuilder<BluetoothDeviceState>(
            stream: widget.device.state,
            initialData: BluetoothDeviceState.connecting,
            builder: (c, snapshot) {
              VoidCallback? onPressed;
              String text;
              switch (snapshot.data) {
                case BluetoothDeviceState.connected:
                  onPressed = () => widget.device.disconnect();
                  text = 'DISCONNECT';
                  break;
                case BluetoothDeviceState.disconnected:
                  onPressed = () => widget.device.connect();
                  text = 'CONNECT';
                  break;
                default:
                  onPressed = null;
                  text = snapshot.data.toString().substring(21).toUpperCase();
                  break;
              }
              return TextButton(
                  onPressed: onPressed,
                  child: Text(
                    text,
                    style: Theme.of(context)
                        .primaryTextTheme
                        .button
                        ?.copyWith(color: Colors.white),
                  ));
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            StreamBuilder<BluetoothDeviceState>(
              stream: widget.device.state,
              initialData: BluetoothDeviceState.connecting,
              builder: (c, snapshot) => ListTile(
                leading: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    snapshot.data == BluetoothDeviceState.connected
                        ? const Icon(Icons.bluetooth_connected)
                        : const Icon(Icons.bluetooth_disabled),
                    snapshot.data == BluetoothDeviceState.connected
                        ? StreamBuilder<int>(
                            stream: rssiStream(),
                            builder: (context, snapshot) {
                              return Text(
                                  snapshot.hasData ? '${snapshot.data}dBm' : '',
                                  style: Theme.of(context).textTheme.caption);
                            })
                        : Text('', style: Theme.of(context).textTheme.caption),
                  ],
                ),
                title: Text(
                    'Device is ${snapshot.data.toString().split('.')[1]}.'),
                // subtitle: Text('${device.id}'),
                trailing: StreamBuilder<bool>(
                  stream: widget.device.isDiscoveringServices,
                  initialData: false,
                  builder: (c, snapshot) => IndexedStack(
                    index: snapshot.data! ? 1 : 0,
                    children: <Widget>[
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () => widget.device.discoverServices(),
                      ),
                      const IconButton(
                        icon: SizedBox(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(Colors.grey),
                          ),
                          width: 18.0,
                          height: 18.0,
                        ),
                        onPressed: null,
                      )
                    ],
                  ),
                ),
              ),
            ),
            StreamBuilder<int>(
              stream: widget.device.mtu,
              initialData: 0,
              builder: (c, snapshot) => ListTile(
                title: const Text('MTU Size'),
                subtitle: Text('${snapshot.data} bytes'),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => widget.device.requestMtu(223),
                ),
              ),
            ),

            StreamBuilder<List<BluetoothService>>(
              stream: widget.device.services,
              initialData: const [],
              builder: (c, snapshot) {
                if (snapshot != null && snapshot.data != null) {
                  return Column(
                    children: _buildServiceTiles(snapshot.data!),
                  );
                }
                return Container();
              },
            ),
            // if (widget.scanResult != null &&
            //     widget.scanResult!.advertisementData.txPowerLevel != null)
            //   LiquidLinearProgressIndicatorPage(
            //       value: widget.scanResult!.advertisementData.txPowerLevel! /
            //           100.00)
            StreamBuilder(
                stream: Stream.periodic(const Duration(seconds: 2))
                    .asyncMap((_) => batteryLevelIs),
                initialData: batteryLevelIs,
                builder: (c, snapshot) {
                  if (snapshot == null || snapshot.data == null) {
                    return Container();
                  } else if (snapshot != null && snapshot.data != null) {
                    return LiquidLinearProgressIndicatorPage(
                        value: ((snapshot.data as int) / 100));
                  }
                  return Container();
                }),
          ],
        ),
      ),
    );
  }

  Stream<int> rssiStream() async* {
    var isConnected = true;
    final subscription = widget.device.state.listen((state) {
      isConnected = state == BluetoothDeviceState.connected;
    });
    while (isConnected) {
      yield await widget.device.readRssi();
      await Future.delayed(Duration(seconds: 1));
    }
    subscription.cancel();
    // Device disconnected, stopping RSSI stream
  }
}
