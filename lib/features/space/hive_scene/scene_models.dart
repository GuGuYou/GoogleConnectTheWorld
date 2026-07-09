import 'dart:math';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// 场景角色（玩家 / NPC）
// ---------------------------------------------------------------------------

/// 角色在场景中的状态
enum ActorState { idle, walking, waving }

/// 场景中的一个角色（玩家或NPC）
class SceneActor {
  final String id;
  final String name;
  final int avatarSeed;
  final bool isMe;
  final Color glowColor; // 我的金环 / 其他人的银环

  // 世界坐标位置
  Offset worldPos;

  // 移动相关
  ActorState state;
  List<Offset>? path;    // 移动路径
  int pathIndex;         // 当前路径点索引
  double moveProgress;   // 当前段进度 0..1

  // NPC 专用
  List<Offset>? npcRoute;   // NPC 环形路线
  int npcRouteIndex;
  double npcSpeed;
  double npcWaitTimer;
  bool npcIsWaiting;

  // 交互
  bool showWaveBubble;
  String? roomType; // 如果角色在房间门口，这里是房间类型

  SceneActor({
    required this.id,
    required this.name,
    required this.avatarSeed,
    required this.worldPos,
    this.isMe = false,
    this.state = ActorState.idle,
    this.glowColor = const Color(0x80B0BEC5), // 默认银灰
    this.npcRoute,
    this.npcRouteIndex = 0,
    this.npcSpeed = 0.02,
    this.npcWaitTimer = 0,
    this.npcIsWaiting = false,
    this.showWaveBubble = false,
    this.roomType,
  })  : path = null,
        pathIndex = 0,
        moveProgress = 0;

  /// 工厂：创建"我"
  factory SceneActor.me({required String name, required int avatarSeed}) {
    return SceneActor(
      id: 'me',
      name: name,
      avatarSeed: avatarSeed,
      worldPos: Offset.zero,
      isMe: true,
      glowColor: const Color(0xCCFFD84A), // 金色
    );
  }

  /// 工厂：创建 NPC
  factory SceneActor.npc({
    required String id,
    required String name,
    required int seed,
    required Offset pos,
    required List<Offset> route,
  }) {
    return SceneActor(
      id: id,
      name: name,
      avatarSeed: seed,
      worldPos: pos,
      npcRoute: route,
      npcRouteIndex: 0,
    );
  }
}

// ---------------------------------------------------------------------------
// 房间数据
// ---------------------------------------------------------------------------

/// 蜂巢房间类型
enum RoomType { game, cinema, drawGuess, music }

extension RoomTypeExt on RoomType {
  String get label {
    switch (this) {
      case RoomType.game:     return '🎮 网吧/游戏房';
      case RoomType.cinema:   return '🎬 电影院';
      case RoomType.drawGuess: return '🎨 你画我猜';
      case RoomType.music:    return '🎵 音乐吧';
    }
  }

  IconData get icon {
    switch (this) {
      case RoomType.game:     return Icons.sports_esports;
      case RoomType.cinema:   return Icons.movie;
      case RoomType.drawGuess: return Icons.draw;
      case RoomType.music:    return Icons.music_note;
    }
  }

  Color get accentColor {
    switch (this) {
      case RoomType.game:     return const Color(0xFF6366F1);
      case RoomType.cinema:   return const Color(0xFFF43F5E);
      case RoomType.drawGuess: return const Color(0xFF10B981);
      case RoomType.music:    return const Color(0xFFF59E0B);
    }
  }
}

/// 地图上的一个房间
class SceneRoom {
  final int index;
  final RoomType type;
  final Offset worldPos;       // 房间中心
  final Offset doorPos;        // 入口位置
  final String label;
  final Color color;
  int onlineCount;

  SceneRoom({
    required this.index,
    required this.type,
    required this.worldPos,
    required this.doorPos,
    required this.label,
    required this.color,
    this.onlineCount = 0,
  });

  /// 6 个预设房间
  static List<SceneRoom> defaultRooms(
    List<Offset> centers,
    List<Offset> doors,
  ) {
    const types = [
      RoomType.game,
      RoomType.cinema,
      RoomType.drawGuess,
      RoomType.music,
      RoomType.game,
      RoomType.cinema,
    ];
    final colors = [
      const Color(0xFF6366F1),
      const Color(0xFFF43F5E),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFF8B5CF6),
      const Color(0xFF06B6D4),
    ];
    return List.generate(6, (i) => SceneRoom(
      index: i,
      type: types[i],
      worldPos: centers[i],
      doorPos: doors[i],
      label: types[i].label,
      color: colors[i],
      onlineCount: Random(i * 7).nextInt(12) + 1,
    ));
  }
}

// ---------------------------------------------------------------------------
// 房间内部数据
// ---------------------------------------------------------------------------

/// 游戏房内的游戏工位
class GameStation {
  final int id;
  bool occupied;
  String? occupantName;
  int? occupantSeed;

  GameStation({required this.id, this.occupied = false, this.occupantName, this.occupantSeed});
}

/// 电影院内的座位
class CinemaSeat {
  final int row;
  final int col;
  bool occupied;
  String? occupantName;
  int? occupantSeed;

  CinemaSeat({required this.row, required this.col, this.occupied = false, this.occupantName, this.occupantSeed});
}

/// 音乐吧内的曲目
class MusicTrack {
  final String title;
  final String artist;
  final String addedBy;
  final int likes;

  const MusicTrack({
    required this.title,
    required this.artist,
    required this.addedBy,
    this.likes = 0,
  });
}
