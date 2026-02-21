import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:strife/page/start/start_page.dart';
import 'package:strife/themes/gradient_theme.dart';
import 'firebase/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:strife/page/home/home_page.dart';
//import 'package:permission_handler/permission_handler.dart';

/*Future<void> _checkPermissions() async {
  var status = await Permission.bluetooth.request();
  if (status.isPermanentlyDenied) {
    print('Bluetooth Permission disabled');
  }
  status = await Permission.bluetoothConnect.request();
  if (status.isPermanentlyDenied) {
    print('Bluetooth Connect Permission disabled');
  }
}*/

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  //await _checkPermissions();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        extensions: const [
          GradientTheme(
            mainGradient: LinearGradient(
              colors: [Color(0xFFB91ED0), Color(0xFF5E0F6A)],
            ),
          ),
        ],
        brightness: Brightness.light,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
          if (snapshot.hasError) {
            return const Text('Что-то пошло не так');
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Text("Загрука...");
          }

          if (!snapshot.hasData) {
            return StartPage();
          }

          return HomePage();
        },
      ),
    );
  }
}
