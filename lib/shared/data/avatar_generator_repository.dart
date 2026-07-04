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

class GeminiAvatarGeneratorRepository implements AvatarGeneratorRepository {
  final Uri endpoint;

  const GeminiAvatarGeneratorRepository(this.endpoint);

  @override
  Future<AvatarGenerationResult> generate(AvatarGenerationRequest request) {
    throw UnimplementedError(
      'Call your backend proxy at $endpoint with prompt, style, and uploaded reference image. Do not put Gemini API keys in Flutter.',
    );
  }
}
