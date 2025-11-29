import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'dart:math';
import '../model_services/tflite_service.dart';
import 'constants.dart';
import 'main_screen.dart';

class ResultScreen extends StatelessWidget {
  final List<Uint8List> drawings;
  final List<String> predictions;
  final TFLiteService tfliteService;
  final List<String> targetObjects;

  const ResultScreen({
    Key? key,
    required this.drawings,
    required this.predictions,
    required this.tfliteService,
    required this.targetObjects,
  }) : super(key: key);

  String _getRandomObject() {
    return objects.isNotEmpty ? objects[Random().nextInt(objects.length)] : "Белгісіз нысан";
  }

  @override
  Widget build(BuildContext context) {
    int correctCount = 0;
    int minLength = [drawings.length, predictions.length, targetObjects.length].reduce(min);

    for (int i = 0; i < minLength; i++) {
      String target = targetObjects[i].toLowerCase().trim();
      String prediction = predictions[i].toLowerCase().trim();
      if (prediction.contains(target)) {
        correctCount++;
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.yellow,
          centerTitle: true,  // Центрируем заголовок
          title: const Text(
            "Ойын аяқталды!",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold, // Жирный шрифт
              fontSize: 20, // можно чуть увеличить размер, если хочешь
            ),
          ),
          elevation: 0,
        ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Сіз ${drawings.length} сурет салдыңыз!",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // GridView.builder(
            //   shrinkWrap: true,
            //   physics: const NeverScrollableScrollPhysics(),
            //   gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            //     crossAxisCount: 2,
            //     crossAxisSpacing: 15,
            //     mainAxisSpacing: 15,
            //     childAspectRatio: 0.8, // Чуть выше карточки
            //   ),
            //   itemCount: drawings.length,
            //   itemBuilder: (context, index) {
            //     String predictionText = index < predictions.length
            //         ? predictions[index]
            //         : "Болжам жоқ";
            //
            //     return Container(
            //       decoration: BoxDecoration(
            //         border: Border.all(color: Colors.black, width: 2),
            //         borderRadius: BorderRadius.circular(12),
            //         color: Colors.grey[100],
            //       ),
            //       padding: const EdgeInsets.all(8.0),
            //       child: Column(
            //         children: [
            //           Text(
            //             "Салу керек еді: ${index < targetObjects.length ? targetObjects[index] : "Белгісіз"}",
            //             style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            //             textAlign: TextAlign.center,
            //           ),
            //           const SizedBox(height: 4),
            //           Expanded(
            //             child: Container(
            //               width: double.infinity,
            //               padding: const EdgeInsets.all(4.0),
            //               child: Image.memory(
            //                 drawings[index],
            //                 fit: BoxFit.contain,
            //               ),
            //             ),
            //           ),
            //           const SizedBox(height: 4),
            //           Text(
            //             "Нейрондық желінің болжамы: $predictionText",
            //             style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            //             textAlign: TextAlign.center,
            //           ),
            //         ],
            //       ),
            //     );
            //   },
            // ),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 0.8,
              ),
              itemCount: drawings.length,
              itemBuilder: (context, index) {
                String targetText = (index < targetObjects.length) ? targetObjects[index] : "Белгісіз";
                String predictionText = (index < predictions.length) ? predictions[index] : "Болжам жоқ";
                Uint8List? drawing = (index < drawings.length) ? drawings[index] : null;

                return Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 2),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[100],
                  ),
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Text(
                        "Салу керек еді: $targetText",
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: drawing != null
                            ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(4.0),
                          child: Image.memory(
                            drawing,
                            fit: BoxFit.contain,
                          ),
                        )
                            : const Text("Сурет жоқ"),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Нейрондық желінің болжамы: $predictionText",
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
            Text(
              "Дұрыс табылды: $correctCount / ${drawings.length}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MainScreen(
                      currentRound: 0,
                      drawings: [],
                      predictions: [],
                      objectToDraw: _getRandomObject(),
                      tfliteService: tfliteService,
                      targetObjects: [],
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow,
                minimumSize: const Size(180, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Қайта ойнау",
                style: TextStyle(fontSize: 18, color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
