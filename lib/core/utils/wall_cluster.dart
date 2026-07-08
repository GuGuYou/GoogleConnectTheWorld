import '../config/map_config.dart';
import '../../shared/models/ip_tag.dart';
import '../../shared/models/wall_message.dart';
import '../../shared/models/wall_spot.dart';
import 'distance.dart';

/// 将可见留言按坐标就近聚合为留言板（默认 100m）。
/// 排除锚点、已删除、审核未通过的留言。
List<WallSpot> buildWallSpots(List<WallMessage> messages) {
  final displayable = messages.where((m) => m.isDisplayable).toList();
  if (displayable.isEmpty) return [];

  final clusters = <List<WallMessage>>[];
  for (final msg in displayable) {
    var placed = false;
    for (final cluster in clusters) {
      final rep = cluster.first;
      if (haversineKm(msg.lat, msg.lng, rep.lat, rep.lng) * 1000 <= MapConfig.wallClusterRadiusMeters) {
        cluster.add(msg);
        placed = true;
        break;
      }
    }
    if (!placed) clusters.add([msg]);
  }

  return [
    for (var i = 0; i < clusters.length; i++)
      _spotFromCluster('spot_$i', clusters[i]),
  ];
}

WallSpot _spotFromCluster(String id, List<WallMessage> cluster) {
  final lat = cluster.map((m) => m.lat).reduce((a, b) => a + b) / cluster.length;
  final lng = cluster.map((m) => m.lng).reduce((a, b) => a + b) / cluster.length;
  final tagSet = <IpTag>{};
  for (final m in cluster) {
    tagSet.addAll(m.tags);
  }
  final tags = tagSet.toList();
  return WallSpot(
    id: id,
    lat: lat,
    lng: lng,
    primaryTag: cluster.first.tags.first,
    messageCount: cluster.length,
    tags: tags,
  );
}

/// 查找坐标所属的留言板 id，若无则生成新 id
String spotIdForCoordinate(List<WallMessage> existing, double lat, double lng) {
  final spots = buildWallSpots(existing);
  for (final spot in spots) {
    if (haversineKm(lat, lng, spot.lat, spot.lng) * 1000 <= MapConfig.wallClusterRadiusMeters) {
      return spot.id;
    }
  }
  return 'spot_${DateTime.now().millisecondsSinceEpoch}';
}

List<WallMessage> messagesForSpot(List<WallMessage> messages, WallSpot spot) {
  return messages
      .where((m) => m.isDisplayable &&
          haversineKm(m.lat, m.lng, spot.lat, spot.lng) * 1000 <= MapConfig.wallClusterRadiusMeters)
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
}

/// 查找坐标附近是否已有留言板（100m 内）
WallSpot? findSpotNear(List<WallMessage> messages, double lat, double lng) {
  for (final spot in buildWallSpots(messages)) {
    if (haversineKm(lat, lng, spot.lat, spot.lng) * 1000 <= MapConfig.wallClusterRadiusMeters) {
      return spot;
    }
  }
  return null;
}
