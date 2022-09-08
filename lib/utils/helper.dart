import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:blue_demo/models/BlueModel.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

const blueKey = "blueKey";
const showAPIKey = "showAPIKey";

Future<SharedPreferences> getSharedInstance() async {
  return await SharedPreferences.getInstance();
}

Future<String> getString() async {
  final prefs = await getSharedInstance();
  return prefs.getString(blueKey) ?? jsonEncode(List.empty());
}

Future<void> setString(String str) async {
  final prefs = await getSharedInstance();
  prefs.setString(blueKey, str);
}

//If we have string then convert it into list and return it otherwise return empty string
Future<List<BlueModel>> getBlueList() async {
  // await setString(blueModelToJson([]));
  List<BlueModel> data = blueModelFromJson(await getString());
  return data;
}

//In this we are checking that if we have list then add one more object to it and save it
// and then if we don't have then create new list and save it.
Future<void> setBlueModelData(BlueModel model) async {
  final data = jsonDecode(await getString());
  data.add(model.toJson());
  await setString(jsonEncode(data));
}

Future<void> addFirstIfNotAvailable(BlueModel model) async {
  List<BlueModel> list = blueModelFromJson(await getString());
  bool check = list.any((e) => e.id == model.id);
  if(check) {
    return;
  }else {
    list.add(model);
    await setString(blueModelToJson(list));
  }
}

// Means we are removing the element from the list to not show them
Future<void> setIsRemoved(String id) async {
  List<BlueModel> list = blueModelFromJson(await getString());
  int index = list.indexWhere((e) => e.id == id);
  list[index].isRemoved = true;
  await setString(blueModelToJson(list));
}

//Changing the name from the list so that it will sync the name from here to get the latest name
Future<void> changeNameOfModel(String id, String name) async {
  List<BlueModel> list = blueModelFromJson(await getString());
  int index = list.indexWhere((e) => e.id == id);
  list[index].name = name;
  await setString(blueModelToJson(list));
}

// Setting all devices visible, this function is triggered from the drawer
Future<void> setAllDevicesVisible() async {
  List<BlueModel> list = blueModelFromJson(await getString());
  list.map((e) => e.isRemoved = false).toList();
  await setString(blueModelToJson([]));
}

// GET LIST OF ID's WHICH YOU WANT TO SHOW ONLY
Future<List> loadData() async {
  String errMsg = "Error is: ";
  try {
    var response = await http.get(Uri.parse("http://10.0.2.2:3000/data"));
    return jsonDecode(response.body);
  } on TimeoutException catch (e) {
    errMsg += e.toString();
  } catch (e) {
    errMsg += e.toString();
  }
  Fluttertoast.showToast(msg: errMsg, toastLength: Toast.LENGTH_LONG);
  return [];
}

Future<bool> getAPIResponseBool() async {
  final prefs = await getSharedInstance();
  return prefs.getBool(showAPIKey) ?? true;
}

Future<void> setAPIBool() async {
  final prefs = await getSharedInstance();
  bool data = await getAPIResponseBool();
  data = !data;
  print("here is the data");
  print(data);
  await prefs.setBool(showAPIKey, data);
}