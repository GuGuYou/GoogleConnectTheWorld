import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'iso_transform.dart';
import 'scene_models.dart';

// ---------------------------------------------------------------------------
// 场景 Tick 时钟
// ---------------------------------------------------------------------------

/// 60fps 游戏循环 tick counter
final sceneTickProvider = StateProvider<int>((ref) => 0);

// ---------------------------------------------------------------------------
// 场景世界状态
// ---------------------------------------------------------------------------

/// 场景世界的完整状态（角色、房间、交互）
class HiveSceneState {
  final List<SceneActor> actors;
  final List<SceneRoom> rooms;
  final String? selectedActorId;  // 当前选择的角色（查看信息）
  final String? enteredRoomId;    // 当前进入的房间（用于动画切换）

  const HiveSceneState({
    required this.actors,
    required this.rooms,
    this.selectedActorId,
    this.enteredRoomId,
  });

  HiveSceneState copyWith({
    List<SceneActor>? actors,
    List<SceneRoom>? rooms,
    String? selectedActorId,
    String? enteredRoomId,
    bool clearSelected = false,
    bool clearEntered = false,
  }) {
    return HiveSceneState(
      actors: actors ?? this.actors,
      rooms: rooms ?? this.rooms,
      selectedActorId: clearSelected ? null : (selectedActorId ?? this.selectedActorId),
      enteredRoomId: clearEntered ? null : (enteredRoomId ?? this.enteredRoomId),
    );
  }
}

/// 场景世界 Provider（Notifier 模式）
class HiveSceneNotifier extends StateNotifier<HiveSceneState> {
  final Random _rng;

  HiveSceneNotifier()
      : _rng = Random(42),
        super(HiveSceneState(actors: [], rooms: []));

  /// 初始化场景（被页面调用一次）
  void initScene() {
    final centers = HiveRoomLayout.roomCenters;
    final doors = HiveRoomLayout.roomDoorPositions();
    final rooms = SceneRoom.defaultRooms(centers, doors);
    final npcRoute = HiveRoomLayout.npcRingPath();

    // 创建"我"
    final me = SceneActor.me(name: '我', avatarSeed: DateTime.now().millisecond);

    // 创建 NPC（4-8 个）
    final npcCount = 6;
    final rng = _rng;
    final npcs = List.generate(npcCount, (i) {
      final startIdx = rng.nextInt(npcRoute.length);
      return SceneActor.npc(
        id: 'npc_$i',
        name: _npcNames[i % _npcNames.length],
        seed: 100 + i * 13,
        pos: npcRoute[startIdx],
        route: npcRoute,
      )..npcRouteIndex = startIdx;
    });

    state = HiveSceneState(
      actors: [me, ...npcs],
      rooms: rooms,
    );
  }

  /// 游戏循环 tick（每帧调用）
  void tick(double dt) {
    final newActors = state.actors.map((a) => _tickActor(a, dt)).toList();

    // NPC 自主行为
    for (int i = 0; i < newActors.length; i++) {
      if (!newActors[i].isMe) {
        newActors[i] = _npcTick(newActors[i], dt);
      }
    }

    state = state.copyWith(actors: newActors);
  }

  // ---- 玩家相关操作 ----

  /// 玩家点击目标点 → 开始移动
  void walkTo(Offset worldTarget) {
    final me = state.actors.firstWhere((a) => a.isMe);
    final path = TilePathfinder.findPath(me.worldPos, worldTarget);
    if (path.isEmpty) return;

    final updated = SceneActor(
      id: me.id,
      name: me.name,
      avatarSeed: me.avatarSeed,
      worldPos: me.worldPos,
      isMe: true,
      state: ActorState.walking,
      glowColor: me.glowColor,
    )..path = path;

    final newActors = state.actors.map((a) => a.isMe ? updated : a).toList();
    state = state.copyWith(actors: newActors);
  }

  /// 玩家走路动画帧
  void _walkTick(SceneActor me, double dt) {
    if (me.path == null || me.pathIndex >= me.path!.length) {
      return;
    }

    final target = me.path![me.pathIndex];
    final dx = target.dx - me.worldPos.dx;
    final dy = target.dy - me.worldPos.dy;
    final dist = sqrt(dx * dx + dy * dy);

    if (dist < 0.05) {
      me.pathIndex++;
      if (me.pathIndex >= me.path!.length) {
        me.state = ActorState.idle;
        me.path = null;
        me.pathIndex = 0;
      }
      return;
    }

    const speed = 3.0; // 世界坐标单位/秒
    final step = speed * dt;
    if (step >= dist) {
      me.worldPos = target;
    } else {
      me.worldPos = Offset(
        me.worldPos.dx + (dx / dist) * step,
        me.worldPos.dy + (dy / dist) * step,
      );
    }
  }

  /// 选中/取消选中角色
  void selectActor(String? id) {
    state = state.copyWith(selectedActorId: id, clearSelected: id == null);
  }

  /// 长按角色 → 显示挥手气泡
  void waveAt(String actorId) {
    final newActors = state.actors.map((a) {
      if (a.id == actorId) {
        a.showWaveBubble = true;
      }
      return a;
    }).toList();
    state = state.copyWith(actors: newActors);

    // 2秒后自动消失
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        final cleared = state.actors.map((a) {
          if (a.id == actorId) a.showWaveBubble = false;
          return a;
        }).toList();
        state = state.copyWith(actors: cleared);
      }
    });
  }

  /// 进入房间
  void enterRoom(int roomIndex) {
    state = state.copyWith(enteredRoomId: 'room_$roomIndex');
  }

  /// 退出房间
  void exitRoom() {
    state = state.copyWith(clearEntered: true);
  }

  // ---- 内部 tick ----

  SceneActor _tickActor(SceneActor a, double dt) {
    if (a.isMe && a.state == ActorState.walking) {
      _walkTick(a, dt);
    }
    return a;
  }

  SceneActor _npcTick(SceneActor npc, double dt) {
    if (npc.npcRoute == null || npc.npcRoute!.isEmpty) return npc;

    // 等待
    if (npc.npcIsWaiting) {
      npc.npcWaitTimer -= dt;
      if (npc.npcWaitTimer <= 0) {
        npc.npcIsWaiting = false;
        npc.npcRouteIndex = (npc.npcRouteIndex + 1) % npc.npcRoute!.length;
      }
      return npc;
    }

    // 移动到下一路径点
    final target = npc.npcRoute![npc.npcRouteIndex % npc.npcRoute!.length];
    final dx = target.dx - npc.worldPos.dx;
    final dy = target.dy - npc.worldPos.dy;
    final dist = sqrt(dx * dx + dy * dy);

    if (dist < 0.1) {
      npc.npcIsWaiting = true;
      npc.npcWaitTimer = 1.0 + _rng.nextDouble() * 3.0; // 等待 1-4 秒
      npc.worldPos = target;
    } else {
      final step = npc.npcSpeed * (0.8 + _rng.nextDouble() * 0.4);
      npc.worldPos = Offset(
        npc.worldPos.dx + (dx / dist) * step * 10 * dt,
        npc.worldPos.dy + (dy / dist) * step * 10 * dt,
      );
    }
    return npc;
  }
}

final hiveSceneProvider =
    StateNotifierProvider<HiveSceneNotifier, HiveSceneState>((ref) {
  final notifier = HiveSceneNotifier();
  notifier.initScene();
  return notifier;
});

// ---------------------------------------------------------------------------
// 常量
// ---------------------------------------------------------------------------

const _npcNames = [
  '小明', '小红', '阿强', '小美', '大壮', '丽丽',
  '老王', '小李', '花花', '阿杰', '小芳', '大刘',
];
