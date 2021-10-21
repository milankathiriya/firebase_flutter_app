import 'dart:convert';

import 'package:firebase_3_pm_app/helpers/firebase_auth_helper.dart';
import 'package:firebase_3_pm_app/screens/dashboard.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

/*
Ch. 13

Publish Code to GitHub
- What is GitHub?
- Installation of Git
- Creating GitHub Account
- Create first GitHub Repository
- Push first App on GitHub
- Grab Project from GitHub
*/

/*
  How to push/upload in GitHub?
    1. Goto your project directory
    2. git init
    3. git add [file/folder/path/.]
    4. git commit -m "commit name"
    5. git push -u origin [branch name/master]

   How to pull/download project from GitHub?
    1. git clone [project url]
* */

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: {
        '/': (context) => HomePage(),
        'dashboard': (context) => DashBoard(),
      },
    ),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  final GlobalKey<FormState> _registerFormKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final GlobalKey<FormState> _loginFormKey = GlobalKey<FormState>();

  final TextEditingController _emailLoginController = TextEditingController();
  final TextEditingController _passwordLoginController =
      TextEditingController();

  String email = "";
  String password = "";

  checkPermission() async {
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');
  }

  @override
  void initState() {
    super.initState();

    messaging.getToken().then((val) {
      print("TOKEN: $val");
    });

    checkPermission();

    FirebaseMessaging.onMessage.listen((RemoteMessage event) {
      print("message recieved");
      print(event.notification!.body);
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(event.notification!.title!),
              content: Text(
                  "${event.notification!.body!}\n${event.data['organization']}"),
              actions: [
                TextButton(
                  child: const Text("Ok"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                )
              ],
            );
          });
    });

    FirebaseMessaging.onBackgroundMessage(_messageHandler);
  }

  Future<void> _messageHandler(RemoteMessage message) async {
    print('background message ${message.notification!.body}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Firebase App"),
        centerTitle: true,
      ),
      body: Container(
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: const Text("Send FCM"),
              style: ElevatedButton.styleFrom(
                primary: Colors.deepOrange,
              ),
              onPressed: sendFCM,
            ),
            ElevatedButton(
              child: const Text("Login Anonymously"),
              onPressed: loginAnonymously,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  child: const Text("Register"),
                  onPressed: registerUser,
                ),
                ElevatedButton(
                  child: const Text("Login with Email/Password"),
                  onPressed: loginUser,
                ),
              ],
            ),
            ElevatedButton(
              child: const Text("Sign in with Google"),
              style: ElevatedButton.styleFrom(
                  primary: Colors.amber, onPrimary: Colors.black),
              onPressed: () async {
                UserCredential userCredential =
                    await FirebaseAuthHelper.instance.signInWithGoogle();

                print("Login Successful");
                print("UID: ${userCredential.user!.uid}");
                print("Name: ${userCredential.user!.displayName}");
                print("Pic: ${userCredential.user!.photoURL}");

                Navigator.of(context)
                    .pushNamed('dashboard', arguments: userCredential);
              },
            ),
          ],
        ),
      ),
    );
  }

  void loginAnonymously() async {
    UserCredential userCredential =
        await FirebaseAuthHelper.instance.loginAnonymously();

    print("Sign in successfully...");
    print("UID: ${userCredential.user!.uid}");

    Navigator.of(context).pushNamed('dashboard', arguments: userCredential);
  }

  void registerUser() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Register User"),
          content: Form(
            key: _registerFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _emailController,
                  validator: (val) {
                    if (val!.isEmpty) {
                      return "Enter your email first...";
                    }
                    return null;
                  },
                  onSaved: (val) {
                    setState(() {
                      email = val!;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: "Email",
                    hintText: "Enter your email here",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  validator: (val) {
                    if (val!.isEmpty) {
                      return "Enter your password first...";
                    }
                    return null;
                  },
                  onSaved: (val) {
                    setState(() {
                      password = val!;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: "Password",
                    hintText: "Enter your password here",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            OutlinedButton(
              child: const Text("Cancel"),
              onPressed: () {
                _emailController.clear();
                _passwordController.clear();

                setState(() {
                  email = "";
                  password = "";
                });
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text("Register"),
              onPressed: () async {
                if (_registerFormKey.currentState!.validate()) {
                  _registerFormKey.currentState!.save();

                  try {
                    UserCredential userCredential = await FirebaseAuthHelper
                        .instance
                        .registerWithEmailAndPassword(
                            email: email, password: password);

                    print("Register Successfully.");
                    print("Email: ${userCredential.user!.email}");
                    print("UID: ${userCredential.user!.uid}");

                    _emailController.clear();
                    _passwordController.clear();

                    setState(() {
                      email = "";
                      password = "";
                    });
                  } on FirebaseAuthException catch (e) {
                    if (e.code == 'weak-password') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Your password is too weak...",
                            style: TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    } else if (e.code == 'email-already-in-use') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "User with this email ID already exists...",
                            style: TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  }

                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void loginUser() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Login User"),
          content: Form(
            key: _loginFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _emailLoginController,
                  validator: (val) {
                    if (val!.isEmpty) {
                      return "Enter your email first...";
                    }
                    return null;
                  },
                  onSaved: (val) {
                    setState(() {
                      email = val!;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: "Email",
                    hintText: "Enter your email here",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _passwordLoginController,
                  obscureText: true,
                  validator: (val) {
                    if (val!.isEmpty) {
                      return "Enter your password first...";
                    }
                    return null;
                  },
                  onSaved: (val) {
                    setState(() {
                      password = val!;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: "Password",
                    hintText: "Enter your password here",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            OutlinedButton(
              child: const Text("Cancel"),
              onPressed: () {
                _emailLoginController.clear();
                _passwordLoginController.clear();

                setState(() {
                  email = "";
                  password = "";
                });
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text("Login"),
              onPressed: () async {
                if (_loginFormKey.currentState!.validate()) {
                  _loginFormKey.currentState!.save();

                  try {
                    UserCredential userCredential = await FirebaseAuthHelper
                        .instance
                        .loginWithEmailAndPassword(
                            email: email, password: password);

                    Navigator.of(context).pop();

                    print("Login Successfully.");
                    print("Email: ${userCredential.user!.email}");
                    print("UID: ${userCredential.user!.uid}");

                    _emailLoginController.clear();
                    _passwordLoginController.clear();

                    setState(() {
                      email = "";
                      password = "";
                    });

                    Navigator.of(context)
                        .pushNamed('dashboard', arguments: userCredential);
                  } on FirebaseAuthException catch (e) {
                    if (e.code == 'user-not-found') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "User not Found...",
                            style: TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    } else if (e.code == 'wrong-password') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Wrong Password...",
                            style: TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  sendFCM() async {
    String url = "https://fcm.googleapis.com/fcm/send";

    Map<String, String> myHeaders = {
      'Content-Type': 'application/json',
      'Authorization':
          'key=AAAApqNz8x4:APA91bE7RU6vmz3lcdmqBcqYoqrbPV20qcM7l9fMVLYbBY4fwMWTk8Cqc_HyG2kVmNHsQG22NllCfIP29EnmmRCmAFUIxHlaTmRTxDHF2mKhyEDXy20DLViVAj2_V8UrfGyFQwwLjt5r',
    };

    Map myBody = {
      "registration_ids": [
        "dY91C-BzSfq76vHSW412RP:APA91bEM4EZ7hmoCUUc4u0PvzuzctyP43whQAmen51OPxZ79V-U492U-UbHqbM7HHYf_-Vo8twX8pDNGJptmIW6viNtD02lmFRroNj0mpTNdTfZIfXRnRnfmuuP_WFbGDivCPkje96oG",
      ],
      "notification": {
        "title": "hello",
        "body": "New announcement assigned",
        "content_available": true,
        "priority": "high",
      },
      "data": {
        "priority": "high",
        "content_available": true,
        "bodyText": "New Announcement assigned",
        "organization": "Elementary school",
        "custom_key": "my_custom_val",
      },
    };

    var response = await http.post(Uri.parse(url),
        headers: myHeaders, body: jsonEncode(myBody));

    if (response.statusCode == 200) {
      print("FCM Successfully done...");
      print(response.body);
    }
  }
}
