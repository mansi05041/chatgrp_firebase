// ignore_for_file: must_be_immutable

import 'dart:io';

import 'package:chatgrp_firebase/helper/helper_function.dart';
import 'package:chatgrp_firebase/helper/validator.dart';
import 'package:chatgrp_firebase/pages/home_page.dart';
import 'package:chatgrp_firebase/pages/reset_password.dart';
import 'package:chatgrp_firebase/service/auth_service.dart';
import 'package:chatgrp_firebase/service/database_service.dart';
import 'package:chatgrp_firebase/widgets/widget.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class UpdateScreen extends StatefulWidget {
  UpdateScreen({
    Key? key,
    required this.email,
    required this.userName,
    required this.photoUrl,
  }) : super(key: key);
  final String userName;
  final String email;
  String photoUrl;

  @override
  State<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends State<UpdateScreen> {
  String updateName = '';
  String updatePhotoUrl = '';
  AuthService authService = AuthService();
  DatabaseService databaseService = DatabaseService();
  final _nameTextController = TextEditingController();
  bool _isPhotoLoading = false;
  bool isGoogleAuthProvider = true;

  // function to show the bottom sheet dialog for uploading or removing picture
  Future<void> _showPhotoUploadOption() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: Icon(
                Icons.photo_camera,
                color: Theme.of(context).primaryColor,
              ),
              title: const Text(
                'upload Photo using Camera',
                style: TextStyle(
                  color: Colors.blueGrey,
                ),
              ),
              onTap: () async {
                Navigator.pop(context);
                setState(() {
                  _isPhotoLoading = true;
                });
                // pick the image
                final ImagePicker imagePicker = ImagePicker();
                final XFile? file = await imagePicker.pickImage(source: ImageSource.camera);
                if (file != null) {
                  final String uniqueFileName = DateTime.now().microsecondsSinceEpoch.toString();
                  // store into Firebase Storage
                  final Reference referenceRoot = FirebaseStorage.instance.ref();
                  final Reference imageRef = referenceRoot.child('images');
                  final Reference referenceImageToUpload = imageRef.child(uniqueFileName);
                  try {
                    // upload the image into Firebase Storage
                    await referenceImageToUpload.putFile(File(file.path));
                    await referenceImageToUpload.getDownloadURL().then((value) {
                      setState(() {
                        updatePhotoUrl = value;
                      });
                    });
                    final userPhotoSnapShot = await databaseService.gettingUserData(widget.email);
                    if (userPhotoSnapShot.docs.isNotEmpty) {
                      final userDocument = userPhotoSnapShot.docs.first;
                      await userDocument.reference.update({'profilePic': updatePhotoUrl});
                    }
                    setState(() {
                      _isPhotoLoading = false;
                    });
                    showSnackbar(
                      context,
                      Colors.black12,
                      'Profile Photo has been updated!',
                    );
                  } catch (e) {
                    rethrow;
                  }
                }
              },
            ),
            ListTile(
              leading: Icon(
                Icons.photo_album,
                color: Theme.of(context).primaryColor,
              ),
              title: const Text(
                'upload Photo from gallery',
                style: TextStyle(
                  color: Colors.blueGrey,
                ),
              ),
              onTap: () async {
                Navigator.pop(context);
                setState(() {
                  _isPhotoLoading = true;
                });
                // pick the image
                final ImagePicker imagePicker = ImagePicker();
                final XFile? file = await imagePicker.pickImage(source: ImageSource.gallery);
                if (file != null) {
                  final String uniqueFileName = DateTime.now().microsecondsSinceEpoch.toString();
                  // store into Firebase Storage
                  final Reference referenceRoot = FirebaseStorage.instance.ref();
                  final Reference imageRef = referenceRoot.child('images');
                  final Reference referenceImageToUpload = imageRef.child(uniqueFileName);
                  try {
                    // upload the image into Firebase Storage
                    await referenceImageToUpload.putFile(File(file.path));
                    await referenceImageToUpload.getDownloadURL().then((value) {
                      setState(() {
                        updatePhotoUrl = value;
                      });
                    });
                    final userPhotoSnapShot = await databaseService.gettingUserData(widget.email);
                    if (userPhotoSnapShot.docs.isNotEmpty) {
                      final userDocument = userPhotoSnapShot.docs.first;
                      await userDocument.reference.update({'profilePic': updatePhotoUrl});
                    }
                    setState(() {
                      _isPhotoLoading = false;
                    });
                    showSnackbar(
                      context,
                      Colors.black12,
                      'Profile Photo has been updated!',
                    );
                  } catch (e) {
                    rethrow;
                  }
                }
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete,
                color: Theme.of(context).primaryColor,
              ),
              title: const Text(
                'Remove Photo',
                style: TextStyle(
                  color: Colors.blueGrey,
                ),
              ),
              onTap: () async {
                Navigator.pop(context);
                setState(() {
                  _isPhotoLoading = true;
                });
                // Check if the user already has a profile photo
                if (widget.photoUrl != '') {
                  try {
                    final Uri uri = Uri.parse(widget.photoUrl);
                    final String path = uri.path;
                    final String fileName = path.split('/').last;
                    final Reference ref = FirebaseStorage.instance.ref().child('images/$fileName');
                    try {
                      await ref.delete();
                      setState(() {
                        widget.photoUrl = '';
                      });
                    } catch (e) {
                      debugPrint(e.toString());
                    }
                  } catch (e) {
                    debugPrint(e.toString());
                  }
                }
                try {
                  // upload the image into Firebase Storage as empty
                  setState(() {
                    widget.photoUrl = '';
                  });
                  final userPhotoSnapShot = await databaseService.gettingUserData(widget.email);
                  if (userPhotoSnapShot.docs.isNotEmpty) {
                    final userDocument = userPhotoSnapShot.docs.first;
                    await userDocument.reference.update({'profilePic': widget.photoUrl});
                  }
                  setState(() {
                    _isPhotoLoading = false;
                  });
                  showSnackbar(
                    context,
                    Colors.black12,
                    'Profile Photo has been removed!',
                  );
                } catch (e) {
                  rethrow;
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      updatePhotoUrl = widget.photoUrl;
      updateName = widget.userName;
    });
    getAuthProvider();
  }

  // function to get the Authentication provider
  getAuthProvider() async {
    await authService.authenticationProvider().then((value) {
      if (value == 'Google') {
        setState(() {
          isGoogleAuthProvider = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: const Text('Update Profile'),
        leading: IconButton(
          onPressed: () {
            nextScreen(context, const HomePage());
          },
          icon: const Icon(Icons.home_filled),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 100),
        child: Column(
          children: [
            Row(
              children: [
                Stack(
                  children: [
                    if (updatePhotoUrl != '')
                      _isPhotoLoading
                          ? CircularProgressIndicator(
                              backgroundColor: Theme.of(context).primaryColor,
                            )
                          : CircleAvatar(
                              radius: 30,
                              backgroundImage: NetworkImage(updatePhotoUrl),
                            )
                    else
                      _isPhotoLoading
                          ? CircularProgressIndicator(
                              backgroundColor: Theme.of(context).primaryColor,
                            )
                          : Icon(
                              Icons.account_circle,
                              size: 50,
                              color: Colors.grey[700],
                            ),
                    Positioned(
                      bottom: -15,
                      right: -13,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt),
                        onPressed: () {
                          // Handle camera icon button press
                          _showPhotoUploadOption();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  width: 20,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.userName.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.redAccent,
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Text.rich(
                      TextSpan(
                        text: 'Change Profile Photo! ',
                        style: const TextStyle(
                          color: Colors.blueGrey,
                          fontSize: 14,
                        ),
                        children: <TextSpan>[
                          TextSpan(
                            text: 'Click here',
                            style: const TextStyle(
                              color: Colors.grey,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                _showPhotoUploadOption();
                              },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(
              height: 30,
            ),
            // name
            TextFormField(
              controller: _nameTextController,
              enabled: !isGoogleAuthProvider,
              decoration: InputDecoration(
                hintText: widget.userName,
                prefixIcon: Icon(
                  Icons.person_outlined,
                  color: Theme.of(context).primaryColor,
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                errorBorder: UnderlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(
                    color: Colors.red,
                  ),
                ),
              ),
              onChanged: (val) async {
                setState(() {
                  updateName = val;
                });
                // update value in firebase
                final userDataSnapShot = await databaseService.gettingUserData(widget.email);
                if (userDataSnapShot.docs.isNotEmpty) {
                  final userDocument = userDataSnapShot.docs.first;
                  await userDocument.reference.update({'fullName': updateName});
                }

                // update in the helper function
                await HelperFunction.saverUserNameSF(updateName);
              },
            ),
            const SizedBox(height: 8),
            if (isGoogleAuthProvider)
              const Text(
                "You can't change your name if you're signed in with Google.",
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w700,
                ),
              ),
            const SizedBox(height: 15),
            // email
            TextFormField(
              enabled: false,
              // check the validation
              validator: (val) => val!.isValidEmail() ? null : 'Please enter a valid email',
              decoration: InputDecoration(
                hintText: widget.email,
                prefixIcon: Icon(
                  Icons.email_outlined,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // reset the password
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () {
                  nextScreen(context, const ResetPassword());
                },
                child: const Text(
                  'Reset Password',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
