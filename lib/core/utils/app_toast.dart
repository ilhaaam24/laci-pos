import 'package:flutter/material.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:cherry_toast/resources/arrays.dart';

class AppToast {
  static void showSuccess(BuildContext context, String message) {
    CherryToast.success(
      title: Text(
        message,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      displayCloseButton: false,
      shadowColor: Colors.transparent,
      animationType: AnimationType.fromTop,
      toastDuration: const Duration(seconds: 3),
    ).show(context);
  }

  static void showError(BuildContext context, String message) {
    CherryToast.error(
      title: Text(
        message,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      displayCloseButton: false,
      shadowColor: Colors.transparent,
      animationType: AnimationType.fromTop,
      toastDuration: const Duration(seconds: 3),
    ).show(context);
  }

  static void showWarning(BuildContext context, String message) {
    CherryToast.warning(
      title: Text(
        message,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      displayCloseButton: false,
      shadowColor: Colors.transparent,
      animationType: AnimationType.fromTop,
      toastDuration: const Duration(seconds: 3),
    ).show(context);
  }

  static void showInfo(BuildContext context, String message) {
    CherryToast.info(
      title: Text(
        message,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      displayCloseButton: false,
      shadowColor: Colors.transparent,
      animationType: AnimationType.fromTop,
      toastDuration: const Duration(seconds: 3),
    ).show(context);
  }
}
