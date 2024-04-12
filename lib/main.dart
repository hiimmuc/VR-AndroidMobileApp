import 'package:flutter/material.dart';
import 'package:VRHuRoLab/app.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.landscapeRight, DeviceOrientation.landscapeLeft,])
      .then((_) {
    runApp(const VRCameraApp());
  });
}