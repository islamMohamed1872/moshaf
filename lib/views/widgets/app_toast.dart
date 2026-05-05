import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';

void showAppToast({
  required String message,
  required bool isError,
}) {
  Fluttertoast.showToast(
    msg: message,
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.BOTTOM,
    backgroundColor:
    isError ? Colors.red.shade700 : Colors.green.shade600,
    textColor: Colors.white,
    fontSize: 14,
  );
}