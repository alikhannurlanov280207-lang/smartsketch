import 'package:flutter/material.dart';
import 'model_services/tflite_service.dart';
import 'screens/start_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализируем Firebase
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Инициализируем TFLiteService перед запуском приложения
  TFLiteService tfliteService = TFLiteService();
  await tfliteService.loadModel();

  runApp(MyApp(tfliteService: tfliteService));
}

class MyApp extends StatelessWidget {
  final TFLiteService tfliteService;

  const MyApp({Key? key, required this.tfliteService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quick Draw!',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: StartScreen(tfliteService: tfliteService), // Передаем tfliteService в StartScreen
    );
  }
}
