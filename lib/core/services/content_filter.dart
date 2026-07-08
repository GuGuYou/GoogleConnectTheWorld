/// 内容审核服务：留言违规词拦截。
///
/// 当前为客户端第一道防线（内置词表），上线后切服务端审核。
///
/// 审核流程：
/// 用户提交留言 → checkContent(text)
///   ├─ PASS → isVisible=true，正常展示
///   └─ BLOCKED → isVisible=false，返回拦截原因
///
/// 后续升级路径：
/// - 服务端统一词表（Firestore/Remote Config 下发）
/// - 对接 Google Cloud Natural Language API（有毒内容检测）
/// - 人审队列（机审不确定的提交人工审核）
class ContentFilter {
  ContentFilter._();

  /// 审核结果
  static const String pass = 'PASS';
  static const String blockedSensitive = 'BLOCKED_SENSITIVE';
  static const String blockedSpam = 'BLOCKED_SPAM';

  /// 内置中文敏感词（示例，生产环境应从服务端下发完整词表）
  static final Set<String> _cnSensitiveWords = {
    // 人身攻击 / 辱骂
    '傻逼', '脑残', '废物', '垃圾人', '白痴', '蠢货', '智障',
    // 歧视性词汇
    '种族歧视', '地域黑',
    // 色情暗示
    '约炮', '一夜情', '嫖娼',
    // 暴力 / 违法
    '杀人', '自杀', '贩毒', '枪支',
  };

  /// 内置英文敏感词
  static final Set<String> _enSensitiveWords = {
    // Profanity
    'fuck', 'shit', 'asshole', 'bastard', 'bitch', 'damn',
    // Hate speech
    'nigger', 'faggot', 'retard',
    // Sexual
    'porn', 'sex', 'nude', 'naked',
    // Violence
    'kill yourself', 'terrorist',
  };

  /// 垃圾信息特征（短时高频重复文本）
  static final Set<String> _spamPatterns = {
    '加微信', '加我wx', '加我VX', '扫码', '关注公众号',
    '加QQ', '加我QQ', '点击链接', '免费领取', '赚钱',
    '兼职', '刷单', '代理',
  };

  /// 检查文本是否包含违规内容。
  ///
  /// 返回 (结果码, 拦截原因)。
  /// - PASS: 通过审核
  /// - BLOCKED_SENSITIVE: 包含敏感词
  /// - BLOCKED_SPAM: 疑似垃圾信息
  static (String code, String? reason) check(String text) {
    if (text.trim().isEmpty) {
      return (pass, null);
    }

    final lower = text.toLowerCase();

    // 1. 敏感词扫描（中文）
    for (final word in _cnSensitiveWords) {
      if (text.contains(word)) {
        return (blockedSensitive, '留言包含不当内容，请修改后重试');
      }
    }

    // 2. 敏感词扫描（英文）
    for (final word in _enSensitiveWords) {
      if (lower.contains(word)) {
        return (blockedSensitive, '留言包含不当内容，请修改后重试');
      }
    }

    // 3. 垃圾信息检测
    for (final pattern in _spamPatterns) {
      if (text.contains(pattern)) {
        return (blockedSpam, '留言疑似广告信息，请勿发布推广内容');
      }
    }

    return (pass, null);
  }

  /// 仅检查是否通过（简化接口）
  static bool isClean(String text) {
    final (code, _) = check(text);
    return code == pass;
  }
}
