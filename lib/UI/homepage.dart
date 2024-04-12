import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screen_recording/flutter_screen_recording.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:VRHuRoLab/io.dart';
import 'package:open_file/open_file.dart';

void logError(String code, String message) =>
    print('Error: $code\nError Message: $message');

String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();

class Homepage extends StatefulWidget {
  const Homepage({super.key, required this.CameraScreen});
  final StatefulWidget CameraScreen;

  @override
  State<Homepage> createState() => _Homepage(this.CameraScreen);
}

class _Homepage extends State<Homepage> {
  bool isViewing = false;
  bool isRecording = false;
  bool isExporting = false;
  bool isStreaming = false;

  final StatefulWidget CameraScreen;

  _Homepage(this.CameraScreen);

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
    return start;
  }

  stopScreenRecord() async {
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
            const SnackBar(content: Text("Video Saved Successfully")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Some error occurred in downloading image")));
      }
    });
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isExporting)
              const Center(child: CircularProgressIndicator())
            else ...[
              if (!isViewing || (!isRecording && !isExporting))
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
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
                  // endif
                  ElevatedButton(
                    onPressed: () {
                      startScreenRecord(false);
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Started video recording")));
                      setState(() {
                        isRecording = true;
                      });
                    },
                    child: const Text('Start recording'),
                  ),
                ],
              ),
              if (isRecording && !isExporting)
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
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
                      },
                      child: const Text('Stop recording'),
                    ),
                  ],
                ),
              if (isViewing)
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          isViewing = false;
                        });
                      },
                      child: const Text('Return to Homepage'),
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