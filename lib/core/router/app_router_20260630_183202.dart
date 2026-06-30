import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/activity/activity_create_page.dart';
import '../../features/activity/activity_detail_page.dart';
import '../../features/activity/activity_list_page.dart';
import '../../features/auth/login_page.dart';
import '../../features/auth/tag_select_page.dart';
import '../../features/chat/chat_list_page.dart';
import '../../features/chat/chat_page.dart';
import '../../features/discover/compose_post_page.dart';
import '../../features/discover/discover_page.dart';
import '../../features/groups/group_detail_page.dart';
import '../../features/groups/groups_page.dart';
import '../../features/match/match_success_page.dart';
import '../../features/nearby/nearby_page.dart';
import '../../features/onboarding/onboarding_page.dart';
import '../../features/plaza/plaza_page.dart';
import '../../features/profile/about_page.dart';
import '../../features/profile/edit_profile_page.dart';
import '../../features/profile/personality_test_page.dart';
import '../../features/profile/profile_page.dart';
import '../../features/profile/rewards_page.dart';
import '../../features/profile/settings_page.dart';
import '../../features/profile/user_detail_page.dart';
import '../../features/splash/splash_page.dart';
import '../../shared/widgets/main_shell.dart';

final _rootKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (c, s) => const SplashPage()),
      GoRoute(path: '/onboarding', builder: (c, s) => const OnboardingPage()),
      GoRoute(path: '/login', builder: (c, s) => const LoginPage()),
      GoRoute(path: '/tag-select', builder: (c, s) => const TagSelectPage()),

      // 主框架：底部 4 Tab
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/discover', builder: (c, s) => const DiscoverPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/nearby', builder: (c, s) => const NearbyPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/groups', builder: (c, s) => const GroupsPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/activity', builder: (c, s) => const ActivityListPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/profile', builder: (c, s) => const ProfilePage()),
          ]),
        ],
      ),

      // 二级页（全屏 push）：带滑动 / 缩放过渡动效
      GoRoute(path: '/chat', pageBuilder: (c, s) => _slide(s, const ChatListPage())),
      GoRoute(path: '/chat/:id', pageBuilder: (c, s) => _slide(s, ChatPage(conversationId: s.pathParameters['id']!))),
      GoRoute(path: '/user/:id', pageBuilder: (c, s) => _slide(s, UserDetailPage(userId: s.pathParameters['id']!))),
      GoRoute(path: '/match/:id', pageBuilder: (c, s) => _scale(s, MatchSuccessPage(userId: s.pathParameters['id']!))),
      GoRoute(path: '/group/:id', pageBuilder: (c, s) => _slide(s, GroupDetailPage(groupId: s.pathParameters['id']!))),
      GoRoute(path: '/discover/compose', pageBuilder: (c, s) => _scale(s, const ComposePostPage())),
      GoRoute(path: '/plaza', pageBuilder: (c, s) => _scale(s, const PlazaPage())),
      GoRoute(path: '/activity/create', pageBuilder: (c, s) => _scale(s, const ActivityCreatePage())),
      GoRoute(path: '/activity/:id', pageBuilder: (c, s) => _slide(s, ActivityDetailPage(activityId: s.pathParameters['id']!))),
      GoRoute(path: '/profile/edit', pageBuilder: (c, s) => _slide(s, const EditProfilePage())),
      GoRoute(path: '/profile/settings', pageBuilder: (c, s) => _slide(s, const SettingsPage())),
      GoRoute(path: '/profile/about', pageBuilder: (c, s) => _slide(s, const AboutPage())),
      GoRoute(path: '/profile/rewards', pageBuilder: (c, s) => _slide(s, const RewardsPage())),
      GoRoute(path: '/profile/personality', pageBuilder: (c, s) => _scale(s, const PersonalityTestPage())),
    ],
  );
});

/// 滑入 + 淡入过渡（详情类页面）
CustomTransitionPage _slide(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    child: child,
    transitionsBuilder: (context, animation, secondary, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween(begin: const Offset(0.18, 0), end: Offset.zero).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// 缩放 + 淡入过渡（弹窗/沉浸类页面，如匹配成功、发布动态）
CustomTransitionPage _scale(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    transitionDuration: const Duration(milliseconds: 360),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    child: child,
    transitionsBuilder: (context, animation, secondary, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween(begin: 0.92, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}
