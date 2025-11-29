import 'package:flutter/material.dart';
import 'dart:math';
import '../model_services/tflite_service.dart';
import 'main_screen.dart';
import 'constants.dart';
import 'help_screen.dart';
import 'dataset_screen.dart';

class StartScreen extends StatelessWidget {
  final TFLiteService tfliteService;

  const StartScreen({Key? key, required this.tfliteService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "SmartSketch",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.help_outline, color: Colors.black, size: 28),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HelpScreen()),
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 65.0),
        child: SingleChildScrollView(  // Добавляем прокручиваемую область
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Image.asset(
                'assets/logo.png',
                height: 400,
                width: double.infinity,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 1),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  'Нейрондық желі суреттерді тануды үйрене алады ма?\n'
                      'SmartSketch — бұл жасанды интеллектіні суреттер арқылы үйретуге арналған мобильді қосымша!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DatasetScreen()),  // Переход на новую страницу
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 5,
                ),
                child: const Text(
                  'Суреттер түрінде деректер жиынтығы',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 17, color: Colors.white),
                ),
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MainScreen(
                        currentRound: 0,
                        drawings: [],
                        predictions: [],
                        objectToDraw: getRandomObject(),
                        tfliteService: tfliteService,
                        targetObjects: [],
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  backgroundColor: Colors.yellow,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 5,
                ),
                child: const Text(
                  'Бастау',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 17, color: Colors.black),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
