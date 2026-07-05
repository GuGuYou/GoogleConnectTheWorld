/// AI 虚拟头像生成后端的接口配置。
///
/// - Web / 桌面 / iOS 模拟器调试：http://127.0.0.1:8000
/// - Android 模拟器调试：electron 网络桥接用 http://10.0.2.2:8000（模拟器访问电脑本机的固定别名）
/// - 真机调试：改成你电脑的局域网 IP，如 http://192.168.1.10:8000
/// - 正式上线：改成你的服务器域名，如 https://api.yourdomain.com
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = 'http://127.0.0.1:8000';

  static String get generateAvatarUrl => '$baseUrl/api/generate-avatar';
}
