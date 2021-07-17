import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:rider_app/main.dart';
import 'package:rider_app/screens/login_screen.dart';
import 'package:rider_app/screens/main_screen.dart';
import 'package:rider_app/widgets/progress_dialog.dart';

class RegistrationScreen extends StatelessWidget {
  static const String idScreen = "register";

  TextEditingController _nameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _phoneController = TextEditingController();
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
              "Register as a Rider",
              style: TextStyle(fontSize: 30, fontFamily: "Brand Bold"),
            ),
            Padding(
              padding: EdgeInsets.all(10),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(labelText: "Name "),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(labelText: "Email "),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(labelText: "Phone "),
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
                        if (_nameController.text.length < 6) {
                          toastMessage(
                              "Name must be at least 5 letters ", context);
                        } else if (!_emailController.text.contains("@")) {
                          toastMessage("email address is not valid", context);
                        } else if (_phoneController.text.isEmpty) {
                          toastMessage("phone number is mandatory", context);
                        } else if (_passwordController.text.length < 7) {
                          toastMessage(
                              "password must be at least 6 char", context);
                        } else {
                          registerNewUser(context);
                        }
                      },
                      child: Text("Create Account"))
                ],
              ),
            ),
            TextButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                      context, LoginScreen.idScreen, (route) => false);
                },
                child: Text(
                  "Already have an account? Login Here",
                  style: TextStyle(color: Colors.grey.shade600),
                ))
          ],
        ),
      ),
    );
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;

  void registerNewUser(BuildContext context) async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return ProgressDialog(
            message: "Registering, Please wait...",
          );
        });
    final User? user = (await _auth
            .createUserWithEmailAndPassword(
                email: _emailController.text,
                password: _passwordController.text)
            .catchError((errMsg) {
      Navigator.pop(context);
      toastMessage("Error : ${errMsg.toString()}", context);
    }))
        .user;
    if (user != null) {
      Map userDataMap = {
        "name": _nameController.text,
        "email": _emailController.text,
        "phone": _phoneController.text
      };

      userRef.child(user.uid).set(userDataMap);
      toastMessage("Congratulations, your account has been created", context);
      Navigator.pushNamedAndRemoveUntil(
          context, MainScreen.idScreen, (route) => false);
    } else {
      Navigator.pop(context);
      toastMessage("New User account has not been created", context);
    }
  }
}

void toastMessage(String message, BuildContext context) {
  Fluttertoast.showToast(msg: message);
}
