import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:imagetotext/imageToText.dart';
import 'package:imagetotext/main.dart';
import 'package:imagetotext/ml_api.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<CameraDescription> cameras;
  CameraController controller;
  bool _isloading = true;
  bool _reqSent = false;
  final GlobalKey<ScaffoldState> _scaffoldkey = new GlobalKey<ScaffoldState>();
  String processedText = "abc";

  void getCameras() async {
    cameras = await availableCameras();
    controller = CameraController(
      cameras[0],
      ResolutionPreset.max,
    );
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
      setState(() {
        _isloading = false;
      });
      controller.setFlashMode(FlashMode.off);
    }).catchError(
      (error) {
        print('Camera Controller Error: $error');
        controller.dispose();
      },
    );
  }

  @override
  void initState() {
    super.initState();
    getCameras();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldkey,
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Scan Text"),
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        child: CameraPreview(controller),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _sendRequest();
        },
        icon: Icon(Icons.camera),
        label: Text("Scan"),
      ),
    );
  }

  void _sendRequest() async {
    try {
      if (!_reqSent) {
        setState(() {
          _reqSent = true;
        });
        XFile file = await controller.takePicture();
        print(file.path);

        ImageToText imageToText = ImageToText();
        processedText = await imageToText.describeImage(file);
        showModalBottomSheet(
            context: context,
            builder: (BuildContext context) {
              return Container(
                width: double.infinity,
                color: Colors.white,
                child: Container(
                  margin: EdgeInsets.all(30.0),
                  decoration: BoxDecoration(
                    border: Border.all(),
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      processedText,
                      style: TextStyle(fontSize: 23.0),
                    ),
                  ),
                ),
              );
            });

        //deleting captured image
        final imageFile = File(file.path);
        imageFile.delete();

        setState(() {
          _reqSent = false;
        });
      }
    } catch (e) {
      print(e);
    }
  }
}
