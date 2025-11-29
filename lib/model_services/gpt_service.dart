///Open ai
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class GPTService {
  final String apiKey = '';

  Future<String> analyzeDrawingFromImage(
      Uint8List pngBytes, String objectToDraw) async {
    // Преобразуем в Base64 Data URI
    final base64Image = base64Encode(pngBytes);
    final dataUri = 'data:image/png;base64,$base64Image';

    final List<String> allowedLabels = [];

    final messages = [
      {
        "role": "user",
        "content": [
          {
            "type": "text",
            "text": """
You are a visual sketch recognition AI.

A human drew a black sketch on a white canvas. Your goal is to honestly describe what you actually see, and guess what the drawing might represent — based only on visual features.

The player was told to draw: "$objectToDraw". However, you MUST IGNORE this instruction if the sketch clearly depicts something else. NEVER say the drawing matches "$objectToDraw" unless you are absolutely sure from the visual data alone.

⚠️ If you falsely claim the drawing matches "$objectToDraw" when it does not, imagine you get a penalty or negative feedback. Always prioritize truthful and accurate recognition over matching the prompt.

🧠 Instructions:
1. Describe what is visually drawn (shapes, structure).
2. Guess 1–3 most likely object names — based only on the sketch.
3. Clearly state whether this looks like "$objectToDraw" or not.

look, if the photo that the user draws doesn't look like the hint that I'm showing you, answer honestly so that there are no deceptions.

DO NOT try to force the sketch to match "$objectToDraw" if it visually doesn't.

Respond in Kazakh, short paragraph.

Format:
"Суретте [не көрініп тұр]. Бұл [неге ұқсайды]. Менің ойымша бұл: [1–3 нысан]"
"""
          },
          {
            "type": "image_url",
            "image_url": {"url": dataUri}
          }
        ]
      }
    ];

    final body = jsonEncode({
      "model": "gpt-4o",
      "messages": messages,
      "max_tokens": 70,
    });

    final response = await http.post(
      Uri.parse("https://api.openai.com/v1/chat/completions"),
      headers: {
        "Authorization": "Bearer $apiKey",
        "Content-Type": "application/json",
      },
      body: body,
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final rawContent = decoded['choices'][0]['message']['content'];
      final guess = utf8.decode(rawContent.toString().codeUnits).trim();
      debugPrint("🧠 GPT (vision) guess: $guess");
      return guess;
    } else {
      debugPrint(
          '❌ GPT Vision API error: ${response.statusCode} ${response.body}');
      return 'Қате';
    }
  }
}
