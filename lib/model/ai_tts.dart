import 'package:flutter/services.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiRepositoryImpl {
  final String apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  static const String modelName = 'gemini-2.0-flash';

  late final GenerativeModel _model;
  late final ChatSession _chatSession;
  final FlutterTts _flutterTts = FlutterTts();

  GeminiRepositoryImpl() {
    _model = GenerativeModel(
      model: modelName,
      apiKey: apiKey,
    );
  }

  @override
  Future<void> setSystemPrompt(String prompt) async {
    debugPrint("🔧 [Gemini] setSystemPrompt() called with prompt: $prompt");
    try {
      final String guideRunner =
      await rootBundle.loadString('assets/guideRunner.txt');
      final full = prompt + guideRunner;
      _chatSession = _model.startChat(history: [Content.text(full)]);
      debugPrint("🔧 [Gemini] chatSession initialized.");
    } catch (e, st) {
      debugPrint("❌ [Gemini] setSystemPrompt failed: $e\n$st");
      rethrow;
    }
  }

  // 사용자 메시지를 보내고, 스트림으로 응답 텍스트를 리턴
  @override
  Stream<String> sendMessage(String message) async* {
    final response = await _chatSession.sendMessage(Content.text(message));
    yield response.text ?? '응답을 생성할 수 없습니다.';
  }

  // TTS 엔진 초기 설정 (언어, 속도, 음높이, 볼륨 등)
  Future<void> initTts() async {
    await _flutterTts.setLanguage('ko-KR');
    await _flutterTts.setSpeechRate(1.0);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setVolume(1.0);

  }

  //텍스트를 음성으로 출력
  Future<void> speak(String text) async {
    await _flutterTts.speak(text);
  }
}
