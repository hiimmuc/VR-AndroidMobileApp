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
import 'package:ed_screen_recorder/ed_screen_recorder.dart';


void logError(String code, String message) =>
    print('Error: $code\nError Message: $message');

String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();

bool isViewing = false;
bool isRecording = false;
bool isExporting = false;
bool isStreaming = false;

class Homepage extends StatefulWidget {
  const Homepage({super.key, required this.CameraScreen});
  final StatefulWidget CameraScreen;

  @override
  State<Homepage> createState() => _Homepage(this.CameraScreen);
}

class _Homepage extends State<Homepage> {

  final StatefulWidget CameraScreen;

  EdScreenRecorder screenRecorder = EdScreenRecorder();
  RecordOutput? response;
  bool inProgress = false;

  _Homepage(this.CameraScreen);

  Future<void> startScreenRecord(bool audio, String fileName, int width, int height) async {
    await Future.delayed(const Duration(milliseconds: 20));
    // var status = await Permission.storage.status;
    // if (!status.isGranted) {
    //   // If not we will ask for permission first
    //   await Permission.storage.request();
    // }
    // Directory directory = Directory("");
    // if (Platform.isAndroid) {
    //   // Redirects it to download folder in android
    //   directory = Directory("/storage/emulated/0/Download");
    // } else {
    //   directory = await getApplicationDocumentsDirectory();
    // }
    // final exPath = directory.path;
    // if (kDebugMode) {
    //   print(exPath.toString());
    // }
    // await Directory("$exPath/VR_logs/video/").create(recursive: true);
    // String savedDirPath = "$exPath/VR_logs/video/";
    var savedDir =  await getApplicationDocumentsDirectory();
    String savedDirPath = savedDir.path;
    // save path: /storage/emulated/0/Download/<App name>/<filename>.mp4
    // Reason for saving file in that path: https://github.com/Isvisoft/flutter_screen_recording/blob/9c1639011ff37055311f5ff4dc27d1be9d8cea58/flutter_screen_recording/android/src/main/kotlin/com/isvisoft/flutter_screen_recording/FlutterScreenRecordingPlugin.kt
    // if (audio) {
    //   start = await FlutterScreenRecording.startRecordScreenAndAudio(
    //       filename,
    //       titleNotification: "Saving recording",
    //       messageNotification: "Saving recording");
    // } else {
    //   start = await FlutterScreenRecording.startRecordScreen(filename,
    //       titleNotification: "Saving recording",
    //       messageNotification: "Saving recording");
    // }
    try {
      var startResponse = await screenRecorder.startRecordScreen(
        fileName: fileName,
        //Optional. It will save the video there when you give the file path with whatever you want.
        //If you leave it blank, the Android operating system will save it to the gallery.
        dirPathToSave: savedDirPath,
        audioEnable: audio,
        width: width,
        height: height,
      );
      setState(() {
        response = startResponse;
      });
    } on PlatformException {
      kDebugMode ? debugPrint("Error: An error occurred while starting the recording!") : null;
    }
    // return response;
  }

  Future<void> stopScreenRecord() async {
    // String lpath = await FlutterScreenRecording.stopRecordScreen;
    // // if (kDebugMode) {
    // //   print("Opening video");
    // // }
    // if (kDebugMode) {
    //   print(lpath);
    // }
    // GallerySaver.saveVideo(lpath).then((value) {
    //   if (value != null && value) {
    //     ScaffoldMessenger.of(context).showSnackBar(
    //         const SnackBar(content: Text("Video Saved Successfully")));
    //   } else {
    //     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
    //         content: Text("Some error occurred in downloading image")));
    //   }
    // });
    try {
      var stopResponse = await screenRecorder.stopRecord();
      setState(() {
        response = stopResponse;
      });
    } on PlatformException {
      kDebugMode ? debugPrint("Error: An error occurred while stopping recording.") : null;
    }
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
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontSize: 24)),
      ),
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (isExporting)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  if (!isViewing || (!isRecording && !isExporting))
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Column(
                        //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        //   children: [
                        //     Text("File: ${response?.file.path}"),
                        //     Text("Status: ${response?.success.toString()}"),
                        //     Text("Event: ${response?.eventName}"),
                        //     Text("Progress: ${response?.isProgress.toString()}"),
                        //     Text("Message: ${response?.message}"),
                        //     Text("Video Hash: ${response?.videoHash}"),
                        //     Text("Start Date: ${(response?.startDate).toString()}"),
                        //     Text("End Date: ${(response?.endDate).toString()}"),
                        //   ],
                        // ),
                        const SizedBox(width: 100,),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // endif
                            ElevatedButton(
                              onPressed: () {
                                startScreenRecord(false, "screen_${timestamp()}",
                                    context.size?.width.toInt() ?? 0,
                                    context.size?.height.toInt() ?? 0);
                                // openApp('com.oneplus.screenrecord');
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Started video recording")));
                                setState(() {
                                  isRecording = true;
                                });
                              },
                              child: const Text('Start recording'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Started video streaming")));
                                openApp('info.dvkr.screenstream');
                                setState(() {
                                  isStreaming = true;
                                });
                              },
                              child: const Text('Start streaming'),
                            ),
                          ],
                        ),
                        const SizedBox(width: 50,),
                        if (!isViewing)
                          FloatingActionButton(
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
                            child: const Icon(Icons.arrow_forward),
                          ),
                      ],
                    ),
                  if (isViewing || (isRecording && !isExporting))
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        const SizedBox(width: 100,),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
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
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("Video Saved Successfully to ${response?.file.path}")));
                                },
                                child: const Text('Stop recording'),
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
                          ],
                        ),
                      ],
                    ),
                  //endif
                ],
              ],
            ),
            Container(
              alignment: Alignment.bottomRight,
              child: FloatingActionButton.extended(
                onPressed: () {
                  SystemChannels.platform.invokeMethod('SystemNavigator.pop');
                },
                icon: const Icon(Icons.close_outlined),
                label: const Text('Exit'),
              ),
            ),
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