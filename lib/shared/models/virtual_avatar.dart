enum AvatarSource {
  local,
  gemini,
  /// 用户导入的照片或内置预设图（generatedImageUrl 为 data:/asset: URI）。
  photo,
}

/// 默认预设头像（Frame 2 主视觉小男孩）。
const kDefaultAvatarAsset = 'asset:assets/images/avatars/default_boy.png';

enum AvatarVisualStyle {
  cute,
  pixel,
}

/// 角色形态：当前阶段仅支持人形，动物形态字段先预留，
/// 避免后续接入时需要改动核心模型 + 所有引用点。
enum AvatarBodyForm {
  human,
  animal,
}

class VirtualAvatar {
  final AvatarSource source;
  final AvatarVisualStyle style;
  final AvatarBodyForm bodyForm;
  final String seed;
  final int colorIndex;
  final int faceIndex;
  final int hairIndex;
  final int eyeIndex;
  final int mouthIndex;
  final int accessoryIndex;
  final int backgroundIndex;
  final String? generatedImageUrl;
  final String? generatedPrompt;

  const VirtualAvatar({
    required this.source,
    required this.style,
    this.bodyForm = AvatarBodyForm.human,
    required this.seed,
    required this.colorIndex,
    required this.faceIndex,
    this.hairIndex = 0,
    required this.eyeIndex,
    required this.mouthIndex,
    required this.accessoryIndex,
    this.backgroundIndex = 0,
    this.generatedImageUrl,
    this.generatedPrompt,
  });

  factory VirtualAvatar.seeded(String seed, {AvatarVisualStyle style = AvatarVisualStyle.cute, AvatarBodyForm bodyForm = AvatarBodyForm.human}) {
    final hash = seed.hashCode.abs();
    return VirtualAvatar(
      source: AvatarSource.local,
      style: style,
      bodyForm: bodyForm,
      seed: seed,
      colorIndex: hash % 6,
      faceIndex: hash % 5,
      // 1..5 —— 随机形象总是带发型（0 表示光头，仅手动可选）
      hairIndex: 1 + hash % 5,
      eyeIndex: hash % 5,
      mouthIndex: hash % 5,
      accessoryIndex: hash % 7,
      backgroundIndex: hash % 5,
    );
  }

  VirtualAvatar copyWith({
    AvatarSource? source,
    AvatarVisualStyle? style,
    AvatarBodyForm? bodyForm,
    String? seed,
    int? colorIndex,
    int? faceIndex,
    int? hairIndex,
    int? eyeIndex,
    int? mouthIndex,
    int? accessoryIndex,
    int? backgroundIndex,
    String? generatedImageUrl,
    String? generatedPrompt,
  }) {
    return VirtualAvatar(
      source: source ?? this.source,
      style: style ?? this.style,
      bodyForm: bodyForm ?? this.bodyForm,
      seed: seed ?? this.seed,
      colorIndex: colorIndex ?? this.colorIndex,
      faceIndex: faceIndex ?? this.faceIndex,
      hairIndex: hairIndex ?? this.hairIndex,
      eyeIndex: eyeIndex ?? this.eyeIndex,
      mouthIndex: mouthIndex ?? this.mouthIndex,
      accessoryIndex: accessoryIndex ?? this.accessoryIndex,
      backgroundIndex: backgroundIndex ?? this.backgroundIndex,
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

  /// 统一视觉风格："光遇"（Sky: Children of the Light）式可爱治愈风。
  /// 注：style 字段暂保留用于兼容旧数据/接口，但不再影响最终画风——
  /// 所有形象都应收敛到同一套光遇风视觉语言，避免"AI 味"过重、风格分裂。
  String get stylePrompt =>
      'Convert the uploaded reference image into a cute chibi-style 2D character avatar in the visual style of "Sky: Children of the Light" — small soft rounded body proportions, flowing hooded cape, gentle glowing eyes, warm ambient rim lighting, dreamy pastel color palette, soft watercolor-like shading, no sharp/hard edges, faint ethereal glowing particles, front-facing, clean simple background, no text, no photorealistic texture';

  String get prompt => '$stylePrompt. Use the uploaded image only as visual identity reference. If no recognizable person or character can be derived, return an error instead of inventing an avatar.';
}

class AvatarGenerationResult {
  final VirtualAvatar avatar;
  final String prompt;

  const AvatarGenerationResult({required this.avatar, required this.prompt});
}
