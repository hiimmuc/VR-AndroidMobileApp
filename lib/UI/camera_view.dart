import 'dart:math';
import 'package:VRHuRoLab/UI/IMU.dart';
import 'package:VRHuRoLab/UI/homepage.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';


class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});
  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  List<CameraDescription>? cameras;
  CameraController? controller;
  CameraDescription? selectedCamera;

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

  double xOffset = 50.0;
  double cameraAngle = 0.0;
  double cameraZoom = 1.0;
  bool showInfoDialog = false;

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


  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    // preview shape
    MediaQueryData mediaQueryData = MediaQuery.of(context);
    previewWidth = mediaQueryData.size.width;
    previewHeight = mediaQueryData.size.height * 1.5;

    Color color = Colors.white;
    var state = "Recording: $isRecording | Streaming: $isStreaming";
    // startCameraRecording();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          const WhiteLine(),
          const IMU(),
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
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              SizedBox(width: paddingWidth * 0.1),
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
                              SizedBox(width: paddingWidth * 0.1),
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

  @override
  void dispose() {
    controller?.dispose();
    _focusNode.dispose();
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