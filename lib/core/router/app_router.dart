import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/activity/activity_create_page.dart';
import '../../features/activity/activity_detail_page.dart';
import '../../features/activity/activity_list_page.dart';
import '../../features/auth/login_page.dart';
import '../../features/auth/tag_select_page.dart';
import '../../features/avatar/avatar_ai_generate_page.dart';
import '../../features/avatar/avatar_customize_page.dart';
import '../../features/avatar/avatar_setup_page.dart';
import '../../features/chat/chat_list_page.dart';
import '../../features/chat/chat_page.dart';
import '../../features/discover/discover_page.dart';
import '../../features/nearby/nearby_page.dart';
import '../../features/onboarding/onboarding_page.dart';
import '../../features/profile/about_page.dart';
import '../../features/profile/edit_profile_page.dart';
import '../../features/profile/profile_page.dart';
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
      GoRoute(path: '/avatar-setup', builder: (c, s) => AvatarSetupPage(returnLocation: s.uri.queryParameters['return'] ?? '/tag-select')),
      GoRoute(path: '/avatar-customize', builder: (c, s) => AvatarCustomizePage(returnLocation: s.uri.queryParameters['return'] ?? '/tag-select')),
      GoRoute(path: '/avatar-ai', builder: (c, s) => AvatarAiGeneratePage(returnLocation: s.uri.queryParameters['return'] ?? '/tag-select')),
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
            GoRoute(path: '/activity', builder: (c, s) => const ActivityListPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/profile', builder: (c, s) => const ProfilePage()),
          ]),
        ],
      ),

      // 二级页（全屏 push）
      GoRoute(path: '/chat', builder: (c, s) => const ChatListPage()),
      GoRoute(path: '/chat/:id', builder: (c, s) => ChatPage(conversationId: s.pathParameters['id']!)),
      GoRoute(path: '/user/:id', builder: (c, s) => UserDetailPage(userId: s.pathParameters['id']!)),
      GoRoute(path: '/activity/create', builder: (c, s) => const ActivityCreatePage()),
      GoRoute(path: '/activity/:id', builder: (c, s) => ActivityDetailPage(activityId: s.pathParameters['id']!)),
      GoRoute(path: '/profile/edit', builder: (c, s) => const EditProfilePage()),
      GoRoute(path: '/profile/settings', builder: (c, s) => const SettingsPage()),
      GoRoute(path: '/profile/about', builder: (c, s) => const AboutPage()),
    ],
  );
});
