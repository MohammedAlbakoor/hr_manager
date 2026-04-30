import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/navigation/role_home_route.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/services/app_services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/login_request.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadSavedCredentials());
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isSubmitting = true;
    });

    try {
      final session = await AppServices.authRepository.signIn(
        LoginRequest(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          rememberMe: _rememberMe,
        ),
      );
      await AppServices.session.setSession(session);
      if (_rememberMe) {
        await AppServices.loginCredentialsStore.save(
          email: _emailController.text,
          password: _passwordController.text,
        );
      } else {
        await AppServices.loginCredentialsStore.clear();
      }

      if (!mounted) {
        return;
      }

      Navigator.of(
        context,
      ).pushReplacementNamed(homeRouteForRole(session.role));
    } catch (error) {
      if (!mounted) {
        return;
      }

      final message = _messageForError(error);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _loadSavedCredentials() async {
    final credentials = await AppServices.loginCredentialsStore.read();
    if (!mounted || credentials == null) {
      return;
    }

    _emailController.text = credentials.email;
    _passwordController.text = credentials.password;
    setState(() {
      _rememberMe = true;
    });
  }

  void _setRememberMe(bool value) {
    setState(() {
      _rememberMe = value;
    });
    if (!value) {
      unawaited(AppServices.loginCredentialsStore.clear());
    }
  }

  String _messageForError(Object error) {
    if (error is ApiException) {
      final message = error.message.trim();
      if (message == 'Invalid credentials.') {
        return 'البريد الإلكتروني أو كلمة المرور غير صحيحة.';
      }
      if (message.isNotEmpty) {
        return message;
      }
    }

    final fallback = error.toString().replaceFirst('Bad state: ', '').trim();
    if (fallback.isNotEmpty) {
      return fallback;
    }

    return 'تعذر تسجيل الدخول حاليًا، حاول مرة أخرى.';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width >= 520;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFFF4F7FB), Color(0xFFEAF2FF), Color(0xFFF7FBF9)],
          ),
        ),
        child: Stack(
          children: [
            const _LoginBackgroundDecor(),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isWide ? 28 : 16,
                      vertical: isWide ? 32 : 20,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - (isWide ? 64 : 40),
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 460),
                          child: _LoginFormCard(
                            formKey: _formKey,
                            emailController: _emailController,
                            passwordController: _passwordController,
                            rememberMe: _rememberMe,
                            isSubmitting: _isSubmitting,
                            onRememberChanged: _setRememberMe,
                            onSubmit: _submit,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginBackgroundDecor extends StatelessWidget {
  const _LoginBackgroundDecor();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            Positioned(
              top: -86,
              right: -64,
              child: _DecorCircle(
                size: 230,
                color: AppPalette.primary.withValues(alpha: 0.10),
              ),
            ),
            Positioned(
              bottom: -110,
              left: -74,
              child: _DecorCircle(
                size: 260,
                color: AppPalette.secondary.withValues(alpha: 0.12),
              ),
            ),
            Positioned(
              top: 126,
              left: 34,
              child: Transform.rotate(
                angle: -0.24,
                child: Container(
                  height: 132,
                  width: 132,
                  decoration: BoxDecoration(
                    color: AppPalette.secondary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(34),
                    border: Border.all(
                      color: AppPalette.secondary.withValues(alpha: 0.10),
                    ),
                  ),
                  child: Icon(
                    Icons.login_rounded,
                    color: AppPalette.secondary.withValues(alpha: 0.24),
                    size: 68,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 28,
              bottom: 118,
              child: Transform.rotate(
                angle: 0.28,
                child: Icon(
                  Icons.verified_user_outlined,
                  color: AppPalette.primary.withValues(alpha: 0.16),
                  size: 96,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DecorCircle extends StatelessWidget {
  const _DecorCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _LoginFormCard extends StatelessWidget {
  const _LoginFormCard({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.rememberMe,
    required this.isSubmitting,
    required this.onRememberChanged,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool rememberMe;
  final bool isSubmitting;
  final ValueChanged<bool> onRememberChanged;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppPalette.border),
        boxShadow: const [
          BoxShadow(
            color: AppPalette.shadow,
            blurRadius: 32,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Form(
          key: formKey,
          child: AutofillGroup(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      height: 52,
                      width: 52,
                      decoration: BoxDecoration(
                        color: AppPalette.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.lock_person_rounded,
                        color: AppPalette.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تسجيل الدخول',
                            style: theme.textTheme.headlineMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                TextFormField(
                  controller: emailController,
                  autofillHints: const [AutofillHints.email],
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    hintText: 'name@company.com',
                    prefixIcon: Icon(Icons.alternate_email_rounded),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'أدخل البريد الإلكتروني';
                    }
                    if (!value.contains('@')) {
                      return 'صيغة البريد غير صحيحة';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordController,
                  autofillHints: const [AutofillHints.password],
                  obscureText: true,
                  onFieldSubmitted: (_) {
                    if (!isSubmitting) {
                      onSubmit();
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'كلمة المرور',
                    hintText: '••••••••',
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'أدخل كلمة المرور';
                    }
                    if (value.trim().length < 6) {
                      return 'الحد الأدنى 6 أحرف';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppPalette.border),
                  ),
                  child: SwitchListTile.adaptive(
                    value: rememberMe,
                    onChanged: onRememberChanged,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                    title: Text('تذكرني', style: theme.textTheme.titleSmall),
                    secondary: const Icon(Icons.devices_rounded),
                  ),
                ),
                const SizedBox(height: 22),
                ElevatedButton.icon(
                  onPressed: isSubmitting ? null : onSubmit,
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: isSubmitting
                        ? const SizedBox(
                            key: ValueKey('loading'),
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.login_rounded,
                            key: ValueKey('icon'),
                          ),
                  ),
                  label: Text(isSubmitting ? 'جاري الدخول...' : 'تسجيل الدخول'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
