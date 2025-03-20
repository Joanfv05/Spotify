import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'audio_service.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final audioService = AudioService();

  runApp(
    ChangeNotifierProvider.value(
      value: audioService,
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mi App de Música',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: WillPopScope(
        onWillPop: () async {
          // Minimizar la app en lugar de cerrarla
          await SystemNavigator.pop();
          return false;
        },
        child: HomeScreen(),
      ),
    );
  }
}