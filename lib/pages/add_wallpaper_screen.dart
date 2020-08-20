import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:path/path.dart' as path;

class AddWallpaperScreen extends StatefulWidget {
  @override
  _AddWallpaperScreenState createState() => _AddWallpaperScreenState();
}

class _AddWallpaperScreenState extends State<AddWallpaperScreen> {
  File _image;
  //this is the image labeler we use..
  final ImageLabeler labeler = FirebaseVision.instance.imageLabeler();

  List<String> labelsInString = [];
  //instances for firebase/auth/storage
  final Firestore _db = Firestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  bool _isUploading = false;
  bool _isCompletedUploading = false;

  @override
  void dispose() {
    labeler.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add Wallpaper"),
      ),
      body: SingleChildScrollView(
        child: Container(
          width: MediaQuery.of(context).size.width,
          child: Column(
            children: <Widget>[
              InkWell(
                onTap: _loadImage,
                child: _image != null
                    ? Image.file(_image)
                    : Image(
                        image: AssetImage("assets/placeholder.jpg"),
                      ),
              ),
              Text("Click to select image "),
              SizedBox(
                height: 20,
              ),
              labelsInString.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Wrap(
                        spacing: 10,
                        children: labelsInString.map((label) {
                          return Chip(
                            label: Text(label),
                          );
                        }).toList(),
                      ),
                    )
                  : Container(),
              SizedBox(
                height: 40,
              ),
              if (_isUploading) ...[Text("Uploading wallpaper...")],
              if (_isCompletedUploading) ...[Text("Upload Completed")],
              SizedBox(
                height: 40,
              ),
              RaisedButton(
                onPressed: _uploadWallpaper,
                child: Text("Upload Wallpaper"),
              ),
              SizedBox(
                height: 40,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _loadImage() async {
    //here we picked the image from the device locally..
    ImagePicker imagePicker = new ImagePicker();
    var image = await imagePicker.getImage(
        source: ImageSource.gallery, imageQuality: 30);
    //here we select the image to be processed..
    final FirebaseVisionImage visionImage =
        FirebaseVisionImage.fromFilePath(image.path);

    //now we wanna get the labels from the visioned image by processing it..
    List<ImageLabel> labels = await labeler.processImage(visionImage);

    labelsInString = [];
    for (var l in labels) {
      labelsInString.add(l.text);
    }

    setState(() {
      _image = File(image.path);
    });
  }

  void _uploadWallpaper() async {
    if (_image != null) {
      // upload image
      //1. we need to get the path name of the file/image
      String fileName = path.basename(_image.path);
      print(fileName);
      //2. we need to get the user's id
      FirebaseUser user = await _auth.currentUser();
      String uid = user.uid;
      //3. now we need to store the file at the firestore..
      StorageUploadTask task = _storage
          .ref()
          .child("wallpapers")
          .child(uid)
          .child(fileName)
          .putFile(_image);

      task.events.listen((e) {
        if (e.type == StorageTaskEventType.progress) {
          setState(() {
            _isUploading = true;
          });
        }
        if (e.type == StorageTaskEventType.success) {
          setState(() {
            _isCompletedUploading = true;
            _isUploading = false;
          });

          e.snapshot.ref.getDownloadURL().then((url) {
            _db.collection("wallpapers").add({
              "url": url,
              "date": DateTime.now(),
              "uploaded_by": uid,
              "tags": labelsInString
            });

            Navigator.of(context).pop();
          });
        }
      });
    } else {
      // show the dialog

      showDialog(
          context: context,
          builder: (ctx) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: Text("Error"),
              content: Text("Select image to upload..."),
              actions: <Widget>[
                RaisedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                  },
                  child: Text("OK"),
                ),
              ],
            );
          });
    }
  }
}
