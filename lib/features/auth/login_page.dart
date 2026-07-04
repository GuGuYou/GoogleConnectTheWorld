import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_text.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/gradient_text.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/neon_background.dart';
import '../../shared/widgets/neon_button.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  int _countdown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  void _startCountdown() {
    setState(() => _countdown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown <= 1) {
        t.cancel();
        setState(() => _countdown = 0);
      } else {
        setState(() => _countdown--);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider).languageCode;
    return Scaffold(
      body: NeonBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: TextButton.icon(
                    onPressed: () => ref.read(localeProvider.notifier).toggle(),
                    icon: const Icon(Icons.translate, size: 18, color: AppColors.neonCyan),
                    label: Text(lang == 'zh' ? 'EN' : '中', style: const TextStyle(color: AppColors.neonCyan)),
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.neonGradient,
                    boxShadow: [BoxShadow(color: AppColors.neonPink.withOpacity(0.5), blurRadius: 30)],
                  ),
                  child: const Icon(Icons.hub, size: 48, color: Colors.white),
                ).animate().scale(duration: 500.ms),
                const SizedBox(height: 24),
                GradientText(ref.tr('app_name'), style: AppTextStyles.h1),
                const SizedBox(height: 6),
                Text(ref.tr('tagline'), style: AppTextStyles.body),
                const SizedBox(height: 40),
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _field(
                        controller: _phone,
                        icon: Icons.phone_iphone,
                        hint: ref.tr('phone_hint'),
                        keyboard: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _field(
                              controller: _code,
                              icon: Icons.lock_outline,
                              hint: ref.tr('code_hint'),
                              keyboard: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          TextButton(
                            onPressed: _countdown > 0 ? null : _startCountdown,
                            child: Text(
                              _countdown > 0 ? '${_countdown}s' : ref.tr('get_code'),
                              style: TextStyle(
                                color: _countdown > 0 ? AppColors.textMuted : AppColors.neonCyan,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                NeonButton(
                  label: ref.tr('login_btn'),
                  icon: Icons.login,
                  onPressed: () => context.go('/avatar-setup'),
                ),
                const SizedBox(height: 16),
                Text(ref.tr('agree_tip'), style: AppTextStyles.caption, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    required TextInputType keyboard,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      style: AppTextStyles.bodyStrong,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppColors.neonCyan, size: 20),
        hintText: hint,
        hintStyle: AppTextStyles.caption,
        filled: true,
        fillColor: Colors.white.withOpacity(0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}
