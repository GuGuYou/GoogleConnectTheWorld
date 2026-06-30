import 'dart:math';

import 'package:flutter/material.dart';

import '../models/activity.dart';
import '../models/feed_post.dart';
import '../models/gamification.dart';
import '../models/group.dart';
import '../models/ip_tag.dart';
import '../models/landmark.dart';
import '../models/message.dart';
import '../models/user.dart';

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
  final List<IpGroup> groups = [];
  final List<Landmark> landmarks = [];

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
      avatarSeed: 'assets/avatars/avatar_10.png',
      bio: '夜猫子 / 主机党 / 二次元浓度过高，找搭子开黑看番！',
      tags: [tags[0], tags[3], tags[5], tags[9]],
      lat: centerLat,
      lng: centerLng,
      city: '深圳',
      online: true,
      age: 23,
      gender: 'f',
      status: UserStatus.online,
      verified: true,
      level: 2,
      personality: '',
    );

    _genUsers();
    _genFeeds();
    _genActivities();
    _genConversations();
    _genGroups();
    _genLandmarks();
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
    const statuses = [
      UserStatus.online,
      UserStatus.idle,
      UserStatus.dnd,
      UserStatus.inEvent,
      UserStatus.offline,
    ];
    const personalityKeys = ['hardcore', 'vibe', 'social', 'creator'];
    for (var i = 0; i < 50; i++) {
      final tagCount = 2 + _rnd.nextInt(4);
      final shuffled = [...tags]..shuffle(_rnd);
      final userTags = shuffled.take(tagCount).toList();
      // 坐标围绕中心点 ±0.05° 抖动
      final lat = centerLat + (_rnd.nextDouble() - 0.5) * 0.1;
      final lng = centerLng + (_rnd.nextDouble() - 0.5) * 0.1;
      final online = _rnd.nextBool();
      users.add(
        UserProfile(
          id: 'u$i',
          nickname: _names[i % _names.length] + (i >= _names.length ? '${i ~/ _names.length}' : ''),
          avatarSeed: 'seed_$i',
          bio: _bios[i % _bios.length],
          tags: userTags,
          lat: lat,
          lng: lng,
          online: online,
          age: 18 + _rnd.nextInt(12),
          gender: _rnd.nextBool() ? 'f' : 'm',
          status: online ? statuses[_rnd.nextInt(4)] : UserStatus.offline,
          verified: _rnd.nextInt(4) == 0, // 约 1/4 资深认证
          level: 1 + _rnd.nextInt(4),
          personality: personalityKeys[_rnd.nextInt(personalityKeys.length)],
        ),
      );
    }
  }

  void _genFeeds() {
    for (var i = 0; i < 24; i++) {
      final author = users[_rnd.nextInt(users.length)];
      final type = FeedType.values[i % FeedType.values.length];
      String? placeZh;
      String? placeEn;
      if (type == FeedType.checkin) {
        const pZh = ['南山漫展现场', '海岸城谷子店', 'COCO PARK 桌游吧', '后海二次元咖啡'];
        const pEn = ['Nanshan Comic Con', 'Coastal City Goods', 'COCO PARK Boardgame', 'Houhai Anime Cafe'];
        placeZh = pZh[i % pZh.length];
        placeEn = pEn[i % pEn.length];
      } else if (type == FeedType.haul) {
        placeZh = '今日战利品';
        placeEn = "Today's Haul";
      }
      feeds.add(
        FeedPost(
          id: 'f$i',
          authorId: author.id,
          contentZh: _feedContentZh(type, i),
          contentEn: _feedContentEn(type, i),
          tag: author.tags.first,
          likes: 5 + _rnd.nextInt(320),
          comments: _rnd.nextInt(48),
          distanceKm: 0.3 + _rnd.nextDouble() * 9,
          imageCount: type == FeedType.talk ? _rnd.nextInt(3) : 1 + _rnd.nextInt(3),
          coverSeed: 'feed_$i',
          type: type,
          placeZh: placeZh,
          placeEn: placeEn,
        ),
      );
    }
  }

  String _feedContentZh(FeedType type, int i) {
    switch (type) {
      case FeedType.checkin:
        return ['今天来漫展啦！现场氛围绝了，求同好一起逛～', '在谷子店蹲到心仪吧唧，开心！', '桌游吧开了一下午，太上头了'][i % 3];
      case FeedType.haul:
        return ['这次的谷子真的绝，晒一下我的战利品！', '入手了限定手办，钱包空了但心满了', '抽到了隐藏款，狂喜！'][i % 3];
      case FeedType.seeking:
        return ['周末想找人一起开黑，王者/原神都行～', '有没有南山附近的搭子周六一起看番？', '差一个人就能组桌游局，速来！'][i % 3];
      case FeedType.talk:
        return _feedTalkZh[i % _feedTalkZh.length];
    }
  }

  String _feedContentEn(FeedType type, int i) {
    switch (type) {
      case FeedType.checkin:
        return ['At the con today! Vibes are amazing, looking for buddies to roam~', 'Snagged my dream badge at the goods shop!', 'Spent the afternoon at the boardgame bar, so hooked'][i % 3];
      case FeedType.haul:
        return ['These goods are incredible, showing off my haul!', 'Got a limited figure, wallet empty but heart full', 'Pulled the secret edition, ecstatic!'][i % 3];
      case FeedType.seeking:
        return ['Looking for a squad this weekend, Honor/Genshin both fine~', 'Any buddies near Nanshan for anime on Saturday?', 'One more for a board game table, come quick!'][i % 3];
      case FeedType.talk:
        return _feedTalkEn[i % _feedTalkEn.length];
    }
  }

  static const _feedTalkZh = [
    '有没有南山附近的原神搭子？周末想一起刷深渊～',
    '今晚有人一起看咒术回战剧场版吗？求伴！',
    '入手了塞尔达王国之泪，欢迎来我家联机！',
    '最近在补怪奇物语，想找人一起讨论剧情',
    '蜘蛛侠新作太燃了，有没有漫画同好聊聊',
    '想组个长期开黑的小队，英雄联盟峡谷见',
  ];

  static const _feedTalkEn = [
    "Any Genshin players near Nanshan? Let's clear Abyss this weekend!",
    'Anyone watching the Jujutsu Kaisen movie tonight? Need a buddy!',
    'Got Zelda TotK, come play co-op at my place!',
    'Binging Stranger Things lately, looking for someone to discuss plot',
    'New Spider-Man is fire, any comic fans wanna chat?',
    'Building a long-term LoL squad, see you on the Rift',
  ];

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
          candidateSeeds: List.generate(3 + _rnd.nextInt(4), (k) => 'cand_${i}_$k'),
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

  // ---- 圈子（Discord 化）----
  void _genGroups() {
    const descZh = '聚集同好的官方圈子，分频道畅聊、组队、开语音房。';
    const descEn = 'Official tribe for fans — chat, squad up, and join voice rooms.';
    // 选取若干热门 IP 作为圈子
    final pick = [tags[0], tags[5], tags[1], tags[2], tags[9], tags[6]];
    for (var i = 0; i < pick.length; i++) {
      final t = pick[i];
      groups.add(
        IpGroup(
          id: 'grp_${t.id}',
          tag: t,
          nameZh: '${t.nameZh} 同好圈',
          nameEn: '${t.nameEn} Tribe',
          descZh: descZh,
          descEn: descEn,
          members: 1200 + _rnd.nextInt(48000),
          onlineNow: 30 + _rnd.nextInt(900),
          joined: i == 0,
          channels: const [
            GroupChannel(id: 'c_news', nameZh: '资讯', nameEn: 'news', activeCount: 12),
            GroupChannel(id: 'c_guide', nameZh: '攻略', nameEn: 'guides', activeCount: 34),
            GroupChannel(id: 'c_art', nameZh: '二创', nameEn: 'fan-art', activeCount: 56),
            GroupChannel(id: 'c_chat', nameZh: '闲聊', nameEn: 'chat', activeCount: 128),
            GroupChannel(id: 'c_meet', nameZh: '约玩', nameEn: 'meetup', activeCount: 9),
            GroupChannel(id: 'c_voice1', nameZh: '深夜电台', nameEn: 'Late Night Radio', type: ChannelType.voice, activeCount: 5),
            GroupChannel(id: 'c_voice2', nameZh: '剧情讨论房', nameEn: 'Lore Talk', type: ChannelType.voice, activeCount: 8),
          ],
          voiceRooms: [
            VoiceRoom(
              id: 'vr_${t.id}_1',
              titleZh: '深夜陪聊电台 🎧',
              titleEn: 'Late Night Chill Radio 🎧',
              hostId: users[_rnd.nextInt(users.length)].id,
              speakerSeeds: List.generate(4, (k) => 'vr_${i}_a_$k'),
              listeners: 12 + _rnd.nextInt(80),
            ),
            VoiceRoom(
              id: 'vr_${t.id}_2',
              titleZh: '联机开黑 找队友',
              titleEn: 'Co-op Squad Finder',
              hostId: users[_rnd.nextInt(users.length)].id,
              speakerSeeds: List.generate(3, (k) => 'vr_${i}_b_$k'),
              listeners: 5 + _rnd.nextInt(40),
            ),
          ],
        ),
      );
    }
  }

  // ---- 同好地标 ----
  void _genLandmarks() {
    const data = [
      ['CTF 漫展会场', 'CTF Comic Con', LandmarkType.con, true],
      ['南山谷子专门店', 'Nanshan Goods Store', LandmarkType.goods, false],
      ['次元站谷子店', 'Dimension Goods', LandmarkType.goods, false],
      ['骰子人桌游吧', 'Dice Board Game Bar', LandmarkType.boardgame, true],
      ['像素桌游空间', 'Pixel Board Space', LandmarkType.boardgame, false],
      ['星轨二次元咖啡', 'Orbit Anime Cafe', LandmarkType.cafe, true],
      ['女仆主题咖啡馆', 'Maid Theme Cafe', LandmarkType.cafe, false],
      ['漫迷主题书吧', 'Manga Book Bar', LandmarkType.cafe, false],
    ];
    for (var i = 0; i < data.length; i++) {
      final d = data[i];
      final lat = centerLat + (_rnd.nextDouble() - 0.5) * 0.06;
      final lng = centerLng + (_rnd.nextDouble() - 0.5) * 0.06;
      landmarks.add(
        Landmark(
          id: 'lm$i',
          nameZh: d[0] as String,
          nameEn: d[1] as String,
          type: d[2] as LandmarkType,
          lat: lat,
          lng: lng,
          distanceKm: haversineFromCenter(lat, lng),
          fansHere: 3 + _rnd.nextInt(60),
          hasEvent: d[3] as bool,
        ),
      );
    }
    landmarks.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
  }

  double haversineFromCenter(double lat, double lng) {
    final dLat = (lat - centerLat) * 111.0;
    final dLng = (lng - centerLng) * 95.0;
    return sqrt(dLat * dLat + dLng * dLng);
  }

  // ---- 破冰问题（参考 Soul 灵魂问题）----
  List<String> icebreakerFor(String lang, IpTag? tag) {
    final ipZh = tag?.nameZh ?? '这个 IP';
    final ipEn = tag?.nameEn ?? 'this IP';
    if (lang == 'en') {
      return [
        'What got you into $ipEn in the first place?',
        'Which moment of $ipEn hit you the hardest?',
        'If you could meet one character, who would it be?',
      ];
    }
    return [
      '你入坑 $ipZh 的原点是什么？',
      '$ipZh 里最戳你的是哪一段？',
      '如果能见一个角色，你最想见谁？',
    ];
  }

  // ---- 兴趣人格测试题 ----
  static const personalityQuestions = <PersonalityQuestion>[
    PersonalityQuestion(
      '入坑一部新作，你最先做的是？',
      'When you get into a new work, you first…',
      [
        MapEntry('hardcore', '翻遍设定集和时间线'),
        MapEntry('vibe', '单纯沉浸享受剧情'),
        MapEntry('social', '拉群找人一起讨论'),
        MapEntry('creator', '手痒想画点同人'),
      ],
      [
        MapEntry('hardcore', 'Dig through all the lore'),
        MapEntry('vibe', 'Just immerse and enjoy'),
        MapEntry('social', 'Find people to discuss'),
        MapEntry('creator', 'Start making fan works'),
      ],
    ),
    PersonalityQuestion(
      '线下活动里你通常是？',
      'At an offline event you usually…',
      [
        MapEntry('hardcore', '考据细节的百科君'),
        MapEntry('vibe', '安静感受氛围的人'),
        MapEntry('social', '气氛组核心 C 位'),
        MapEntry('creator', '忙着拍照 / cos 出片'),
      ],
      [
        MapEntry('hardcore', 'The walking encyclopedia'),
        MapEntry('vibe', 'Quietly soaking the vibe'),
        MapEntry('social', 'The life of the party'),
        MapEntry('creator', 'Busy shooting / cosplaying'),
      ],
    ),
    PersonalityQuestion(
      '最让你满足的瞬间是？',
      'The most satisfying moment is…',
      [
        MapEntry('hardcore', '发现一个隐藏彩蛋'),
        MapEntry('vibe', '被某个画面狠狠戳中'),
        MapEntry('social', '和搭子一起通关 / 应援'),
        MapEntry('creator', '作品被同好点赞'),
      ],
      [
        MapEntry('hardcore', 'Finding a hidden easter egg'),
        MapEntry('vibe', 'Being deeply moved by a scene'),
        MapEntry('social', 'Clearing / cheering with buddies'),
        MapEntry('creator', 'Your work getting loved'),
      ],
    ),
  ];

  // ---- 每日任务（参考 Duolingo）----
  List<DailyTask> buildDailyTasks() => [
        DailyTask(id: 't_match', titleZh: '匹配 1 位同好', titleEn: 'Match 1 fan', icon: Icons.favorite, xp: 10),
        DailyTask(id: 't_post', titleZh: '发布 1 条动态', titleEn: 'Post 1 moment', icon: Icons.edit, xp: 15),
        DailyTask(id: 't_join', titleZh: '参加 1 个活动', titleEn: 'Join 1 event', icon: Icons.celebration, xp: 20),
      ];

  // ---- 查询方法 ----
  UserProfile userById(String id) {
    if (id == 'me') return me;
    return users.firstWhere((u) => u.id == id, orElse: () => me);
  }
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
