import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screen_recording/flutter_screen_recording.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:VRHuRoLab/io.dart';
import 'package:device_apps/device_apps.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
// import 'package:ed_screen_recorder/ed_screen_recorder.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';

void logError(String code, String message) =>
    print('Error: $code\nError Message: $message');

String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();

bool isViewing = false;
bool isRecording = false;
bool isExporting = false;
bool isStreaming = false;
const List<String> resolutionList = <String>['Low (320x240)', 'Medium (720x480)', 'High (1280x720)', 'Very High (1920x1080)', 'Ultra High (3840x2160)', 'Max (Highest as possible)'];
String resolutionChoice = resolutionList.last;

class Homepage extends StatefulWidget {
  const Homepage({super.key, required this.CameraScreen});
  final StatefulWidget CameraScreen;

  @override
  State<Homepage> createState() => _Homepage(this.CameraScreen);
}

class _Homepage extends State<Homepage> {

  final StatefulWidget CameraScreen;

  bool inProgress = false;

  _Homepage(this.CameraScreen);

  Future<bool> startScreenRecord(bool audio, String fileName, int width, int height) async {

    var status = await Permission.storage.status;
    if (!status.isGranted) {
      // If not we will ask for permission first
      await Permission.storage.request();
    }
    // save path: /storage/emulated/0/Download/<App name>/<filename>.mp4
    // Reason for saving file in that path: https://github.com/Isvisoft/flutter_screen_recording/blob/9c1639011ff37055311f5ff4dc27d1be9d8cea58/flutter_screen_recording/android/src/main/kotlin/com/isvisoft/flutter_screen_recording/FlutterScreenRecordingPlugin.kt
    bool start = false;
    if (audio) {
      start = await FlutterScreenRecording.startRecordScreenAndAudio(
          fileName,
          titleNotification: "Saving recording",
          messageNotification: "Saving recording");
    } else {
      start = await FlutterScreenRecording.startRecordScreen(fileName,
          titleNotification: "Saving recording",
          messageNotification: "Saving recording");
    }
    return start;
  }

  Future<void> stopScreenRecord() async {
    String lpath = await FlutterScreenRecording.stopRecordScreen;
    // if (kDebugMode) {
    //   print("Opening video");
    // }
    if (kDebugMode) {
      print(lpath);
    }
    GallerySaver.saveVideo(lpath).then((value) {
      if (value != null && value) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Video Saved Successfully to $lpath")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Some error occurred in downloading image")));
      }
    });
    // try {
    //   var stopResponse = await screenRecorder.stopRecord();
    //   setState(() {
    //     response = stopResponse;
    //   });
    // } on PlatformException {
    //   kDebugMode ? debugPrint("Error: An error occurred while stopping recording.") : null;
    // }
    // OpenFile.open(lpath);
  }

  var headings = """Timestamp, 
  UserAccelerometer.X, UserAccelerometer.Y, UserAccelerometer.Z, 
  AccelerometerEvent.X, AccelerometerEvent.Y, AccelerometerEvent.Z, 
  GyroscopeEvent.X, GyroscopeEvent.Y, GyroscopeEvent.Z, 
  MagnetometerEvent.X, MagnetometerEvent.Y, MagnetometerEvent.Z
  """ ;

  @override
  Widget build(BuildContext context) {
    var title = 'Homepage';
    if (isViewing) {
      title = 'Return page';
    }

    double screenWidth =MediaQuery.of(context).size.width;
    double screenHeight =MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(title, style: const TextStyle(fontSize: 24)),
        backgroundColor: Colors.grey,
        leading: Image(
            width: screenWidth / 5,
            height: screenHeight / 5,
            image: const AssetImage('assets/images/HuRoLabIcon.png')),
        actions: [
          IconButton(onPressed: (){
            SystemChannels.platform.invokeMethod('SystemNavigator.pop');
          }, icon: const Icon(Icons.exit_to_app_rounded))
        ],
      ),
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Container(
              width: screenWidth / 3,
              alignment: Alignment.topLeft,
              child:
              const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Powered by:"),
                  Text("Human robotics laboratory"),
                  Text("NAIST"),
                  Text("Version: 20240419"),
                  Text("Developed by MuC"),
                  Text("Saved files:"),
                  Text(" IMU: Download/VR_logs/imu/"),
                  Text(" Videos: gallery"),
                ],
              ),
            ),
            Container(
              width: screenWidth / 3,
              alignment: Alignment.topCenter,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (isExporting)
                    const Center(child: CircularProgressIndicator())
                  else ...[
                    if ((!isRecording || !isStreaming) && !isExporting)
                      if (!isRecording)
                        ElevatedButton(
                          onPressed: () {
                            startScreenRecord(false, "screen_${timestamp()}",
                                context.size?.width.toInt() ?? 0,
                                context.size?.height.toInt() ?? 0);
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Started video recording")));
                            setState(() {
                              isRecording = true;
                            });
                          },
                          child: const Text('Start recording'),
                        ),
                      if (!isStreaming)
                        ElevatedButton(
                          onPressed: () {
                            startStreaming();
                            setState(() {
                              isStreaming = true;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Started video streaming")));
                          },
                          child: const Text('Start streaming'),
                        ),
                    // endif
                    if (isRecording && !isExporting)
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            isExporting = true;
                          });
                          stopScreenRecord();
                          setState(() {
                            isExporting = false;
                            isRecording = false;
                          });
                          // ScaffoldMessenger.of(context).showSnackBar(
                          //     SnackBar(content: Text("Video Saved Successfully")));
                        },
                        child: const Text('Stop recording'),
                      ),
                    if (isStreaming)
                      ElevatedButton(
                        onPressed: () {
                          stopStreaming();
                          setState(() {
                            isStreaming = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Stopped streaming Successfully")));
                        },
                        child: const Text('Stop Streaming'),
                      ),
                    if (isViewing)
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            isViewing = false;
                          });
                        },
                        child: const Text('Return to Homepage'),
                      ),
                    //endif
                  ],
                  ElevatedButton(
                    onPressed: () {
                      openApp("com.oneplus.filemanager");
                    },
                    child: const Text('Open FileManager'),
                  )
                ],
              ),
            ),
            Container(
              width: screenWidth / 3,
              alignment: Alignment.topRight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const Text("Camera resolution settings:"),
                  DropdownMenu<String>(
                    width: screenWidth/4,
                    initialSelection: resolutionList.last,
                    onSelected: (String? value) {
                      // This is called when the user selects an item.
                      setState(() {
                        resolutionChoice = value!;
                      });
                    },
                    dropdownMenuEntries: resolutionList.map<DropdownMenuEntry<String>>((String value) {
                      return DropdownMenuEntry<String>(
                        value: value,
                        label: value,
                      );
                    }).toList(),
                  ),
                  if (!isViewing)
                    Container(
                      alignment: Alignment.center,
                      child: FloatingActionButton.extended(
                        onPressed: () {
                          FileStorage.writeCounter(headings,
                              "log_imu_${timestamp()}.txt");
                          setState(() {
                            isViewing = true;
                          });
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => CameraScreen
                            ),
                          );
                        },
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Start'),
                      ),
                    )
                  else
                    const SizedBox(),
                  ],
                ),
              )
          ],
        ),
      ),
    );
  }
}

Future<void> openApp(String packageName) async {
  List<Application> apps = await DeviceApps.getInstalledApplications(onlyAppsWithLaunchIntent: true, includeSystemApps: true);
  if (kDebugMode) {
    for (var element in apps) {print(element);}
  }
  try {
    bool isInstalled = await DeviceApps.isAppInstalled(packageName);
    if (isInstalled){
      DeviceApps.openApp(packageName);
    } else {
      launch( "market://details?id=$packageName");
    }
  } catch (e){
    if (kDebugMode) {
      print(e);
    }
  }
}

Future<void> startStreaming() async{
  await FlutterWindowManager.clearFlags(
      FlutterWindowManager.FLAG_SECURE);
  openApp('info.dvkr.screenstream.dev');
}

Future<void> stopStreaming() async{
  await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
}