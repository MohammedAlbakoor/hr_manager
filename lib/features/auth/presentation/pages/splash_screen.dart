import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/navigation/role_home_route.dart';
import '../../../../core/services/app_services.dart';
import '../../../../core/session/app_user_session.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  AppUserSession? _pendingBiometricSession;
  bool _isAuthenticatingBiometric = false;
  String? _biometricErrorMessage;

  @override
  void initState() {
    super.initState();
    unawaited(_resolveStartRoute());
  }

  Future<void> _resolveStartRoute() async {
    final results = await Future.wait<dynamic>([
      Future<void>.delayed(const Duration(milliseconds: 300)),
      AppServices.authRepository.restoreSession(),
    ]);
    final session = results[1] as dynamic;

    if (!mounted) {
      return;
    }

    if (session is AppUserSession) {
      final biometricEnabled = await AppServices.biometricLockService
          .isEnabled();
      if (!mounted) {
        return;
      }

      if (biometricEnabled) {
        setState(() {
          _pendingBiometricSession = session;
          _biometricErrorMessage = null;
        });
        await _unlockWithBiometrics();
        return;
      }

      await AppServices.session.setSession(session);
      if (!mounted) {
        return;
      }
      Navigator.of(
        context,
      ).pushReplacementNamed(homeRouteForRole(session.role));
      return;
    }

    await AppServices.session.clear();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  Future<void> _unlockWithBiometrics() async {
    final session = _pendingBiometricSession;
    if (session == null || _isAuthenticatingBiometric) {
      return;
    }

    setState(() {
      _isAuthenticatingBiometric = true;
      _biometricErrorMessage = null;
    });

    final canUseBiometrics = await AppServices.biometricLockService
        .canUseBiometrics();
    final authenticated =
        canUseBiometrics &&
        await AppServices.biometricLockService.authenticate(
          reason: 'افتح القفل البيومتري للمتابعة إلى حسابك.',
        );

    if (!mounted) {
      return;
    }

    if (authenticated) {
      await AppServices.session.setSession(session);
      if (!mounted) {
        return;
      }
      Navigator.of(
        context,
      ).pushReplacementNamed(homeRouteForRole(session.role));
      return;
    }

    setState(() {
      _isAuthenticatingBiometric = false;
      _biometricErrorMessage = canUseBiometrics
          ? 'لم يتم تأكيد الهوية. حاول مرة أخرى للمتابعة.'
          : 'لا توجد بصمة أو وجه مفعّل على هذا الجهاز حالياً.';
    });
  }

  Future<void> _goToLogin() async {
    await AppServices.session.clear();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBiometricLocked = _pendingBiometricSession != null;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F172A), Color(0xFF102A5C), Color(0xFF1D4ED8)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -80,
              right: -40,
              child: _GlowCircle(
                size: 220,
                color: Colors.white.withValues(alpha: 0.09),
              ),
            ),
            Positioned(
              bottom: -90,
              left: -30,
              child: _GlowCircle(
                size: 200,
                color: const Color(0xFF5EEAD4).withValues(alpha: 0.16),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(),
                    Container(
                      height: 116,
                      width: 116,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(36),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                      ),
                      child: const Icon(
                        Icons.badge_outlined,
                        color: Colors.white,
                        size: 58,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      isBiometricLocked
                          ? 'القفل البيومتري مفعل'
                          : 'نظام إدارة الإجازات',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontSize: 32,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isBiometricLocked
                          ? 'أكّد هويتك بالبصمة أو الوجه للمتابعة إلى حسابك.'
                          : 'إدارة الطلبات والموافقات وتسجيل الحضور عبر QR في تجربة واحدة مرتبة وواضحة.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ),
                    const Spacer(),
                    if (isBiometricLocked) ...[
                      if (_biometricErrorMessage != null) ...[
                        Text(
                          _biometricErrorMessage!,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFFFECACA),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      ElevatedButton.icon(
                        onPressed: _isAuthenticatingBiometric
                            ? null
                            : _unlockWithBiometrics,
                        icon: _isAuthenticatingBiometric
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.fingerprint_rounded),
                        label: Text(
                          _isAuthenticatingBiometric
                              ? 'جاري التحقق...'
                              : 'فتح القفل',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: _isAuthenticatingBiometric
                            ? null
                            : _goToLogin,
                        child: const Text('تسجيل الدخول بكلمة المرور'),
                      ),
                    ] else ...[
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.15, end: 1),
                        duration: Duration(milliseconds: 1100),
                        curve: Curves.easeOutCubic,
                        builder: _buildProgress,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'جارِ تهيئة النظام',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.74),
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildProgress(
    BuildContext context,
    double value,
    Widget? child,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        minHeight: 8,
        value: value,
        backgroundColor: Colors.white.withValues(alpha: 0.18),
        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF5EEAD4)),
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
