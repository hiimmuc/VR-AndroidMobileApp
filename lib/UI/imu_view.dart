import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import "package:intl/intl.dart";

String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();

class IMU extends StatefulWidget {
  const IMU({super.key});
  @override
  State<IMU> createState() => _IMU_widget();
}

class _IMU_widget extends State<IMU> {
  String time = timestamp();
  // Log file
  // final talker = TalkerFlutter.init();
  File file = File(
      "/storage/emulated/0/Download/VR_logs/imu/log_imu_${timestamp()}.txt");

  static const Duration _ignoreDuration = Duration(milliseconds: 10);

  UserAccelerometerEvent? _userAccelerometerEvent;
  AccelerometerEvent? _accelerometerEvent;
  GyroscopeEvent? _gyroscopeEvent;
  MagnetometerEvent? _magnetometerEvent;

  DateTime? _userAccelerometerUpdateTime;
  DateTime? _accelerometerUpdateTime;
  DateTime? _gyroscopeUpdateTime;
  DateTime? _magnetometerUpdateTime;

  int? _userAccelerometerLastInterval;
  int? _accelerometerLastInterval;
  int? _gyroscopeLastInterval;
  int? _magnetometerLastInterval;
  final _streamSubscriptions = <StreamSubscription<dynamic>>[];

  Duration sensorInterval = const Duration(milliseconds: 33, microseconds: 333);// normal (200) ui (70) game(20)
  double textSize = 8;
  @override
  Widget build(BuildContext context) {
    time = _userAccelerometerUpdateTime.toString();

    // Verbose log console
    var logMsg = "$time, ${_userAccelerometerEvent?.x}, ${_userAccelerometerEvent?.y}, ${_userAccelerometerEvent?.z}, ${_accelerometerEvent?.x}, ${_accelerometerEvent?.y}, ${_accelerometerEvent?.z}, ${_gyroscopeEvent?.x}, ${_gyroscopeEvent?.y}, ${_gyroscopeEvent?.z}, ${_magnetometerEvent?.x}, ${_magnetometerEvent?.y}, ${_magnetometerEvent?.z}";
    // talker.info(logMsg);

    file.writeAsString(logMsg, mode: FileMode.writeOnlyAppend);
    return IMU_widget(
        _userAccelerometerEvent = _userAccelerometerEvent,
        _accelerometerEvent = _accelerometerEvent,
        _gyroscopeEvent = _gyroscopeEvent,
        _magnetometerEvent = _magnetometerEvent,
        _accelerometerLastInterval = _accelerometerLastInterval,
        _userAccelerometerLastInterval = _userAccelerometerLastInterval,
        _gyroscopeLastInterval = _gyroscopeLastInterval,
        _magnetometerLastInterval = _magnetometerLastInterval,
        _userAccelerometerUpdateTime = _userAccelerometerUpdateTime);
  }

  @override
  void dispose() {
    super.dispose();
    for (final subscription in _streamSubscriptions) {
      subscription.cancel();
    }
  }

  @override
  void initState() {
    super.initState();
    _streamSubscriptions.add(
      userAccelerometerEventStream(samplingPeriod: sensorInterval).listen(
            (UserAccelerometerEvent event) {
          final now = DateTime.now();
          setState(() {
            _userAccelerometerEvent = event;
            if (_userAccelerometerUpdateTime != null) {
              final interval = now.difference(_userAccelerometerUpdateTime!);
              if (interval > _ignoreDuration) {
                _userAccelerometerLastInterval = interval.inMilliseconds;
              }
            }
          });
          _userAccelerometerUpdateTime = now;
        },
        onError: (e) {
          showDialog(
              context: context,
              builder: (context) {
                return const AlertDialog(
                  title: Text("Sensor Not Found"),
                  content: Text(
                      "It seems that your device doesn't support User Accelerometer Sensor"),
                );
              });
        },
        cancelOnError: true,
      ),
    );
    _streamSubscriptions.add(
      accelerometerEventStream(samplingPeriod: sensorInterval).listen(
            (AccelerometerEvent event) {
          final now = DateTime.now();
          setState(() {
            _accelerometerEvent = event;
            if (_accelerometerUpdateTime != null) {
              final interval = now.difference(_accelerometerUpdateTime!);
              if (interval > _ignoreDuration) {
                _accelerometerLastInterval = interval.inMilliseconds;
              }
            }
          });
          _accelerometerUpdateTime = now;
        },
        onError: (e) {
          showDialog(
              context: context,
              builder: (context) {
                return const AlertDialog(
                  title: Text("Sensor Not Found"),
                  content: Text(
                      "It seems that your device doesn't support Accelerometer Sensor"),
                );
              });
        },
        cancelOnError: true,
      ),
    );
    _streamSubscriptions.add(
      gyroscopeEventStream(samplingPeriod: sensorInterval).listen(
            (GyroscopeEvent event) {
          final now = DateTime.now();
          setState(() {
            _gyroscopeEvent = event;
            if (_gyroscopeUpdateTime != null) {
              final interval = now.difference(_gyroscopeUpdateTime!);
              if (interval > _ignoreDuration) {
                _gyroscopeLastInterval = interval.inMilliseconds;
              }
            }
          });
          _gyroscopeUpdateTime = now;
        },
        onError: (e) {
          showDialog(
              context: context,
              builder: (context) {
                return const AlertDialog(
                  title: Text("Sensor Not Found"),
                  content: Text(
                      "It seems that your device doesn't support Gyroscope Sensor"),
                );
              });
        },
        cancelOnError: true,
      ),
    );
    _streamSubscriptions.add(
      magnetometerEventStream(samplingPeriod: sensorInterval).listen(
            (MagnetometerEvent event) {
          final now = DateTime.now();
          setState(() {
            _magnetometerEvent = event;
            if (_magnetometerUpdateTime != null) {
              final interval = now.difference(_magnetometerUpdateTime!);
              if (interval > _ignoreDuration) {
                _magnetometerLastInterval = interval.inMilliseconds;
              }
            }
          });
          _magnetometerUpdateTime = now;
        },
        onError: (e) {
          showDialog(
              context: context,
              builder: (context) {
                return const AlertDialog(
                  title: Text("Sensor Not Found"),
                  content: Text(
                      "It seems that your device doesn't support Magnetometer Sensor"),
                );
              });
        },
        cancelOnError: true,
      ),
    );
  }
}

class IMU_widget extends StatelessWidget {
  final UserAccelerometerEvent? _userAccelerometerEvent;

  final AccelerometerEvent? _accelerometerEvent;

  final GyroscopeEvent? _gyroscopeEvent;

  final MagnetometerEvent? _magnetometerEvent;

  final int? _userAccelerometerLastInterval;

  final int? _accelerometerLastInterval;

  final int? _gyroscopeLastInterval;

  final int? _magnetometerLastInterval;

  final DateTime? _userAccelerometerUpdateTime;

  const IMU_widget(
      this._userAccelerometerEvent,
      this._accelerometerEvent,
      this._gyroscopeEvent,
      this._magnetometerEvent,
      this._userAccelerometerLastInterval,
      this._accelerometerLastInterval,
      this._gyroscopeLastInterval,
      this._magnetometerLastInterval,
      this._userAccelerometerUpdateTime,
      {super.key});

  final double textSize = 8;

  @override
  Widget build(BuildContext context) {
    return //IMU
      Stack(children: [
        Positioned(
            bottom: 18,
            left: -200,
            right: 0,
            child: Container(
              alignment: Alignment.bottomCenter,
              child: Text(
                _userAccelerometerUpdateTime.toString(),
                style: const TextStyle(color: Colors.lightBlue, fontSize: 12),
              ),
            )),
        Positioned(
        bottom: 0,
        left: 500,
        right: 30,
        child: Container(
          padding: const EdgeInsets.all(1.0),
          alignment: Alignment.bottomRight,
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(1),
              1: FlexColumnWidth(0.3),
              2: FlexColumnWidth(0.3),
              3: FlexColumnWidth(0.3),
              4: FlexColumnWidth(0.5),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              // const TableRow(
              //   children: [
              //     SizedBox.shrink(),
              //     Text('X',
              //         style: TextStyle(color: Colors.white70, fontSize: 8)),
              //     Text('Y',
              //         style: TextStyle(color: Colors.white70, fontSize: 8)),
              //     Text('Z',
              //         style: TextStyle(color: Colors.white70, fontSize: 8)),
              //     Text('Interval',
              //         style: TextStyle(color: Colors.white70, fontSize: 8)),
              //   ],
              // ),
              TableRow(
                children: [
                  const Text('UserAccelerometer',
                      style: TextStyle(color: Colors.white70, fontSize: 8)),
                  Text(_userAccelerometerEvent?.x.toStringAsFixed(1) ?? '?',
                      style: const TextStyle(color: Colors.white70, fontSize: 8)),
                  Text(_userAccelerometerEvent?.y.toStringAsFixed(1) ?? '?',
                      style: const TextStyle(color: Colors.white70, fontSize: 8)),
                  Text(_userAccelerometerEvent?.z.toStringAsFixed(1) ?? '?',
                      style: const TextStyle(color: Colors.white70, fontSize: 8)),
                  Text('${_userAccelerometerLastInterval?.toString() ?? '?'} ms',
                      style: const TextStyle(color: Colors.white70, fontSize: 8)),
                ],
              ),
              TableRow(
                children: [
                  const Text('Accelerometer',
                      style: TextStyle(color: Colors.white70, fontSize: 8)),
                  Text(_accelerometerEvent?.x.toStringAsFixed(1) ?? '?',
                      style: const TextStyle(color: Colors.white70, fontSize: 8)),
                  Text(_accelerometerEvent?.y.toStringAsFixed(1) ?? '?',
                      style: const TextStyle(color: Colors.white70, fontSize: 8)),
                  Text(_accelerometerEvent?.z.toStringAsFixed(1) ?? '?',
                      style: const TextStyle(color: Colors.white70, fontSize: 8)),
                  Text('${_accelerometerLastInterval?.toString() ?? '?'} ms',
                      style: const TextStyle(color: Colors.white70, fontSize: 8)),
                ],
              ),
              TableRow(
                children: [
                  const Text('Gyroscope',
                      style: TextStyle(color: Colors.white70, fontSize: 8)),
                  Text(_gyroscopeEvent?.x.toStringAsFixed(1) ?? '?',
                      style: const TextStyle(color: Colors.white70, fontSize: 8)),
                  Text(_gyroscopeEvent?.y.toStringAsFixed(1) ?? '?',
                      style: const TextStyle(color: Colors.white70, fontSize: 8)),
                  Text(_gyroscopeEvent?.z.toStringAsFixed(1) ?? '?',
                      style: const TextStyle(color: Colors.white70, fontSize: 8)),
                  Text('${_gyroscopeLastInterval?.toString() ?? '?'} ms',
                      style: const TextStyle(color: Colors.white70, fontSize: 8)),
                ],
              ),
              TableRow(
                children: [
                  const Text('Magnetometer',
                      style: TextStyle(color: Colors.white70, fontSize: 8)),
                  Text(_magnetometerEvent?.x.toStringAsFixed(1) ?? '?',
                      style: const TextStyle(color: Colors.white70, fontSize: 8)),
                  Text(_magnetometerEvent?.y.toStringAsFixed(1) ?? '?',
                      style: const TextStyle(color: Colors.white70, fontSize: 8)),
                  Text(_magnetometerEvent?.z.toStringAsFixed(1) ?? '?',
                      style: const TextStyle(color: Colors.white70, fontSize: 8)),
                  Text('${_magnetometerLastInterval?.toString() ?? '?'} ms',
                      style: const TextStyle(color: Colors.white70, fontSize: 8)),
                ],
              ),
            ],
          ),
        ),
      )
      ],
    );

  }
}
