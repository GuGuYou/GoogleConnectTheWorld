enum MessageType { text, image, system }

/// 聊天消息模型
class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId; // 'me' 表示当前用户
  final MessageType type;
  final String content; // 文本内容，或图片 data URI / URL
  final DateTime time;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.type,
    required this.content,
    required this.time,
  });

  bool get isMe => senderId == 'me';
}

/// 会话模型（会话列表用）
class Conversation {
  final String id;
  final String peerId;
  final String lastMessage;
  final DateTime lastTime;
  final int unread;

  const Conversation({
    required this.id,
    required this.peerId,
    required this.lastMessage,
    required this.lastTime,
    this.unread = 0,
  });
}
