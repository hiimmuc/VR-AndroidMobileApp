// ignore_for_file: prefer_interpolation_to_compose_strings

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:io';
import 'package:ed_screen_recorder/ed_screen_recorder.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:talker_flutter/talker_flutter.dart';
import "package:intl/intl.dart";
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_screen_recording/flutter_screen_recording.dart';
import 'package:open_file/open_file.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight])
      .then((_) {
    runApp(const VRCameraApp());
  });
}

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
      home: const BluetoothScreen(),
    );
  }
}

class Homepage extends StatefulWidget {
  const Homepage({super.key});
  @override
  _Homepage createState() => _Homepage();
}

class _Homepage extends State<Homepage> {
  // const Homepage({super.key});
  bool _recording = false;
  bool _exporting = false;
  bool recording = false;
  final int _time = 0;

  // final ScreenRecorderController _controller = ScreenRecorderController();
  // bool get canExport => _controller.exporter.hasFrames;

  startScreenRecord(bool audio) async {
    bool start = false;
    await Future.delayed(const Duration(milliseconds: 20));
    String fname =
        "screen_${timestamp()}";
    // /storage/emulated/0/Android/data/dev.VRHuRoLab/cache//storage/emulated/0/Download/VR_logs/screen_20240405.mp4
    if (audio) {
      start = await FlutterScreenRecording.startRecordScreenAndAudio(
          fname,
          titleNotification: "Saving recording",
          messageNotification: "Saving recording");
    } else {
      start = await FlutterScreenRecording.startRecordScreen(fname,
          titleNotification: "Saving recording",
          messageNotification: "Saving recording");
    }
    if (start) {
      setState(() => recording = !recording);
    }
    return start;
  }

  stopScreenRecord() async {
    String lpath = await FlutterScreenRecording.stopRecordScreen;
    setState(() {
      recording = !recording;
    });
    if (kDebugMode) {
      print("Opening video");
    }
    if (kDebugMode) {
      print(lpath);
    }
    GallerySaver.saveVideo(lpath).then((value) {
      if (value != null && value) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Video Saved Successfully")));
        // setState(() {
        //   isLoading = false;
        // });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Some error occurred in downloading image")));
        // setState(() {
        //   isLoading = false;
        // });
      }
    });
    // OpenFile.open(lpath);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Homepage', style: TextStyle(fontSize: 24)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_exporting)
              const Center(child: CircularProgressIndicator())
            else ...[
              if (!recording && !_exporting)
                FloatingActionButton(
                  onPressed: () {
                    FileStorage.writeCounter("Begin",
                        "log_imu_${timestamp()}.txt");
                    // _controller.start();
                    // setState(() {
                    //   _recording = true;
                    //   _exporting = false;
                    // });
                    startScreenRecord(false);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const CameraScreen()
                      ),
                    );
                  },
                  child: const Icon(Icons.arrow_forward),
                ),
              if (recording && !_exporting)
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        // _controller.stop();
                        // setState(() {
                        //   _recording = false;
                        //   // _exporting = true;
                        // });
                        stopScreenRecord();
                      },
                      child: const Text('Stop'),
                    ),
                  ],
                )
            ]
          ],
        ),
      ),
    );
  }
}

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  // Slider settings
  static const maxSliderValue = 100.0;
  static const maxAngleValue = 90.0;
  static const minAngleValue = -90.0;
  static const maxZoomLevel = 4.0;
  static const minZoomLevel = 0.5;

  //Camera settings
  double previewHeight = 0.0;
  double previewWidth = 0.0;
  double sliderWidth = 50;
  double paddingWidth = 10;

  List<CameraDescription>? cameras;
  CameraController? controller;
  CameraDescription? selectedCamera;
  EdScreenRecorder? screenRecorder;
  // RecordOutput? _response;
  // bool inProgress = false;

  double xOffset = 50.0;
  double cameraAngle = 0.0;
  double cameraZoom = 1.0;

  bool showInfoDialog = false;

  //IMU settings
  static const Duration _ignoreDuration = Duration(milliseconds: 20);

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
  Duration sensorInterval = SensorInterval.normalInterval;

  // Log file
  final talker = TalkerFlutter.init();
  File file = File(
      "/storage/emulated/0/Download/VR_logs/log_imu_${timestamp()}.txt");

  //Keyboard
  final FocusNode _focusNode = FocusNode();
  bool recording = false;
  // Handles the key events from the Focus widget and updates the

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    setState(() {
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        cameraZoom += 0.1;
        cameraZoom = cameraZoom < maxZoomLevel ? cameraZoom : maxZoomLevel;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        cameraZoom -= 0.1;
        cameraZoom = cameraZoom > minZoomLevel ? cameraZoom : minZoomLevel;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        cameraAngle += 1;
        cameraAngle = cameraAngle < maxAngleValue ? cameraAngle : maxAngleValue;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        cameraAngle -= 1;
        cameraAngle = cameraAngle > minAngleValue ? cameraAngle : minAngleValue;
      }
    });
    return KeyEventResult.handled;
  }

  startScreenRecord(bool audio) async {
    bool start = false;
    await Future.delayed(const Duration(milliseconds: 20));
    String fname =
        "screen_${timestamp()}";
    // /storage/emulated/0/Android/data/dev.VRHuRoLab/cache//storage/emulated/0/Download/VR_logs/screen_20240405.mp4
    if (audio) {
      start = await FlutterScreenRecording.startRecordScreenAndAudio(
          fname,
          titleNotification: "Saving recording",
          messageNotification: "Saving recording");
    } else {
      start = await FlutterScreenRecording.startRecordScreen(fname,
          titleNotification: "Saving recording",
          messageNotification: "Saving recording");
    }
    if (start) {
      setState(() => recording = !recording);
    }
    return start;
  }

  stopScreenRecord() async {
    String lpath = await FlutterScreenRecording.stopRecordScreen;
    setState(() {
      recording = !recording;
    });
    if (kDebugMode) {
      print("Opening video");
    }
    if (kDebugMode) {
      print(lpath);
    }
    GallerySaver.saveVideo(lpath).then((value) {
      if (value != null && value) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Video Saved Successfully")));
        // setState(() {
        //   isLoading = false;
        // });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Some error occurred in downloading image")));
        // setState(() {
        //   isLoading = false;
        // });
      }
    });
    // OpenFile.open(lpath);
  }

  @override
  void initState() {
    super.initState();
    // enable fullscreen

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    availableCameras().then((availableCameras) {
      cameras = availableCameras;
      if (cameras!.isNotEmpty) {
        setState(() {
          selectedCamera = cameras![0];
          _initCameraController(selectedCamera!);
        });
      }
    }).catchError((error) {
      if (kDebugMode) {
        print("Error initializing camera: $error");
      }
    });
    //enable imu
    init_imu();
    //
    // startScreenRecord(false);
  }

  void _initCameraController(CameraDescription cameraDescription) async {
    if (controller != null) {
      await controller!.dispose();
    }
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      // If not we will ask for permission first
      await Permission.storage.request();
    }
    // set camera property here
    controller = CameraController(
      cameraDescription,
      ResolutionPreset.max,
      enableAudio: false,
    );
    // await FlutterDisplayMode.setHighRefreshRate();
    // screenRecorder = EdScreenRecorder();

    controller!.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    }).catchError((error) {
      if (kDebugMode) {
        print("Error initializing camera controller: $error");
      }
    });
  }

  void _switchCamera() {
    if (cameras != null) {
      int currentIndex = cameras!.indexOf(selectedCamera!);
      CameraDescription nextCamera;
      if (currentIndex + 1 < cameras!.length) {
        nextCamera = cameras![currentIndex + 1];
      } else {
        nextCamera = cameras![0];
      }
      setState(() {
        selectedCamera = nextCamera;
      });
      _initCameraController(nextCamera);
    }
  }

  void _showCameraInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Information"),
          content: const Text(
              "Tap the camera preview to switch between available cameras."),
          actions: [
            TextButton(
              child: const Text("Understood"),
              onPressed: () {
                setState(() {
                  showInfoDialog = false;
                });
                Navigator.of(context).pop();
              },
            )
          ],
        );
      },
    );
  }

  void startCameraRecording() async {
    if (controller != null && controller!.value.isInitialized && !controller!.value.isRecordingVideo) {
      await controller?.prepareForVideoRecording();
      await controller?.startVideoRecording();
      // Start recording video
    }
  }

  void stopCameraRecording() async {
    if (controller != null && controller!.value.isRecordingVideo) {
      final videoPath = await controller!.stopVideoRecording();
      // Process the recorded video
      videoPath.saveTo("/storage/emulated/0/Download/VR_logs/camera_${DateFormat('yyyyMMdd').format(DateTime.now()).toString()}.avi");
    }
  }


  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    if (showInfoDialog) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _showCameraInfoDialog(context));
    }

    // preview shape
    MediaQueryData mediaQueryData = MediaQuery.of(context);
    previewWidth = mediaQueryData.size.width;
    previewHeight = mediaQueryData.size.height * 1.5;

    // Verbose log console
    var logMsg = "\n------------------------ Verbose:" +
        DateFormat('yyyy-MM-dd hh:mm:ss').format(DateTime.now()).toString() +
        '------------------------' +
        '\nUser Accelerometer:' +
        ' ' +
        _userAccelerometerEvent!.x.toStringAsFixed(1) +
        ' ' +
        _userAccelerometerEvent!.y.toStringAsFixed(1) +
        ' ' +
        _userAccelerometerEvent!.z.toStringAsFixed(1) +
        "\nAccelerometer event:" +
        ' ' +
        _accelerometerEvent!.x.toStringAsFixed(1) +
        ' ' +
        _accelerometerEvent!.y.toStringAsFixed(1) +
        ' ' +
        _accelerometerEvent!.z.toStringAsFixed(1) +
        "\nGyroscope event:" +
        ' ' +
        _gyroscopeEvent!.x.toStringAsFixed(1) +
        ' ' +
        _gyroscopeEvent!.y.toStringAsFixed(1) +
        ' ' +
        _gyroscopeEvent!.z.toStringAsFixed(1) +
        "\nMagnetometer event:" +
        ' ' +
        _magnetometerEvent!.x.toStringAsFixed(1) +
        ' ' +
        _magnetometerEvent!.y.toStringAsFixed(1) +
        ' ' +
        _magnetometerEvent!.z.toStringAsFixed(1);

    talker.info(logMsg);
    file.writeAsString(logMsg, mode: FileMode.writeOnlyAppend);

    Color color = Colors.white;
    var state = timestamp();
    // startCameraRecording();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          const WhiteLine(),
          IMU_widget(
              _userAccelerometerEvent = _userAccelerometerEvent,
              _accelerometerEvent = _accelerometerEvent,
              _gyroscopeEvent = _gyroscopeEvent,
              _magnetometerEvent = _magnetometerEvent,
              _accelerometerLastInterval = _accelerometerLastInterval,
              _userAccelerometerLastInterval = _userAccelerometerLastInterval,
              _gyroscopeLastInterval = _gyroscopeLastInterval,
              _magnetometerLastInterval = _magnetometerLastInterval),

          // Camera preview
          Focus(
            focusNode: _focusNode,
            onKeyEvent: _handleKeyEvent,
            child: ListenableBuilder(
                listenable: _focusNode,
                builder: (BuildContext context, Widget? child) {
                  return Stack(
                    children: [
                      Center(
                        child: Row(
                          children: [
                            // right eye
                            Expanded(
                              child: GestureDetector(
                                onTap: _switchCamera,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10.0),
                                  child: Transform.translate(
                                    offset: Offset(xOffset, 0),
                                    child: Transform.rotate(
                                      angle: (cameraAngle * pi) / 180,
                                      child: Transform.scale(
                                        scale: cameraZoom,
                                        child: FittedBox(
                                          fit: BoxFit.cover,
                                          child: SizedBox(
                                            width: previewWidth,
                                            height: previewHeight,
                                            child: CameraPreview(controller!),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // left eye
                            Expanded(
                              child: GestureDetector(
                                onTap: _switchCamera,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10.0),
                                  child: Transform.translate(
                                    offset: Offset(-xOffset, 0),
                                    child: Transform.rotate(
                                      angle: (cameraAngle * pi) / 180,
                                      child: Transform.scale(
                                        scale: cameraZoom,
                                        child: FittedBox(
                                          fit: BoxFit.cover,
                                          child: SizedBox(
                                            width: previewWidth,
                                            height: previewHeight,
                                            child: CameraPreview(controller!),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // sliders
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          //First el
                          Positioned(
                            left: 10,
                            right: 10,
                            child: Row(
                              children: [
                                // Text for angle
                                Column(
                                  children: [
                                    //text offset
                                    Text(
                                      xOffset.toStringAsFixed(2),
                                      style: const TextStyle(
                                          color: Color.fromARGB(216, 0, 255, 0),
                                          fontSize: 12),
                                    ),
                                    //text angle
                                    Text(
                                      cameraAngle.toStringAsFixed(2),
                                      style: const TextStyle(
                                          color:
                                          Color.fromARGB(216, 255, 165, 0),
                                          fontSize: 16),
                                    ),
                                    //test zoom
                                    Text(
                                      cameraZoom.toStringAsFixed(2),
                                      style: const TextStyle(
                                          color: Color.fromARGB(216, 255, 0, 0),
                                          fontSize: 16),
                                    ),
                                  ],
                                ),

                                SizedBox(width: paddingWidth * 0.1),

                                // Slider for offset
                                Expanded(
                                  child: Slider(
                                    value: xOffset,
                                    activeColor: const Color.fromARGB(
                                        100, 115, 115, 115),
                                    inactiveColor: const Color.fromARGB(
                                        100, 115, 115, 115),
                                    onChanged: (newValue) {
                                      setState(() {
                                        xOffset = newValue;
                                      });
                                    },
                                    min: 0,
                                    max: maxSliderValue,
                                  ),
                                ),
                                //padding
                                SizedBox(width: paddingWidth * 0.8),
                                // Escape button
                                IconButton(
                                  iconSize: 20,
                                  icon: const Icon(
                                    Icons.exit_to_app,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    Navigator.pop(
                                      context,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),

                          // Second block
                          Positioned(
                            left: 0,
                            right: 0,
                            // alignment: Alignment.center,
                            child: Row(
                              children: <Widget>[
                                //padding left
                                SizedBox(
                                  width: paddingWidth * 0.8,
                                ),
                                //Slider for rotate
                                Container(
                                  width: sliderWidth,
                                  alignment: Alignment.centerLeft,
                                  child: Expanded(
                                    child: RotatedBox(
                                      quarterTurns: 1,
                                      child: Slider(
                                        value: cameraAngle,
                                        divisions: (maxAngleValue.toInt() -
                                            minAngleValue.toInt()),
                                        label: '${cameraAngle.toInt()}',
                                        activeColor: Colors.grey,
                                        inactiveColor:
                                        Colors.grey.withOpacity(0.2),
                                        onChanged: (dynamic newValue) {
                                          setState(() {
                                            cameraAngle = newValue;
                                          });
                                        },
                                        min: minAngleValue,
                                        max: maxAngleValue,
                                      ),
                                    ),
                                  ),
                                ),
                                //padding for screen view
                                SizedBox(
                                    width: previewWidth -
                                        2 * sliderWidth -
                                        2 * paddingWidth),
                                //Slider for camera zoom
                                Container(
                                  width: sliderWidth,
                                  alignment: Alignment.centerLeft,
                                  child: Expanded(
                                    child: RotatedBox(
                                      quarterTurns: 3,
                                      child: Slider(
                                        value: cameraZoom,
                                        label: '$cameraZoom',
                                        min: minZoomLevel,
                                        max: maxZoomLevel,
                                        activeColor: Colors.grey,
                                        inactiveColor:
                                        Colors.grey.withOpacity(0.2),
                                        onChanged: (newValue) {
                                          setState(() {
                                            cameraZoom = newValue;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                                //right padding
                                SizedBox(
                                  width: paddingWidth,
                                ),
                              ],
                            ),
                          ),

                          //Third block
                          Positioned(
                            left: 10,
                            right: 10,
                            child: Row(
                              children: [
                                SizedBox(
                                  height: sliderWidth * 2,
                                  width: 10,
                                ),
                                Column(
                                  children: [
                                    SizedBox(
                                      height: sliderWidth,
                                    ),
                                    Text(
                                      'Status: $state',
                                      style:
                                      TextStyle(color: color, fontSize: 16),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: sliderWidth * 2,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }),
          ),
        ],
      ),
    );
  }


  Future<void> init_imu() async {
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

  @override
  void dispose() {
    controller?.dispose();
    _focusNode.dispose();
    // stopScreenRecord();
    for (final subscription in _streamSubscriptions) {
      subscription.cancel();
    }
    // stopRecord();
    super.dispose();
  }
}

class WhiteLine extends StatelessWidget {
  const WhiteLine({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      bottom: 0,
      left: MediaQuery.of(context).size.width / 2 - 1,
      child: Container(
        width: 2,
        color: Colors.white,
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

  IMU_widget(
      this._userAccelerometerEvent,
      this._accelerometerEvent,
      this._gyroscopeEvent,
      this._magnetometerEvent,
      this._userAccelerometerLastInterval,
      this._accelerometerLastInterval,
      this._gyroscopeLastInterval,
      this._magnetometerLastInterval,
      {super.key});

  double textSize = 8;

  @override
  Widget build(BuildContext context) {
    return //IMU
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
      );
  }
}

// To save the file in the device
class FileStorage {
  static Future<String> getExternalDocumentPath() async {
    // To check whether permission is given for this app or not.
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      // If not we will ask for permission first
      await Permission.storage.request();
    }
    Directory directory = Directory("");
    if (Platform.isAndroid) {
      // Redirects it to download folder in android
      directory = Directory("/storage/emulated/0/Download");
    } else {
      directory = await getApplicationDocumentsDirectory();
    }
    final exPath = directory.path;
    if (kDebugMode) {
      print(exPath.toString());
    }
    await Directory("$exPath/VR_logs/").create(recursive: true);
    return exPath;
  }

  static Future<String> get _localPath async {
    // final directory = await getApplicationDocumentsDirectory();
    // return directory.path;
    // To get the external path from device of download folder
    final String directory = await getExternalDocumentPath();
    return directory;
  }

  static Future<File> writeCounter(String bytes, String name) async {
    final path = await _localPath;
    // Create a file for the path of
    // device and file name with extension
    File file = File('$path/$name');
    // Write the data in the file you have created
    return file.writeAsString(bytes);
  }
}

class BluetoothScreen extends StatelessWidget {
  const BluetoothScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      color: Colors.lightBlue,
      home: StreamBuilder<BluetoothAdapterState>(
          stream: FlutterBluePlus.adapterState,
          initialData: BluetoothAdapterState.unknown,
          builder: (c, snapshot) {
            final state = snapshot.data;
            if (state == BluetoothAdapterState.on) {
              return Homepage();
            }
            return BluetoothOffScreen(state: state);
          }),
    );
  }
}

class BluetoothOffScreen extends StatelessWidget {
  const BluetoothOffScreen({super.key, this.state});

  final BluetoothAdapterState? state;

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
                  .titleSmall
                  ?.copyWith(color: Colors.white),
            ),
            ElevatedButton(
              onPressed:
              Platform.isAndroid ? () => FlutterBluePlus.turnOn() : null,
              child: const Text('TURN ON'),
            ),
          ],
        ),
      ),
    );
  }
}