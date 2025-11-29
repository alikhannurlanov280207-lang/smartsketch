import 'package:firebase_storage/firebase_storage.dart';

class FirebaseService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Функция для получения URL изображений из папки "quickdraw"
  Future<List<String>> getImageUrls() async {
    List<String> imageUrls = [];

    try {
      // Получаем ссылку на папку "quickdraw"
      ListResult result = await _storage.ref('quickdraw').listAll();

      // Для каждого файла в папке получаем его URL
      for (var item in result.items) {
        String downloadURL = await item.getDownloadURL();
        imageUrls.add(downloadURL);
      }
    } catch (e) {
      print("Error fetching images: $e");
    }

    return imageUrls;
  }
}
