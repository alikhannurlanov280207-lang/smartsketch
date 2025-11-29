import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import '../model_services/labels_translations.dart';
import '../model_services/tflite_service.dart';
import '../model_services/gpt_service.dart';
import 'drawing_painter.dart';
import 'main_screen.dart';
import 'result_screen.dart';
import 'constants.dart';
import 'package:image/image.dart' as img;
import 'dart:convert'; // для base64Encode


class DrawingScreen extends StatefulWidget {
  final String objectToDraw;
  final int round;
  final Function(Uint8List, String) onRoundComplete;
  final List<Uint8List> drawings;
  final List<String> predictions;
  final TFLiteService tfliteService;
  final List<String> targetObjects;

  const DrawingScreen({
    required this.objectToDraw,
    required this.round,
    required this.onRoundComplete,
    required this.drawings,
    required this.predictions,
    required this.tfliteService,
    required this.targetObjects,
    super.key,
  });

  @override
  _DrawingScreenState createState() => _DrawingScreenState();
}

Map<String, dynamic> processImageInBackground(Uint8List imageBytes) {
  final img.Image? decodedImage = img.decodeImage(imageBytes);
  if (decodedImage == null) {
    throw Exception("Image decoding failed");
  }

  int cropSize = 300;
  int offsetX = ((decodedImage.width - cropSize) / 2).round();
  int offsetY = ((decodedImage.height - cropSize) / 2).round();

  img.Image cropped = img.copyCrop(decodedImage, x: offsetX, y: offsetY, width: cropSize, height: cropSize);
  img.Image resized = img.copyResize(cropped, width: 28, height: 28);

  Uint8List processedBytes = Uint8List.fromList(img.encodePng(resized));

  return {
    'processedBytes': processedBytes,
  };
}

class _DrawingScreenState extends State<DrawingScreen> {
  int timeLeft = 20;
  late Timer timer;
  List<Offset?> points = [];
  final GlobalKey _globalKey = GlobalKey();
  //List<String> livePredictions = [];
  String gptDescription = "";
  final GPTService gptService = GPTService();
  Timer? gptTimer; // для GPT
  bool isGptProcessing = false; // 🔧 Добавь ЭТО сюда

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) => _setDrawingArea());

    // Timer.periodic(const Duration(seconds: 2), (_) async {
    //   if (!mounted || points.whereType<Offset>().length < 5) return;
    //
    //   RenderRepaintBoundary? boundary = _globalKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    //   if (boundary == null) return;
    //
    //   ui.Image image = await boundary.toImage(pixelRatio: 1.0);
    //   ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    //   if (byteData == null) return;
    //
    //   Uint8List pngBytes = byteData.buffer.asUint8List();
    //   img.Image? decodedImage = img.decodeImage(pngBytes);
    //   if (decodedImage == null) return;
    //
    //   // Обрезаем и ресайзим
    //   int cropSize = 280;
    //   int offsetX = ((decodedImage.width - cropSize) / 2).round();
    //   int offsetY = ((decodedImage.height - cropSize) / 2).round();
    //   img.Image cropped = img.copyCrop(decodedImage, x: offsetX, y: offsetY, width: cropSize, height: cropSize);
    //   img.Image resized = img.copyResize(cropped, width: 28, height: 28);
    //   Uint8List processedBytes = Uint8List.fromList(img.encodePng(resized));
    //
    //   // Предсказание
    //   String prediction = await widget.tfliteService.predict(processedBytes);
    //   String translatedPrediction = translateLabel(prediction);
    //
    //   setState(() {
    //     livePredictions = [translatedPrediction];
    //   });
    // });

    // Запускаем GPT таймер один раз на каждые 5 секунд
    bool isGptProcessing = false;

    gptTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!mounted || timeLeft <= 3 || isGptProcessing || points.whereType<Offset>().length < 3) return;

      isGptProcessing = true;

      String? imageDataUri = await _convertImageToBase64();
      if (imageDataUri != null) {
        String gptGuess = await gptService.analyzeDrawingFromImage(
          base64Decode(imageDataUri.replaceFirst('data:image/png;base64,', '')),
          widget.objectToDraw,
        );
        if (mounted) {
          setState(() {
            gptDescription = gptGuess;
          });
        }
      }

      isGptProcessing = false;
    });
  }

  void _startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      setState(() {
        if (timeLeft > 1) {
          timeLeft--;

          // ⏱ Финальный запуск GPT за 3 секунды до конца
          if (timeLeft == 3) {
            _forceFinalGptPrediction();
          }

        } else {
          timer.cancel();
          _processDrawing(finalPrediction: true); // завершение раунда
        }
      });
    });
  }

  void _forceFinalGptPrediction() async {
    if (points.whereType<Offset>().length < 5 || isGptProcessing) return;

    isGptProcessing = true;

    String? imageDataUri = await _convertImageToBase64();
    if (imageDataUri != null) {
      String gptGuess = await gptService.analyzeDrawingFromImage(
        base64Decode(imageDataUri.replaceFirst('data:image/png;base64,', '')),
        widget.objectToDraw,
      );
      if (mounted) {
        setState(() {
          gptDescription = gptGuess; // ✅ отображается сразу
        });
      }
    }

    isGptProcessing = false;
  }

  Future<String?> _convertImageToBase64() async {
    RenderRepaintBoundary? boundary = _globalKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;

    ui.Image image = await boundary.toImage(pixelRatio: 10.0);
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return null;

    Uint8List pngBytes = byteData.buffer.asUint8List();
    String base64String = base64Encode(pngBytes);
    return 'data:image/png;base64,$base64String';
  }

  // Future<void> _processDrawing({bool finalPrediction = false}) async {
  //   try {
  //     // Убираем проверку на пустые точки, чтобы всегда обрабатывать, даже если ничего не нарисовано
  //     RenderRepaintBoundary? boundary = _globalKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
  //     if (boundary == null) return;
  //
  //     // Создаем изображения для дальнейшей обработки
  //     ui.Image image = await boundary.toImage(pixelRatio: 1.0);
  //     ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  //     if (byteData == null) return;
  //
  //     ui.Image bigImage = await boundary.toImage(pixelRatio: 10.0);
  //     ByteData? bigByteData = await bigImage.toByteData(format: ui.ImageByteFormat.png);
  //     if (bigByteData == null) return;
  //
  //     Uint8List bigPngBytes = bigByteData.buffer.asUint8List();
  //     Uint8List pngBytes = byteData.buffer.asUint8List();
  //     img.Image? decodedImage = img.decodeImage(pngBytes);
  //
  //     if (decodedImage == null) return;
  //
  //     // Обрезаем и масштабируем изображение
  //     int cropSize = 300;
  //     int offsetX = ((decodedImage.width - cropSize) / 2).round();
  //     int offsetY = ((decodedImage.height - cropSize) / 2).round();
  //
  //     img.Image cropped = img.copyCrop(decodedImage, x: offsetX, y: offsetY, width: cropSize, height: cropSize);
  //     img.Image resized = img.copyResize(cropped, width: 28, height: 28);
  //
  //     // Сохраняем изображения для отладки
  //     await saveDebugImage(cropped, 'cropped_image.png');
  //     await saveDebugImage(resized, 'resized_image.png');
  //
  //     Uint8List processedBytes = Uint8List.fromList(img.encodePng(resized));
  //     String prediction = await widget.tfliteService.predict(processedBytes);
  //     String translatedPrediction = translateLabel(prediction);
  //
  //     if (!mounted) return;
  //
  //     setState(() {
  //       if (finalPrediction) {
  //         List<Uint8List> updatedDrawings = List.from(widget.drawings)..add(bigPngBytes);
  //         List<String> updatedPredictions = List.from(widget.predictions)..add(translatedPrediction);
  //
  //         // Передаем результаты в родительский экран
  //         widget.onRoundComplete(pngBytes, translatedPrediction);
  //         if (widget.round < 6) {
  //           Navigator.pushReplacement(
  //             context,
  //             MaterialPageRoute(
  //               builder: (context) => MainScreen(
  //                 currentRound: widget.round,
  //                 drawings: updatedDrawings,
  //                 predictions: updatedPredictions,
  //                 objectToDraw: getRandomObject(),
  //                 tfliteService: widget.tfliteService,
  //               ),
  //             ),
  //           );
  //         } else {
  //           Navigator.pushReplacement(
  //             context,
  //             MaterialPageRoute(
  //               builder: (context) => ResultScreen(
  //                 drawings: updatedDrawings,
  //                 predictions: updatedPredictions,
  //                 tfliteService: widget.tfliteService,
  //               ),
  //             ),
  //           );
  //         }
  //       }
  //     });
  //   } catch (e) {
  //     debugPrint("❌ Ошибка обработки рисунка: $e");
  //   }
  // }
  Future<void> _processDrawing({bool finalPrediction = false}) async {
    try {
      RenderRepaintBoundary? boundary = _globalKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      // ✅ Большое изображение — используем для GPT
      ui.Image bigImage = await boundary.toImage(pixelRatio: 2.0);
      ByteData? bigByteData = await bigImage.toByteData(format: ui.ImageByteFormat.png);
      if (bigByteData == null) return;
      Uint8List bigPngBytes = bigByteData.buffer.asUint8List();

      // ✅ Маленькое изображение — используем для tflite
      // ui.Image smallImage = await boundary.toImage(pixelRatio: 1.0);
      // ByteData? byteData = await smallImage.toByteData(format: ui.ImageByteFormat.png);
      // if (byteData == null) return;
      // Uint8List pngBytes = byteData.buffer.asUint8List();

      // ✅ Обрабатываем для tflite
      // final result = await compute(processImageInBackground, pngBytes);
      // Uint8List processedBytes = result['processedBytes'];

      if (!mounted) return;

      setState(() {
        if (finalPrediction) {
          // List<Uint8List> updatedDrawings = List.from(widget.drawings)..add(bigPngBytes);
          // List<String> updatedPredictions = List.from(widget.predictions)..add(gptDescription.isNotEmpty ? gptDescription : "Анықталмады");

          List<Uint8List> updatedDrawings = List.from(widget.drawings)..add(bigPngBytes);
          List<String> updatedPredictions = List.from(widget.predictions)..add(gptDescription.isNotEmpty ? gptDescription : "Анықталмады",);
          List<String> updatedTargets = List.from(widget.targetObjects)..add(widget.objectToDraw);

          //widget.onRoundComplete(pngBytes, gptDescription.isNotEmpty ? gptDescription : "Анықталмады");
          widget.onRoundComplete(bigPngBytes, gptDescription.isNotEmpty ? gptDescription : "Анықталмады");

          if (widget.round < 6) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => MainScreen(
                  currentRound: widget.round,
                  drawings: updatedDrawings,
                  predictions: updatedPredictions,
                  objectToDraw: getRandomObject(),
                  tfliteService: widget.tfliteService,
                  targetObjects: updatedTargets,
                ),
              ),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ResultScreen(
                  drawings: updatedDrawings,
                  predictions: updatedPredictions,
                  tfliteService: widget.tfliteService,
                  targetObjects: updatedTargets,
                ),
              ),
            );
          }
        }
      });
    } catch (e) {
      debugPrint("❌ Ошибка обработки рисунка: $e");
    }
  }

  void _setDrawingArea() {
    final RenderBox? box = _globalKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null) {
      setState(() {
        debugPrint('🖼️ Drawing area size: ${box.size.width}x${box.size.height}');
      });
    }
  }


  Future<void> saveDebugImage(img.Image image, String fileName) async {
    final appDir = await getApplicationDocumentsDirectory();
    final path = '${appDir.path}/$fileName';
    await File(path).writeAsBytes(img.encodePng(image));
    debugPrint('✅ Изображение сохранено для отладки в: $path');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.yellow,
        elevation: 0,
        title: Text(
          "Сурет ${widget.round}/6",
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold, // Перемещаем сюда fontWeight
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Text(
            "00:${timeLeft.toString().padLeft(2, '0')}",
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 10),
          Text(
            "${widget.objectToDraw} салыңыз",
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 10),
          _buildControls(),
          const SizedBox(height: 5),
          Expanded(
            child: Center(
              child: SizedBox(
                width: 280,
                height: 280,
                child: RepaintBoundary(
                  key: _globalKey,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        points.add(details.localPosition);
                      });
                    },
                    onPanEnd: (_) {
                      points.add(null);
                    },
                    child: CustomPaint(
                      size: const Size(280, 280),
                      painter: DrawingPainter(points),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _buildPredictionBox(),
          // if (gptDescription.isNotEmpty)
          //   Padding(
          //     padding: const EdgeInsets.all(10),
          //     child: Text(
          //       "🧠 GPT болжамы: $gptDescription",
          //       style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          //     ),
          //   ),
          const SizedBox(height: 1),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildButton(Icons.cleaning_services, "Өшіргіш", () {
          setState(() {
            points.clear();
          });
        }),
        const SizedBox(width: 20),
        _buildButton(Icons.skip_next, "Өткізу", () => _processDrawing(finalPrediction: true)),
        const SizedBox(width: 20),
        _buildButton(Icons.home, "Шығу", () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MainScreen(
                currentRound: 0,
                drawings: [],
                predictions: [],
                objectToDraw: getRandomObject(),
                tfliteService: widget.tfliteService,
                targetObjects: [],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildButton(IconData icon, String label, VoidCallback onPressed) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(20),
            backgroundColor: Colors.white,
            elevation: 5,
          ),
          child: Icon(icon, color: Colors.black, size: 27),
        ),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // Widget _buildPredictionBox() {
  //   return Container(
  //     height: 50,
  //     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
  //     alignment: Alignment.center,
  //     decoration: BoxDecoration(
  //       color: Colors.yellow[100],
  //       borderRadius: BorderRadius.circular(10),
  //     ),
  //     child: Center(
  //       child: Text(
  //         gptDescription.isEmpty ? "..." : gptDescription,
  //         style: const TextStyle(
  //           fontSize: 18,
  //           fontWeight: FontWeight.bold,
  //           color: Colors.black87,
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildPredictionBox() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.yellow[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          gptDescription.isEmpty ? "..." : gptDescription,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }


  img.Image invertImage(img.Image image) {
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        img.Pixel pixel = image.getPixel(x, y);
        int invertedRed = 255 - pixel.r.toInt();
        int invertedGreen = 255 - pixel.g.toInt();
        int invertedBlue = 255 - pixel.b.toInt();
        image.setPixelRgb(x, y, invertedRed, invertedGreen, invertedBlue);
      }
    }
    return image;
  }

  @override
  void dispose() {
    timer.cancel();
    gptTimer?.cancel(); // не забудь!
    super.dispose();
  }
}
