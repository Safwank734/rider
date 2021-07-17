import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:rider_app/main.dart';
import 'package:rider_app/screens/registratiion_screen.dart';
import 'package:rider_app/widgets/progress_dialog.dart';

import 'main_screen.dart';

class LoginScreen extends StatelessWidget {
  static const String idScreen = "login";
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 35.9,
            ),
            Image(
              image: AssetImage("assets/images/logo.png"),
              width: 390,
              height: 250,
              alignment: Alignment.center,
            ),
            Text(
              "Login as Rider",
              style: TextStyle(fontSize: 30, fontFamily: "Brand Bold"),
            ),
            Padding(
              padding: EdgeInsets.all(10),
              child: Column(
                children: [
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(labelText: "Email "),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(labelText: "Password"),
                  ),
                  SizedBox(height: 10.0),
                  ElevatedButton(
                      onPressed: () {
                        if (!_emailController.text.contains("@")) {
                          toastMessage("email address is not valid", context);
                        } else if (_passwordController.text.isEmpty) {
                          toastMessage("password is mandatory", context);
                        } else {
                          login(context);
                        }
                      },
                      child: Text("Login"))
                ],
              ),
            ),
            TextButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                      context, RegistrationScreen.idScreen, (route) => false);
                },
                child: Text(
                  "Do not have an account? Register Here",
                  style: TextStyle(color: Colors.grey.shade600),
                ))
          ],
        ),
      ),
    );
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;

  void login(BuildContext context) async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return ProgressDialog(
            message: "Authenticating, Please wait...",
          );
        });
    final User? user = (await _auth
            .signInWithEmailAndPassword(
                email: _emailController.text,
                password: _passwordController.text)
            .catchError((errMsg) {
      toastMessage("Error : ${errMsg.toString()}", context);
    }))
        .user;
    if (user != null) {
      userRef.child(user.uid).once().then((DataSnapshot snap) {
        if (snap.value != null) {
          Navigator.pushNamedAndRemoveUntil(
              context, MainScreen.idScreen, (route) => false);
          toastMessage("You are logged in", context);
        } else {
          Navigator.pop(context);
          _auth.signOut();
          toastMessage(
              "No record exists for this user. Please create new account",
              context);
        }
      });
    } else {
      Navigator.pop(context);
      toastMessage("Error occurred", context);
    }
  }
}
