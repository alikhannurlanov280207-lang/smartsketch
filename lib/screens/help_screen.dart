import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Белый фон
      appBar: AppBar(
        title: const Text(
          "Ойын туралы",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22, // Чуть больше размер
          ),
        ),
        backgroundColor: Colors.yellow, // Желтый фон
        elevation: 0,
        centerTitle: true, // Центрируем заголовок
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 10), // Отступ сверху
            const Text(
              "Бұл қандай ойын?",
              style: TextStyle(
                fontSize: 24, // Чуть крупнее
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20), // Отступ перед основным текстом
            Expanded(
              child: Align(
                alignment: Alignment.topCenter, // Размещаем текст ниже
                child: Text(
                  "SmartSketch ойыны машиналық оқыту технологияларын пайдаланады. "
                      "Сіз затты сызасыз, ал нейрондық желі оның не екенін анықтауға тырысады. "
                      "Оның барлық әрекеттері сәтті бола бермейді. Неғұрлым көп ойнасаңыз, желі соғұрлым көп біледі. "
                      "Қазіргі уақытта ол 50 заттарды таниды, "
                      "бірақ уақыт өте келе оның тізімі кеңейеді. Бұл ойын – машиналық оқытудың қызықты бола алатынының мысалы.",
                  style: TextStyle(
                    fontSize: 18, // Немного крупнее
                    color: Colors.black54, // Менее насыщенный черный
                    height: 1.5, // Чуть больше межстрочный интервал
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
