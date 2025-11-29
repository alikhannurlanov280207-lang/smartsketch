import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

// class TFLiteService {
//   Interpreter? _interpreter;
//   List<String> _labels = [];
//   static const int inputSize = 28; // Размер изображения 28x28
//
//   /// Загрузка новой модели и меток
//   Future<void> loadModel() async {
//     try {
//       _interpreter = await Interpreter.fromAsset('assets/model100.tflite'); // 🟡 Новый путь к модели
//       _labels = await _loadLabels('labels100.txt'); // 🟡 Новый файл меток
//       debugPrint('✅ Модель model100.tflite и labels100.txt успешно загружены!');
//     } catch (e) {
//       debugPrint('❌ Ошибка загрузки модели или меток: $e');
//     }
//   }
//
//   Future<List<String>> _loadLabels(String fileName) async {
//     try {
//       final rawLabels = await rootBundle.loadString('assets/$fileName');
//       return rawLabels.split('\n').where((label) => label.isNotEmpty).toList();
//     } catch (e) {
//       debugPrint('❌ Ошибка загрузки меток: $e');
//       return [];
//     }
//   }

class TFLiteService {
  Interpreter? _interpreter;
  List<String> _labels = [];
  static const int inputSize = 28; // Размер изображения 28x28

  /// Загрузка модели и меток
  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/model345.tflite');
      _labels = await _loadLabels('labels.txt');
      debugPrint('✅ Модель и метки успешно загружены!');
    } catch (e) {
      debugPrint('❌ Ошибка загрузки модели: $e');
    }
  }

  /// Загрузка списка меток
  Future<List<String>> _loadLabels(String fileName) async {
    try {
      final rawLabels = await rootBundle.loadString('assets/$fileName');
      return rawLabels.split('\n').where((label) => label.isNotEmpty).toList();
    } catch (e) {
      debugPrint('❌ Ошибка загрузки меток: $e');
      return [];
    }
  }

  /// Основной метод предсказания
  Future<String> predict(Uint8List imageData) async {
    if (_interpreter == null) {
      debugPrint('❌ Модель не загружена!');
      return 'Ошибка';
    }

    // ✅ Декодирование изображения
    img.Image? image = img.decodeImage(imageData);
    if (image == null) {
      debugPrint('⚠️ Ошибка: Не удалось декодировать изображение.');
      return 'Ошибка обработки изображения';
    }

    // 👇 ДОБАВЬ ЭТУ СТРОЧКУ
    debugPrint('📤 Исходный размер изображения: ${image.width}x${image.height}');

    // 📏 Обрезка и масштабирование
    img.Image processedImage = resizeWithPadding(image, inputSize);


    // ✅ Сохранение обработанного изображения для отладки
    await saveImage(processedImage, 'processed_image.png');

    // 📊 Преобразование изображения в массив и нормализация данных
    List<double> input = List.generate(
      processedImage.height * processedImage.width,
          (i) => img.getLuminance(
          processedImage.getPixelSafe(i % processedImage.width, i ~/ processedImage.width)) /
          255.0,
    );

    debugPrint('🖼 Размер изображения: ${processedImage.width}x${processedImage.height}');
    debugPrint('🔳 Первые 10 пикселей: ${input.sublist(0, 10)}');

    // 📡 Подготовка входного тензора
    var inputTensor = input.reshape([1, inputSize, inputSize, 1]);
    var outputTensor = List.filled(_labels.length, 0.0).reshape([1, _labels.length]);

    try {
      // 🎯 Запуск модели
      _interpreter!.run(inputTensor, outputTensor);
    } catch (e) {
      debugPrint('❌ Ошибка запуска модели: $e');
      return 'Ошибка предсказания';
    }

    // 📊 Преобразование результата
    List<double> predictions = List<double>.from(outputTensor[0]);

    if (predictions.any((p) => p.isNaN)) {
      debugPrint('❌ Предсказания содержат NaN!');
      return 'Ошибка предсказания';
    }

    // 🔎 Индекс с максимальной вероятностью
    int predictedIndex = predictions.indexOf(predictions.reduce((a, b) => a > b ? a : b));
    double confidence = predictions[predictedIndex] * 100;

    // ⛔ Если уверенность слишком низкая — не показываем
    // if (confidence < 50.0) {
    //   debugPrint('⚠️ Низкая уверенность: $confidence% — Предсказание скрыто.');
    //   return ''; // Или 'Болжам жоқ'
    // }

    debugPrint('📈 Все вероятности: $predictions');
    debugPrint('🔮 Итоговое предсказание: ${_labels[predictedIndex]} с вероятностью ${confidence.toStringAsFixed(2)}%');

    // 📝 Результат предсказания
    String result = predictedIndex < _labels.length ? _labels[predictedIndex] : 'Неизвестный объект';

    // ✅ Сохранение результата в лог
    await savePredictionToLog(result, confidence);

    return result;
  }

  /// 🎨 Обрезка, изменение размера и центрирование изображения
  img.Image resizeWithPadding(img.Image image, int targetSize) {
    // Определяем размер фиксированной центральной области (90% от исходного)
    int cropSize = (image.width * 0.9).toInt();
    if (cropSize > image.height) cropSize = image.height; // Чтобы не выйти за границы

    // Смещения для центрирования
    int offsetX = (image.width - cropSize) ~/ 2;
    int offsetY = (image.height - cropSize) ~/ 2;

    // ✂️ Обрезаем фиксированную центральную область
    img.Image cropped = img.copyCrop(
      image,
      x: offsetX,
      y: offsetY,
      width: cropSize,
      height: cropSize,
    );

    // 📏 Изменение размера изображения
    img.Image resized = img.copyResize(
      cropped,
      width: targetSize,
      height: targetSize,
    );

    // 🎨 Центрирование на белом фоне
    img.Image padded = img.Image(width: targetSize, height: targetSize, numChannels: 3);

    // ✅ Заполняем фон белым цветом вручную
    final img.Color white = img.ColorUint8.rgb(255, 255, 255);
    for (int y = 0; y < targetSize; y++) {
      for (int x = 0; x < targetSize; x++) {
        padded.setPixel(x, y, white);
      }
    }

    int finalOffsetX = ((targetSize - resized.width) / 2).round();
    int finalOffsetY = ((targetSize - resized.height) / 2).round();
    img.compositeImage(padded, resized, dstX: finalOffsetX, dstY: finalOffsetY);

    return padded;
  }


  /// 📥 Сохранение обработанного изображения в память устройства
  Future<void> saveImage(img.Image image, String fileName) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final path = '${appDir.path}/$fileName';
      await File(path).writeAsBytes(img.encodePng(image));
      debugPrint('✅ Изображение сохранено в: $path');
    } catch (e) {
      debugPrint('❌ Ошибка сохранения изображения: $e');
    }
  }

  /// 📝 Сохранение предсказания в лог
  Future<void> savePredictionToLog(String prediction, double confidence) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final logPath = '${appDir.path}/predictions_log.txt';
      final logFile = File(logPath);
      String timestamp = DateTime.now().toIso8601String();
      String logEntry =
          '[$timestamp] Предсказание: $prediction, Вероятность: ${confidence.toStringAsFixed(2)}%\n';
      await logFile.writeAsString(logEntry, mode: FileMode.append);
      debugPrint('✅ Предсказание сохранено в log');
    } catch (e) {
      debugPrint('❌ Ошибка сохранения предсказаний: $e');
    }
  }

  /// 🛑 Закрытие интерпретатора при завершении
  void dispose() {
    if (_interpreter != null) {
      _interpreter!.close();
      _interpreter = null;
      debugPrint('🛑 Интерпретатор закрыт.');
    }
  }
}