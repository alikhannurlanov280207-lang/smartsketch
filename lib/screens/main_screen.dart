import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../model_services/tflite_service.dart';
import 'drawing_screen.dart';
import 'result_screen.dart';
import 'constants.dart';

class MainScreen extends StatefulWidget {
  final int currentRound;
  final List<Uint8List> drawings;
  final List<String> predictions;
  final String objectToDraw;
  final TFLiteService tfliteService;
  final List<String> targetObjects;

  const MainScreen({
    Key? key,
    this.currentRound = 0,
    required this.drawings,
    required this.predictions,
    required this.objectToDraw,
    required this.tfliteService,
    required this.targetObjects,
  }) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int currentRound;

  @override
  void initState() {
    super.initState();
    currentRound = widget.currentRound;
  }

  void startDrawing() {
    if (currentRound < 6) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DrawingScreen(
            objectToDraw: widget.objectToDraw,
            round: currentRound + 1,
            drawings: List.from(widget.drawings),
            predictions: List.from(widget.predictions),
            tfliteService: widget.tfliteService,
            targetObjects: widget.targetObjects,
            onRoundComplete: (Uint8List drawing, String prediction) {
              setState(() {
                currentRound += 1;
                widget.drawings.add(drawing);
                widget.predictions.add(prediction);
              });

              if (currentRound < 6) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MainScreen(
                      currentRound: currentRound,
                      drawings: widget.drawings,
                      predictions: widget.predictions,
                      objectToDraw: getRandomObject(),
                      tfliteService: widget.tfliteService,
                      targetObjects: widget.targetObjects,
                    ),
                  ),
                );
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ResultScreen(
                      drawings: widget.drawings,
                      predictions: widget.predictions,
                      tfliteService: widget.tfliteService,
                      targetObjects: widget.targetObjects,
                    ),
                  ),
                );
              }
            },
          ),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            drawings: widget.drawings,
            predictions: widget.predictions,
            tfliteService: widget.tfliteService,
            targetObjects: widget.targetObjects,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.yellow,
      appBar: AppBar(
        backgroundColor: Colors.yellow,
        title: const Text(
          "SmartSketch",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Сурет ${currentRound + 1}/6",
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              "${widget.objectToDraw} - салыңыз",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: startDrawing,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(150, 50),
              ),
              child: const Text(
                "ОК",
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
