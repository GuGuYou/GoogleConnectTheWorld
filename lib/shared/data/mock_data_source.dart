import 'dart:math';

import 'package:flutter/material.dart';

import '../models/activity.dart';
import '../models/feed_post.dart';
import '../models/ip_tag.dart';
import '../models/message.dart';
import '../models/user.dart';
import '../models/virtual_avatar.dart';
import '../models/whisper.dart';

/// 全局 Mock 数据源（单例）。所有页面数据均来源于此。
/// 切换真实后端时只需替换为 RemoteDataSource，业务层零改动。
class MockDataSource {
  MockDataSource._() {
    _generate();
  }
  static final MockDataSource instance = MockDataSource._();

  // 中心点：深圳南山区
  static const double centerLat = 22.5429;
  static const double centerLng = 113.9414;

  final _rnd = Random(20260627); // 固定种子，演示数据稳定

  // ---- 标签库 ----
  late final List<IpTag> tags;

  // ---- 当前用户 ----
  late UserProfile me;

  // ---- 数据集合 ----
  final List<UserProfile> users = [];
  final List<FeedPost> feeds = [];
  final List<ActivityItem> activities = [];
  final List<Conversation> conversations = [];
  final Map<String, List<ChatMessage>> messages = {};
  final List<Whisper> whispers = [];

  void _generate() {
    tags = const [
      // 游戏
      IpTag(id: 'g1', nameZh: '原神', nameEn: 'Genshin', category: 'game', icon: Icons.videogame_asset),
      IpTag(id: 'g2', nameZh: '英雄联盟', nameEn: 'LoL', category: 'game', icon: Icons.sports_esports),
      IpTag(id: 'g3', nameZh: '塞尔达', nameEn: 'Zelda', category: 'game', icon: Icons.castle),
      IpTag(id: 'g4', nameZh: '艾尔登法环', nameEn: 'Elden Ring', category: 'game', icon: Icons.shield),
      IpTag(id: 'g5', nameZh: '动物森友会', nameEn: 'Animal Crossing', category: 'game', icon: Icons.park),
      // 动漫
      IpTag(id: 'a1', nameZh: '咒术回战', nameEn: 'Jujutsu Kaisen', category: 'anime', icon: Icons.auto_awesome),
      IpTag(id: 'a2', nameZh: '海贼王', nameEn: 'One Piece', category: 'anime', icon: Icons.sailing),
      IpTag(id: 'a3', nameZh: '鬼灭之刃', nameEn: 'Demon Slayer', category: 'anime', icon: Icons.whatshot),
      IpTag(id: 'a4', nameZh: '间谍过家家', nameEn: 'Spy Family', category: 'anime', icon: Icons.family_restroom),
      // 剧集
      IpTag(id: 'd1', nameZh: '怪奇物语', nameEn: 'Stranger Things', category: 'drama', icon: Icons.tv),
      IpTag(id: 'd2', nameZh: '权力的游戏', nameEn: 'GoT', category: 'drama', icon: Icons.castle_outlined),
      IpTag(id: 'd3', nameZh: '最后生还者', nameEn: 'The Last of Us', category: 'drama', icon: Icons.coronavirus),
      // 漫画
      IpTag(id: 'c1', nameZh: '蝙蝠侠', nameEn: 'Batman', category: 'comic', icon: Icons.nightlight),
      IpTag(id: 'c2', nameZh: '蜘蛛侠', nameEn: 'Spider-Man', category: 'comic', icon: Icons.bug_report),
      // 音乐
      IpTag(id: 'm1', nameZh: '电子音乐', nameEn: 'EDM', category: 'music', icon: Icons.music_note),
      IpTag(id: 'm2', nameZh: '说唱', nameEn: 'Hip-Hop', category: 'music', icon: Icons.mic),
    ];

    // 当前用户
    me = UserProfile(
      id: 'me',
      nickname: 'NeonDrifter',
      avatarSeed: 'me_seed_42',
      virtualAvatar: VirtualAvatar.seeded('me_seed_42'),
      bio: '夜猫子 / 主机党 / 二次元浓度过高，找搭子开黑看番！',
      tags: [tags[0], tags[3], tags[5], tags[9]],
      lat: centerLat,
      lng: centerLng,
      city: '深圳',
      online: true,
      age: 23,
      gender: 'f',
    );

    _genUsers();
    _genFeeds();
    _genActivities();
    _genConversations();
    _genWhispers();
  }

  static const _names = [
    'AuroraByte', 'PixelFox', 'NovaRin', 'GlitchKoi', 'EchoMira',
    'ZephyrAce', 'LunaVolt', 'CipherJin', 'NeonOtaku', 'VividHana',
    'SaberLily', 'ByteMochi', 'RaiDenki', 'MistyQu', 'KuroNeko',
    'SoraWave', 'HikariX', 'ChronoMei', 'IrisGlow', 'TankaShu',
    'VelvetRei', 'OrbitYuki', 'CrimsonAo', 'PrismKai', 'SilkMomo',
    'DriftKaze', 'EmberSayu', 'JadeRyu', 'PolarToki', 'FuzzyMint',
  ];

  static const _bios = [
    '周末就想找人一起开黑，王者/原神都行',
    '资深番剧党，追新番从不掉队',
    '主机收藏家，欢迎来我家联机塞尔达',
    '漫展常客，cos 同好优先',
    '只想安安静静找个搭子看演唱会',
    '社恐但热情，线上能聊三天三夜',
    '电竞退役选手，带你上分',
    '影视区 up，最近在补美剧',
    '动森岛主，求互访串门',
    '说唱爱好者，周末有局喊我',
  ];

  void _genUsers() {
    for (var i = 0; i < 50; i++) {
      final tagCount = 2 + _rnd.nextInt(4);
      final shuffled = [...tags]..shuffle(_rnd);
      final userTags = shuffled.take(tagCount).toList();
      // 坐标围绕中心点 ±0.05° 抖动
      final lat = centerLat + (_rnd.nextDouble() - 0.5) * 0.1;
      final lng = centerLng + (_rnd.nextDouble() - 0.5) * 0.1;
      users.add(
        UserProfile(
          id: 'u$i',
          nickname: _names[i % _names.length] + (i >= _names.length ? '${i ~/ _names.length}' : ''),
          avatarSeed: 'seed_$i',
          // 视觉风格已统一为"光遇"式可爱治愈风，Mock 用户不再随机分配 pixel 风格。
          virtualAvatar: VirtualAvatar.seeded('seed_$i'),
          bio: _bios[i % _bios.length],
          tags: userTags,
          lat: lat,
          lng: lng,
          online: _rnd.nextBool(),
          age: 18 + _rnd.nextInt(12),
          gender: _rnd.nextBool() ? 'f' : 'm',
        ),
      );
    }
  }

  void _genFeeds() {
    const zh = [
      '有没有南山附近的原神搭子？周末想一起刷深渊～',
      '今晚有人一起看咒术回战剧场版吗？求伴！',
      '入手了塞尔达王国之泪，欢迎来我家联机！',
      '漫展门票多了一张，有没有同好一起去？',
      '周五夜场电子音乐，组队蹦迪走起！',
      '最近在补怪奇物语，想找人一起讨论剧情',
      '蜘蛛侠新作太燃了，有没有漫画同好聊聊',
      '想组个长期开黑的小队，英雄联盟峡谷见',
    ];
    const en = [
      'Any Genshin players near Nanshan? Let\'s clear Abyss this weekend!',
      'Anyone watching the Jujutsu Kaisen movie tonight? Need a buddy!',
      'Got Zelda TotK, come play co-op at my place!',
      'Extra con ticket here, any fans wanna go together?',
      'Friday night EDM, let\'s form a dance squad!',
      'Binging Stranger Things lately, looking for someone to discuss plot',
      'New Spider-Man is fire, any comic fans wanna chat?',
      'Building a long-term LoL squad, see you on the Rift',
    ];
    for (var i = 0; i < 24; i++) {
      final author = users[_rnd.nextInt(users.length)];
      feeds.add(
        FeedPost(
          id: 'f$i',
          authorId: author.id,
          contentZh: zh[i % zh.length],
          contentEn: en[i % en.length],
          tag: author.tags.first,
          likes: 5 + _rnd.nextInt(320),
          comments: _rnd.nextInt(48),
          distanceKm: 0.3 + _rnd.nextDouble() * 9,
          imageCount: 1 + _rnd.nextInt(3),
          coverSeed: 'feed_$i',
        ),
      );
    }
  }

  void _genActivities() {
    const titleZh = [
      '原神玩家线下联机日', '咒术回战观影团', '塞尔达通关分享会', '漫展拼团同行',
      '周五电音蹦迪局', '怪奇物语剧迷茶话会', '英雄联盟五黑训练赛', '海贼王主题桌游夜',
      '动物森友会串门日', '说唱 Cypher 开放麦', '蜘蛛侠观影 + 漫画交流', '鬼灭之刃 cos 拍摄',
      '塞尔达手办交换会', '电竞酒馆开黑夜', '二次元歌会 KTV', '美剧马拉松通宵场',
      '间谍过家家观影', '游戏原声音乐会', '漫画工作坊', '复古游戏机体验展',
    ];
    const titleEn = [
      'Genshin Co-op Meetup', 'Jujutsu Kaisen Movie Night', 'Zelda Clear Sharing', 'Comic Con Group Trip',
      'Friday EDM Party', 'Stranger Things Fan Tea', 'LoL 5v5 Scrim', 'One Piece Board Game Night',
      'Animal Crossing Visit Day', 'Rap Cypher Open Mic', 'Spider-Man Movie + Comics', 'Demon Slayer Cosplay Shoot',
      'Zelda Figure Swap', 'Esports Bar Night', 'Anime Song KTV', 'TV Series Marathon',
      'Spy x Family Screening', 'Game OST Concert', 'Comic Workshop', 'Retro Console Expo',
    ];
    const locZh = ['南山科技园', '深圳湾万象城', '海岸城', '欢乐海岸', '后海地铁站', '世界之窗', '蛇口网谷'];
    const locEn = ['Nanshan Tech Park', 'MixC Bay', 'Coastal City', 'OCT Harbour', 'Houhai Station', 'Window of the World', 'Shekou Net Valley'];
    for (var i = 0; i < 20; i++) {
      final tag = tags[_rnd.nextInt(tags.length)];
      final lat = centerLat + (_rnd.nextDouble() - 0.5) * 0.08;
      final lng = centerLng + (_rnd.nextDouble() - 0.5) * 0.08;
      final p = 3 + _rnd.nextInt(16);
      activities.add(
        ActivityItem(
          id: 'act$i',
          titleZh: titleZh[i % titleZh.length],
          titleEn: titleEn[i % titleEn.length],
          category: tag.category,
          tag: tag,
          time: DateTime.now().add(Duration(days: 1 + _rnd.nextInt(20), hours: _rnd.nextInt(12))),
          locationZh: '深圳·${locZh[i % locZh.length]}',
          locationEn: 'Shenzhen · ${locEn[i % locEn.length]}',
          lat: lat,
          lng: lng,
          hostId: users[_rnd.nextInt(users.length)].id,
          descZh: '欢迎同好报名！我们将一起度过一段有趣的线下时光，名额有限，先到先得。现场提供饮品与小食。',
          descEn: 'Fans welcome! Let\'s enjoy a fun offline time together. Limited spots, first come first served. Drinks and snacks provided.',
          participants: p,
          maxParticipants: p + 2 + _rnd.nextInt(20),
          participantAvatarSeeds: List.generate(p.clamp(0, 6), (k) => 'p_${i}_$k'),
        ),
      );
    }
  }

  void _genWhispers() {
    const zh = [
      '第一次一个人坐在这里看日落，原来一个人也可以很自在。',
      '如果你也喜欢原神，此刻正好路过这里，祝你今天抽卡欧气满满。',
      '深夜写完代码下楼透气，发现这附近意外地安静，留个痕迹给同样emo的你。',
      '刚打完一场很爽的排位，分享一下这份快乐给路过的召唤师。',
      '一个人来的漫展，但一点都不孤单，因为知道总有同好会经过这里。',
      '今天心情不太好，但走到这儿突然觉得没那么糟了，希望你也是。',
      '如果有人也在补这季的新番，我们大概曾在同一时间擦肩而过。',
      '刚搬来这个城市，谁都不认识，留句话当作我在这里存在过的证据。',
      '深夜emo发作，写下这句话希望能被某个失眠的同类看到。',
      '路过的你，今天辛苦了，随便找个地方坐会儿吧。',
    ];
    const en = [
      'First time sitting here alone watching the sunset — turns out being alone can feel fine.',
      'If you also play Genshin and happen to pass by, wishing you great luck on your next pull.',
      'Stepped out for air after coding all night, this corner is oddly peaceful. Leaving a trace for fellow night owls.',
      'Just had an amazing ranked match, sharing the joy with whoever passes by.',
      'Came to the con alone but never felt lonely, knowing someone like-minded will pass through here.',
      'Wasn\'t feeling great today, but this spot made it a little better. Hope it does for you too.',
      'If you\'re also catching up on this season\'s anime, we might have crossed paths in time.',
      'Just moved to this city, don\'t know anyone yet. Leaving this as proof I existed here.',
      'Late night overthinking again, hoping some fellow insomniac finds this.',
      'Hey stranger passing by, you did well today. Sit here for a bit if you want.',
    ];
    for (var i = 0; i < 16; i++) {
      final author = users[_rnd.nextInt(users.length)];
      final lat = centerLat + (_rnd.nextDouble() - 0.5) * 0.06;
      final lng = centerLng + (_rnd.nextDouble() - 0.5) * 0.06;
      whispers.add(
        Whisper(
          id: 'wh$i',
          authorId: author.id,
          authorNickname: author.nickname,
          authorAvatarSeed: author.avatarSeed,
          contentZh: zh[i % zh.length],
          contentEn: en[i % en.length],
          lat: lat,
          lng: lng,
          createdAt: DateTime.now().subtract(Duration(hours: 1 + _rnd.nextInt(240))),
          resonanceCount: _rnd.nextInt(60),
        ),
      );
    }
  }

  void _genConversations() {
    final peers = users.take(6).toList();
    const lastZh = [
      '哈喽！看你也喜欢原神，周末一起刷本？',
      '好呀好呀，我也在补这部番！',
      '[图片]',
      '那约个时间线下面基吧～',
      '收到，到时候喊我！',
      '在吗？看你报名了那个活动',
    ];
    for (var i = 0; i < peers.length; i++) {
      final peer = peers[i];
      final convId = 'conv_${peer.id}';
      conversations.add(
        Conversation(
          id: convId,
          peerId: peer.id,
          lastMessage: lastZh[i % lastZh.length],
          lastTime: DateTime.now().subtract(Duration(minutes: 3 + i * 27)),
          unread: i < 2 ? (1 + i) : 0,
        ),
      );
      messages[convId] = _seedMessages(convId, i);
    }
  }

  List<ChatMessage> _seedMessages(String convId, int idx) {
    final now = DateTime.now();
    return [
      ChatMessage(id: '${convId}_0', conversationId: convId, senderId: 'system', type: MessageType.system, content: 'matched', time: now.subtract(const Duration(hours: 2))),
      ChatMessage(id: '${convId}_1', conversationId: convId, senderId: convId, type: MessageType.text, content: '哈喽！看你头像也是原神玩家呀～', time: now.subtract(const Duration(minutes: 58))),
      ChatMessage(id: '${convId}_2', conversationId: convId, senderId: 'me', type: MessageType.text, content: '对呀！主修雷神，最近在抓深渊满星', time: now.subtract(const Duration(minutes: 55))),
      ChatMessage(id: '${convId}_3', conversationId: convId, senderId: convId, type: MessageType.image, content: 'chat_img_1', time: now.subtract(const Duration(minutes: 50))),
      ChatMessage(id: '${convId}_4', conversationId: convId, senderId: convId, type: MessageType.text, content: '这是我的角色配队，周末一起刷？', time: now.subtract(const Duration(minutes: 49))),
      ChatMessage(id: '${convId}_5', conversationId: convId, senderId: 'me', type: MessageType.text, content: '可以啊！那约周六下午～', time: now.subtract(const Duration(minutes: 30))),
    ];
  }

  // ---- 查询方法 ----
  UserProfile userById(String id) {
    if (id == 'me') return me;
    return users.firstWhere((u) => u.id == id, orElse: () => me);
  }

  /// 自动回复一条消息（IM mock）
  ChatMessage autoReply(String convId) {
    const replies = ['哈哈哈确实！', '那必须的～', '好呀，等你！', '我也这么觉得 [图片]', '冲冲冲！'];
    final r = replies[Random().nextInt(replies.length)];
    return ChatMessage(
      id: '${convId}_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: convId,
      senderId: convId,
      type: r.contains('[图片]') ? MessageType.image : MessageType.text,
      content: r.contains('[图片]') ? 'chat_img_reply' : r,
      time: DateTime.now(),
    );
  }
}
