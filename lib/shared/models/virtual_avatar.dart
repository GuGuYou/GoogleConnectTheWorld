enum AvatarSource {
  local,
  gemini,
}

enum AvatarVisualStyle {
  cute,
  pixel,
}

class VirtualAvatar {
  final AvatarSource source;
  final AvatarVisualStyle style;
  final String seed;
  final int colorIndex;
  final int faceIndex;
  final int eyeIndex;
  final int mouthIndex;
  final int accessoryIndex;
  final String? generatedImageUrl;
  final String? generatedPrompt;

  const VirtualAvatar({
    required this.source,
    required this.style,
    required this.seed,
    required this.colorIndex,
    required this.faceIndex,
    required this.eyeIndex,
    required this.mouthIndex,
    required this.accessoryIndex,
    this.generatedImageUrl,
    this.generatedPrompt,
  });

  factory VirtualAvatar.seeded(String seed, {AvatarVisualStyle style = AvatarVisualStyle.cute}) {
    final hash = seed.hashCode.abs();
    return VirtualAvatar(
      source: AvatarSource.local,
      style: style,
      seed: seed,
      colorIndex: hash % 6,
      faceIndex: hash % 3,
      eyeIndex: hash % 4,
      mouthIndex: hash % 4,
      accessoryIndex: hash % 5,
    );
  }

  VirtualAvatar copyWith({
    AvatarSource? source,
    AvatarVisualStyle? style,
    String? seed,
    int? colorIndex,
    int? faceIndex,
    int? eyeIndex,
    int? mouthIndex,
    int? accessoryIndex,
    String? generatedImageUrl,
    String? generatedPrompt,
  }) {
    return VirtualAvatar(
      source: source ?? this.source,
      style: style ?? this.style,
      seed: seed ?? this.seed,
      colorIndex: colorIndex ?? this.colorIndex,
      faceIndex: faceIndex ?? this.faceIndex,
      eyeIndex: eyeIndex ?? this.eyeIndex,
      mouthIndex: mouthIndex ?? this.mouthIndex,
      accessoryIndex: accessoryIndex ?? this.accessoryIndex,
      generatedImageUrl: generatedImageUrl ?? this.generatedImageUrl,
      generatedPrompt: generatedPrompt ?? this.generatedPrompt,
    );
  }
}

class AvatarGenerationRequest {
  final AvatarVisualStyle style;
  final String referenceImagePath;

  const AvatarGenerationRequest({
    required this.style,
    required this.referenceImagePath,
  });

  String get stylePrompt => style == AvatarVisualStyle.pixel
      ? 'Convert the uploaded reference image into an 8-bit pixel art character avatar, square canvas, crisp blocks, limited palette, front-facing, clean background, no text, no photorealistic texture'
      : 'Convert the uploaded reference image into a cute 2D cartoon character avatar, rounded shapes, soft colors, clean vector-like illustration, front-facing, clean background, no text, no photorealistic texture';

  String get prompt => '$stylePrompt. Use the uploaded image only as visual identity reference. If no recognizable person or character can be derived, return an error instead of inventing an avatar.';
}

class AvatarGenerationResult {
  final VirtualAvatar avatar;
  final String prompt;

  const AvatarGenerationResult({required this.avatar, required this.prompt});
}
