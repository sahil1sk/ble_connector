// To parse this JSON data, do
//
//     final blueModel = blueModelFromJson(jsonString);

import 'dart:convert';

List<BlueModel> blueModelFromJson(String str) => List<BlueModel>.from(json.decode(str).map((x) => BlueModel.fromJson(x)));

String blueModelToJson(List<BlueModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class BlueModel {
  BlueModel({
    this.id,
    this.name,
    this.isRemoved,
    this.battery = "N/A"
  });

  String? id;
  String? name;
  bool? isRemoved;
  String? battery;

  factory BlueModel.fromJson(Map<String, dynamic> json) => BlueModel(
    id: json["id"],
    name: json["name"],
    isRemoved: json["isRemoved"],
    battery: json["battery"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "isRemoved": isRemoved,
    "battery": battery
  };
}
