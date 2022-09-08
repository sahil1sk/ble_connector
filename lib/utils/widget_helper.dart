
import 'package:flutter/material.dart';

Widget customTextField({required TextEditingController controller, required Size size, required Function onChange}) {
  return Container(
    height: 50,
    width: size.width,
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius:  BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(10)),
    ),
    child: TextField(
      controller: controller,
      onChanged: (e) => onChange(e),
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        hintText: "Add New Name",
      ),
    ),
  );
}