// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:flutter/material.dart';

import 'package:VRHuRoLab/UI/IMU.dart';
import 'package:VRHuRoLab/UI/bluetooth.dart';
import 'package:VRHuRoLab/UI/homepage.dart';
import 'package:VRHuRoLab/UI/camera_view.dart';

void logError(String code, String message) =>
    print('Error: $code\nError Message: $message');

String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();

class VRCameraApp extends StatelessWidget {
  const VRCameraApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VR HuRoLab',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const BluetoothScreen(Homepage(CameraScreen: CameraScreen(),)),
    );
  }
}













