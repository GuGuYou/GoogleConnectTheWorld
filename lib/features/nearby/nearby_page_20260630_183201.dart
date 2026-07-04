import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_text.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/data/repositories.dart';
import '../../shared/widgets/gradient_text.dart';
import '../../shared/widgets/neon_background.dart';
import 'nearby_map_view.dart';
import 'widgets/match_card.dart';

class NearbyPage extends ConsumerStatefulWidget {
  const NearbyPage({super.key});

  @override
  ConsumerState<NearbyPage> createState() => _NearbyPageState();
}

class _NearbyPageState extends ConsumerState<NearbyPage> {
  bool _mapMode = false;
  final _swiper = CardSwiperController();

  @override
  void dispose() {
    _swiper.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider).languageCode;
    final nearby = ref.watch(nearbyUsersProvider);

    return NeonBackground(
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  GradientText(ref.tr('nearby_title'), style: AppTextStyles.h1),
                  const Spacer(),
                  _Toggle(
                    mapMode: _mapMode,
                    listLabel: ref.tr('view_list'),
                    mapLabel: ref.tr('view_map'),
                    onChanged: (v) => setState(() => _mapMode = v),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _mapMode
                  ? const NearbyMapView()
                  : _SwipeDeck(nearby: nearby, lang: lang, controller: _swiper),
            ),
          ],
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  final bool mapMode;
  final String listLabel;
  final String mapLabel;
  final ValueChanged<bool> onChanged;
  const _Toggle({required this.mapMode, required this.listLabel, required this.mapLabel, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _seg(Icons.view_agenda, listLabel, !mapMode, () => onChanged(false)),
          _seg(Icons.map, mapLabel, mapMode, () => onChanged(true)),
        ],
      ),
    );
  }

  Widget _seg(IconData icon, String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: active ? AppColors.cyanPurple : null,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: active ? Colors.white : AppColors.textMuted),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12, color: active ? Colors.white : AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _SwipeDeck extends ConsumerWidget {
  final List<UserWithDistance> nearby;
  final String lang;
  final CardSwiperController controller;
  const _SwipeDeck({required this.nearby, required this.lang, required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (nearby.isEmpty) {
      return Center(child: Text(ref.tr('no_more_cards'), style: AppTextStyles.body));
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(ref.tr('swipe_hint'), style: AppTextStyles.caption),
        ),
        Expanded(
          child: CardSwiper(
            controller: controller,
            cardsCount: nearby.length,
            numberOfCardsDisplayed: nearby.length >= 3 ? 3 : nearby.length,
            backCardOffset: const Offset(0, 40),
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
            onSwipe: (prev, curr, dir) {
              if (dir == CardSwiperDirection.right) {
                context.push('/match/${nearby[prev].user.id}');
              }
              return true;
            },
            cardBuilder: (context, index, _, __) => GestureDetector(
              onTap: () => context.push('/user/${nearby[index].user.id}'),
              child: MatchCard(data: nearby[index], lang: lang),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(40, 8, 40, 90),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _circleBtn(Icons.close, AppColors.textMuted, () => controller.swipe(CardSwiperDirection.left)),
              _circleBtn(Icons.favorite, AppColors.neonPink, () => controller.swipe(CardSwiperDirection.right), big: true),
              _circleBtn(Icons.chat_bubble, AppColors.neonCyan, () {
                context.push('/chat/conv_${nearby.first.user.id}');
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _circleBtn(IconData icon, Color color, VoidCallback onTap, {bool big = false}) {
    final size = big ? 64.0 : 52.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.bg2,
          border: Border.all(color: color, width: 2),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 14)],
        ),
        child: Icon(icon, color: color, size: big ? 30 : 24),
      ),
    );
  }
}
