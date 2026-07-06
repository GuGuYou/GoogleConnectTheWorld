import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/virtual_avatar.dart';

class AvatarGenerationException implements Exception {
  final String message;
  const AvatarGenerationException(this.message);

  @override
  String toString() => message;
}

abstract class AvatarGeneratorRepository {
  Future<AvatarGenerationResult> generate(AvatarGenerationRequest request);
}

class MockAvatarGeneratorRepository implements AvatarGeneratorRepository {
  @override
  Future<AvatarGenerationResult> generate(AvatarGenerationRequest request) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (request.referenceImagePath.trim().isEmpty) {
      throw const AvatarGenerationException('reference_image_required');
    }
    final seed = '${request.style.name}_${request.referenceImagePath}_${DateTime.now().millisecondsSinceEpoch}';
    return AvatarGenerationResult(
      prompt: request.prompt,
      avatar: VirtualAvatar.seeded(seed, style: request.style).copyWith(
        source: AvatarSource.gemini,
        generatedPrompt: request.prompt,
      ),
    );
  }
}

/// 真实实现：把参考图片 + 风格 + prompt 上传到自建后端，
/// 后端持有 Google Cloud 服务账号密钥代为调用 Vertex AI Gemini 图生图模型。
/// 客户端永远不接触任何 Google 凭据。
class GeminiAvatarGeneratorRepository implements AvatarGeneratorRepository {
  final Uri endpoint;
  final String userToken;
  final http.Client _http;

  GeminiAvatarGeneratorRepository({
    required this.endpoint,
    required this.userToken,
    http.Client? client,
  }) : _http = client ?? http.Client();

  @override
  Future<AvatarGenerationResult> generate(AvatarGenerationRequest request) async {
    final path = request.referenceImagePath.trim();
    if (path.isEmpty) {
      throw const AvatarGenerationException('reference_image_required');
    }

    final file = File(path);
    if (!await file.exists()) {
      throw const AvatarGenerationException('reference_image_required');
    }

    final bytes = await file.readAsBytes();
    final mimeType = _guessMimeType(path);

    http.Response response;
    try {
      response = await _http
          .post(
            endpoint,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'image_base64': base64Encode(bytes),
              'mime_type': mimeType,
              'style': request.style.name,
              'prompt': request.prompt,
              'user_token': userToken,
            }),
          )
          .timeout(const Duration(seconds: 60));
    } catch (e) {
      throw AvatarGenerationException('network_error: $e');
    }

    Map<String, dynamic> data;
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw AvatarGenerationException('bad_response (${response.statusCode})');
    }

    if (response.statusCode != 200 || data['success'] != true) {
      final detail = data['detail']?.toString() ?? 'generate_failed (${response.statusCode})';
      throw AvatarGenerationException(detail);
    }

    final imageBase64 = data['image_base64'] as String?;
    if (imageBase64 == null || imageBase64.isEmpty) {
      throw const AvatarGenerationException('empty_image');
    }
    final outMime = data['mime_type'] as String? ?? 'image/png';

    final seed = 'gemini_${DateTime.now().millisecondsSinceEpoch}';
    return AvatarGenerationResult(
      prompt: request.prompt,
      avatar: VirtualAvatar.seeded(seed, style: request.style).copyWith(
        source: AvatarSource.gemini,
        generatedPrompt: request.prompt,
        generatedImageUrl: 'data:$outMime;base64,$imageBase64',
      ),
    );
  }

  String _guessMimeType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}
