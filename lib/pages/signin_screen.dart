import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:wallyapp/config/config.dart';

class SignInScreen extends StatefulWidget {
  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final Firestore _db = Firestore.instance;

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        width: screenSize.width,
        height: screenSize.height,
        child: Stack(
          children: <Widget>[
            Image(
              image: AssetImage("assets/bg.jpg"),
              width: screenSize.width,
              height: screenSize.height,
              fit: BoxFit.cover,
            ),
            Container(
              margin: EdgeInsets.only(
                top: 200,
              ),
              width: screenSize.width,
              child: Image(
                image: AssetImage("assets/logo_circle.png"),
                width: 200,
                height: 200,
              ),
            ),
            Container(
              width: screenSize.width,
              height: screenSize.height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF000000),
                    Color(0x00000000),
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Container(
                width: screenSize.width,
                margin: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: InkWell(
                  onTap: _signIn,
                  child: Container(
                    width: screenSize.width,
                    padding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryColor, secondaryColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      "Google Sign In",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _signIn() async {
    try {
      final GoogleSignInAccount googleUser = await _googleSignIn.signIn();
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.getCredential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final FirebaseUser user =
          (await _auth.signInWithCredential(credential)).user;
      print("signed in " + user.providerId);

      _db.collection("users").document(user.uid).setData({
        "displayName": user.displayName,
        "email": user.email,
        "uid": user.uid,
        "photoUrl": user.photoUrl,
        "lastSignIn": DateTime.now(),
      }, merge: true);
    } catch (e) {
      print(e.message);
    }
  }
}
