import 'package:flutter/material.dart';
import 'package:video_rec/auth/authentication.dart';


import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;

import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:video_rec/ui/video_play_pause.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';



class HomePage extends StatefulWidget {

  final BaseAuth auth;
  final String userId ;
  final VoidCallback onSignedOut;


  HomePage({Key key, this.auth, this.userId, this.onSignedOut}) : super(key: key);



  @override
  _HomePageState createState() => _HomePageState();
}

/// Returns a suitable camera icon for [direction].
IconData getCameraLensIcon(CameraLensDirection direction) {
  switch (direction) {
    case CameraLensDirection.back:
      return Icons.camera_rear;
    case CameraLensDirection.front:
      return Icons.camera_front;
    case CameraLensDirection.external:
      return Icons.camera;
  }
  throw ArgumentError('Unknown lens direction');
}

void logError(String code, String message) =>
    print('Error: $code\nError Message: $message');




class _HomePageState extends State<HomePage> {

  List<CameraDescription> cameras;
  CameraController controller;
  bool _isReady = false;
  final FlutterFFmpeg _flutterFFmpeg = new FlutterFFmpeg();

  @override
  void initState() {
    super.initState();
    _setupCameras();
  }

  Future<void> _setupCameras() async {
    try {
      // initialize cameras.
      cameras = await availableCameras();
      // initialize camera controllers.
      controller = new CameraController(cameras[0], ResolutionPreset.medium);
      await controller.initialize();
    } on CameraException catch (_) {
      // do something on error.
    }
//    if (!isMounted) return;
    setState(() {
      _isReady = true;
    });
  }

  Future<dynamic> downloadFile(String url) async {
//    String dir = (await getApplicationDocumentsDirectory()).path;
    final Directory extDir = await getApplicationDocumentsDirectory();
    final String dirPath = '${extDir.path}/Videos/flutter_test';
    File file = new File('$dirPath/watermark.png');
    var request = await http.get(url,);
    var bytes = await request.bodyBytes;//close();
    await file.writeAsBytes(bytes);
    print(file.path);
  }



  String imagePath;
  String videoPath;
  VideoPlayerController videoController;
  VoidCallback videoPlayerListener;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _signOut() async {
    try {
      await widget.auth.signOut();
      widget.onSignedOut();
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        key: _scaffoldKey,
        appBar: new AppBar(
          title: new Text('Video Recording'),
          actions: <Widget>[
            new FlatButton(
                child: new Text('Logout',
                    style: new TextStyle(fontSize: 17.0, color: Colors.white)),
                onPressed: _signOut)
          ],
        ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Container(
              child: Padding(
                padding: const EdgeInsets.all(1.0),
                child: Center(
                  child: _cameraPreviewWidget(),
                ),
              ),
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(
                  color: controller != null && controller.value.isRecordingVideo
                      ? Colors.redAccent
                      : Colors.grey,
                  width: 3.0,
                ),
              ),
            ),
          ),
          _captureControlRowWidget(),
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                _cameraTogglesRowWidget(),
//                _thumbnailWidget(),
              ],
            ),
          ),
        ],
      ),
    );
  }

    /// Display the preview from the camera (or a message if the preview is not available).
    Widget _cameraPreviewWidget() {
      if (controller == null || !controller.value.isInitialized) {
        return const Text(
          'Tap a camera',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24.0,
            fontWeight: FontWeight.w900,
          ),
        );
      } else {
        return AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: CameraPreview(controller),

        );
      }
    }


    /// Display the control bar with buttons to take pictures and record videos.
    Widget _captureControlRowWidget() {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          IconButton(
            icon: const Icon(Icons.videocam),
            color: Colors.blue,
            onPressed: controller != null &&
                controller.value.isInitialized &&
                !controller.value.isRecordingVideo
                ? onVideoRecordButtonPressed
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.stop),
            color: Colors.red,
            onPressed: controller != null &&
                controller.value.isInitialized &&
                controller.value.isRecordingVideo
                ? onStopButtonPressed
                : null,
          )
        ],
      );
    }

    /// Display a row of toggle to select the camera (or a message if no camera is available).
    Widget _cameraTogglesRowWidget() {
      final List<Widget> toggles = <Widget>[];
      print('Error: '+cameras.toString());
      if (cameras == null) {
        return const Text('No camera found');
      } else {

        for (CameraDescription cameraDescription in cameras) {
          toggles.add(
            SizedBox(
              width: 90.0,
              child: RadioListTile<CameraDescription>(
                title: Icon(getCameraLensIcon(cameraDescription.lensDirection)),
                groupValue: controller?.description,
                value: cameraDescription,
                onChanged: controller != null && controller.value.isRecordingVideo
                    ? null
                    : onNewCameraSelected,
              ),
            ),
          );
        }
      }

      return Row(children: toggles);
    }

    String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();

    void showInSnackBar(String message) {
      _scaffoldKey.currentState.showSnackBar(SnackBar(content: Text(message)));
    }

    void onNewCameraSelected(CameraDescription cameraDescription) async {
      if (controller != null) {
        await controller.dispose();
      }
      controller = CameraController(cameraDescription, ResolutionPreset.high);

      // If the controller is updated then update the UI.
      controller.addListener(() {
        if (mounted) setState(() {});
        if (controller.value.hasError) {
          showInSnackBar('Camera error ${controller.value.errorDescription}');
        }
      });

      try {
        await controller.initialize();
      } on CameraException catch (e) {
        _showCameraException(e);
      }

      if (mounted) {
        setState(() {});
      }
    }


    void onVideoRecordButtonPressed() {
      startVideoRecording().then((String filePath) {
        if (mounted) setState(() {});
        if (filePath != null) showInSnackBar('Saving video to $filePath');
      });
    }

    void  onStopButtonPressed() {
      stopVideoRecording().then((_) {
        if (mounted) setState(() {});
        showInSnackBar('Video recorded to: $videoPath');
      });
    }

    Future<String> startVideoRecording() async {
      if (!controller.value.isInitialized) {
        showInSnackBar('Error: select a camera first.');
        return null;
      }

      final Directory extDir = await getApplicationDocumentsDirectory();
      final String dirPath = '${extDir.path}/Movies/flutter_test';
      await Directory(dirPath).create(recursive: true);
      final String filePath = '$dirPath/${timestamp()}.mp4';

      if (controller.value.isRecordingVideo) {
        // A recording is already started, do nothing.
        return null;
      }

      try {
        videoPath = filePath;
        await controller.startVideoRecording(filePath);
      } on CameraException catch (e) {
        _showCameraException(e);
        return null;
      }
      return filePath;
    }

    Future<void> stopVideoRecording() async {
      if (!controller.value.isRecordingVideo) {
        return null;
      }

      try {
        await controller.stopVideoRecording();
      } on CameraException catch (e) {
        _showCameraException(e);
        return null;
      }

      String imgurl = 'https://i.imgur.com/FRZUyS2.png';
      await downloadFile(imgurl);
      final Directory extDir = await getApplicationDocumentsDirectory();
      final String dirPath = '${extDir.path}/Videos/flutter_test';
      await Directory(dirPath).create(recursive: true);
      final String filePath = '$dirPath/${timestamp()}.mp4';
      final String watermarkImagePath = '$dirPath/watermark.png';


     var complexCommand = ["-y" ,"-i", videoPath,"-strict","experimental", "-vf", "movie=$watermarkImagePath [watermark]; [in][watermark] overlay=main_w-overlay_w-10:10 [out]","-s", "320x240","-r", "30", "-b", "15496k", "-vcodec", "mpeg4","-ab", "48000", "-ac", "2", "-ar", "22050", filePath];
      await _flutterFFmpeg.executeWithArguments(complexCommand).then((rc) {
        print("FFmpeg process exited with rc $rc");
        videoPath = filePath;
      });


      await _startVideoPlayer();

    }



    Future<void> _startVideoPlayer() async {
      print('Video recorded to: $videoPath');
      final VideoPlayerController vcontroller =
      VideoPlayerController.file(File(videoPath));
      videoPlayerListener = () {
        if (videoController != null && videoController.value.size != null) {
          // Refreshing the state to update video player with the correct ratio.
          if (mounted) setState(() {});
          videoController.removeListener(videoPlayerListener);
        }
      };
      vcontroller.addListener(videoPlayerListener);
      await vcontroller.setLooping(false);
      await vcontroller.initialize();
      await videoController?.dispose();
      if (mounted) {
        setState(() {
          imagePath = null;
          videoController = vcontroller;
        });
      }
      await vcontroller.play();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>  VideoPlayPause(vcontroller),
        ),
      );
    }


    void _showCameraException(CameraException e) {
      logError(e.code, e.description);
      showInSnackBar('Error: ${e.code}\n${e.description}');
    }
  }

  class CameraApp extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
      return MaterialApp(
        home: HomePage(),
      );
    }
  }

  List<CameraDescription> cameras;

  Future<void> main() async {
    // Fetch the available cameras before initializing the app.
    try {
      cameras = await availableCameras();
    } on CameraException catch (e) {
      logError(e.code, e.description);
    }
    runApp(CameraApp());
  }

