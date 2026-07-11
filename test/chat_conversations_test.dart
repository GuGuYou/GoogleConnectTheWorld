import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gobuzz/shared/data/repositories.dart';

/// Behaviour of the dynamic conversation list that drives the chat inbox,
/// unread badge and message previews. Pure Riverpod logic — no timers/UI.
void main() {
  test('seed is sorted newest-first and unread total matches the list', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);

    final convs = c.read(conversationsProvider);
    expect(convs, isNotEmpty);
    for (var i = 0; i < convs.length - 1; i++) {
      expect(!convs[i].lastTime.isBefore(convs[i + 1].lastTime), isTrue,
          reason: 'conversations must be ordered newest-first');
    }
    expect(c.read(unreadTotalProvider),
        convs.fold<int>(0, (s, x) => s + x.unread));
  });

  test('markRead clears a conversation unread and lowers the total', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);

    final before = c.read(unreadTotalProvider);
    final target = c.read(conversationsProvider).firstWhere((x) => x.unread > 0);
    c.read(conversationsProvider.notifier).markRead(target.id);

    final after =
        c.read(conversationsProvider).firstWhere((x) => x.id == target.id);
    expect(after.unread, 0);
    expect(c.read(unreadTotalProvider), before - target.unread);
  });

  test('bump moves a conversation to the top with the new preview', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);

    final last = c.read(conversationsProvider).last;
    c
        .read(conversationsProvider.notifier)
        .bump(last.id, last.peerId, 'newest line');

    final convs = c.read(conversationsProvider);
    expect(convs.first.id, last.id);
    expect(convs.first.lastMessage, 'newest line');
  });

  test('bump with incUnread raises the badge; my own send does not', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);

    final target = c.read(conversationsProvider).first;
    c.read(conversationsProvider.notifier).markRead(target.id);
    final base = c.read(unreadTotalProvider);

    // Peer message → unread grows.
    c
        .read(conversationsProvider.notifier)
        .bump(target.id, target.peerId, 'hi', incUnread: true);
    expect(c.read(unreadTotalProvider), base + 1);

    // My own send (default incUnread:false) → unread unchanged.
    c.read(conversationsProvider.notifier).markRead(target.id);
    final base2 = c.read(unreadTotalProvider);
    c.read(conversationsProvider.notifier).bump(target.id, target.peerId, 'me');
    expect(c.read(unreadTotalProvider), base2);
  });

  test('bump creates a brand-new conversation (messaging a fresh friend)', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);

    const id = 'conv_brand_new_peer';
    expect(c.read(conversationsProvider).any((x) => x.id == id), isFalse);

    c
        .read(conversationsProvider.notifier)
        .bump(id, 'brand_new_peer', 'first message');

    final convs = c.read(conversationsProvider);
    expect(convs.first.id, id);
    expect(convs.first.lastMessage, 'first message');
  });
}
