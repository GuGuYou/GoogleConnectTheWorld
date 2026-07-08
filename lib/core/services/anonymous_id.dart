import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/locale_provider.dart';

/// 匿名身份服务：三层匿名机制的核心实现。
///
/// 三层匿名设计：
/// ┌─ 第 1 层（客户端）───────────────────────────┐
/// │  只持有 device_token（16 字符随机 hex）      │
/// │  无手机号/邮箱/真实姓名                        │
/// └─────────────────────────────────────────────┘
///            ↓
/// ┌─ 第 2 层（服务端通信）───────────────────────┐
/// │  user_id = sha256(device_token + salt)       │
/// │  所有 API 只用 user_id，不传 device_token    │
/// │  不记 IP、设备指纹                            │
/// └─────────────────────────────────────────────┘
///            ↓
/// ┌─ 第 3 层（日志脱敏）─────────────────────────┐
/// │  坐标 → 格网ID（GpsFuzzer.gridId）            │
/// │  昵称 → sha256 截断 8 位                      │
/// │  无 user_id 明文                              │
/// └─────────────────────────────────────────────┘
class AnonymousId {
  AnonymousId._();

  /// 固定盐值（生产环境应从服务端安全下发）
  static const String _salt = 'gobuzz_anon_2026_v1';

  /// 从 device_token 生成匿名 user_id（服务端同步使用相同算法）
  static String userIdFromToken(String deviceToken) {
    final bytes = utf8.encode('$deviceToken$_salt');
    final digest = sha256.convert(bytes);
    return digest.toString(); // 64位 hex
  }

  /// 昵称脱敏：sha256 截断前 8 位（仅用于日志）
  static String sanitizeNickname(String nickname) {
    final bytes = utf8.encode('$nickname$_salt');
    final digest = sha256.convert(bytes);
    return 'anon_${digest.toString().substring(0, 8)}';
  }

  /// 生成新的 device_token（16 位随机 hex）
  static String generateDeviceToken() {
    final rand = Random.secure();
    return List.generate(16, (_) => rand.nextInt(16).toRadixString(16)).join();
  }

  /// 构建日志安全数据：
  /// - 坐标替换为格网 ID
  /// - 昵称替换为脱敏 hash
  /// - 移除所有直接身份信息
  static Map<String, dynamic> sanitizeLogData(Map<String, dynamic> data) {
    final safe = <String, dynamic>{};
    for (final entry in data.entries) {
      final key = entry.key;
      final value = entry.value;
      if (key == 'lat' || key == 'lng' || key == 'latitude' || key == 'longitude') {
        // 跳过，坐标不在日志中记录（或用 GpsFuzzer.gridId 替代）
        continue;
      }
      if (key == 'nickname' && value is String) {
        safe[key] = sanitizeNickname(value);
      } else if (key == 'user_id' || key == 'userId' || key == 'authorId' || key == 'device_token') {
        safe[key] = sanitizeNickname(value.toString());
      } else if (key == 'grid_id') {
        safe[key] = value; // grid_id 本身已是脱敏结果，保留
      } else {
        safe[key] = value;
      }
    }
    return safe;
  }
}

/// 匿名 userId Provider：从 deviceToken 派生出服务端通信用的匿名 id
final anonymousUserIdProvider = Provider<String>((ref) {
  // deviceTokenProvider 已在 repositories.dart 中定义
  // 这里直接引用同一逻辑
  final prefs = ref.watch(sharedPrefsProvider);
  const key = 'ai_avatar_device_token';
  var token = prefs.getString(key);
  if (token == null || token.isEmpty) {
    final rand = Random();
    token = List.generate(16, (_) => rand.nextInt(16).toRadixString(16)).join();
    prefs.setString(key, token);
  }
  return AnonymousId.userIdFromToken(token);
});
