import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/services/app_services.dart';
import '../../domain/models/account_profile_data.dart';
import '../../domain/models/app_user_role.dart';
import '../widgets/app_error_state.dart';
import '../widgets/app_loading_state.dart';
import '../widgets/role_bottom_navigation_bar.dart';

class ProfileAccountScreen extends StatefulWidget {
  const ProfileAccountScreen({super.key, required this.role});

  final AppUserRole role;

  @override
  State<ProfileAccountScreen> createState() => _ProfileAccountScreenState();
}

class _ProfileAccountScreenState extends State<ProfileAccountScreen> {
  AccountProfileData? _profile;
  bool _pushNotifications = true;
  bool _biometricLock = false;
  bool _rememberDevice = true;
  bool _isUpdatingBiometric = false;
  bool _isRequestingPasswordChange = false;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    unawaited(_loadProfile());
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait<dynamic>([
        AppServices.commonRepository.fetchProfile(widget.role),
        AppServices.biometricLockService.isEnabled(),
      ]);
      if (!mounted) {
        return;
      }

      setState(() {
        _profile = results[0] as AccountProfileData;
        _biometricLock = results[1] as bool;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'تعذر تحميل بيانات الحساب حالياً.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleBiometricChanged(bool value) async {
    if (_isUpdatingBiometric) {
      return;
    }

    setState(() {
      _isUpdatingBiometric = true;
    });

    try {
      if (!value) {
        await AppServices.biometricLockService.setEnabled(false);
        if (!mounted) {
          return;
        }
        setState(() {
          _biometricLock = false;
        });
        _showSnack('تم إيقاف القفل البيومتري.');
        return;
      }

      final canUseBiometrics = await AppServices.biometricLockService
          .canUseBiometrics();
      if (!canUseBiometrics) {
        if (!mounted) {
          return;
        }
        _showSnack('لا توجد بصمة أو وجه مفعّل على هذا الجهاز حالياً.');
        return;
      }

      final authenticated = await AppServices.biometricLockService.authenticate(
        reason: 'أكّد هويتك لتفعيل القفل البيومتري.',
      );
      if (!mounted) {
        return;
      }

      if (!authenticated) {
        _showSnack('لم يتم تفعيل القفل لأن التحقق البيومتري لم يكتمل.');
        return;
      }

      await AppServices.biometricLockService.setEnabled(true);
      if (!mounted) {
        return;
      }
      setState(() {
        _biometricLock = true;
      });
      _showSnack('تم تفعيل القفل البيومتري.');
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingBiometric = false;
        });
      }
    }
  }

  Future<void> _requestPasswordChange() async {
    if (_isRequestingPasswordChange) {
      return;
    }

    final password = await _showPasswordChangeRequestDialog();
    if (password == null) {
      return;
    }

    setState(() {
      _isRequestingPasswordChange = true;
    });

    try {
      await AppServices.commonRepository.requestPasswordChange(
        password: password,
      );
      if (!mounted) {
        return;
      }
      _showSnack(
        'تم إرسال طلب تغيير كلمة المرور إلى الموارد البشرية بانتظار الموافقة.',
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showSnack('تعذر إرسال طلب تغيير كلمة المرور حالياً.');
    } finally {
      if (mounted) {
        setState(() {
          _isRequestingPasswordChange = false;
        });
      }
    }
  }

  Future<String?> _showPasswordChangeRequestDialog() {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _PasswordChangeRequestDialog(),
    );
  }

  void _handlePrimaryNavigation(int index) {
    final role = _profile?.role ?? widget.role;

    switch (role) {
      case AppUserRole.employee:
        switch (index) {
          case 0:
            Navigator.of(
              context,
            ).pushReplacementNamed(AppRoutes.employeeDashboard);
            return;
          case 1:
            Navigator.of(
              context,
            ).pushReplacementNamed(AppRoutes.employeeLeaveHistory);
            return;
          case 2:
            Navigator.of(
              context,
            ).pushReplacementNamed(AppRoutes.employeeAttendanceHistory);
            return;
          case 3:
            Navigator.of(
              context,
            ).pushReplacementNamed(AppRoutes.notifications, arguments: role);
            return;
          case 4:
            return;
        }
      case AppUserRole.manager:
        switch (index) {
          case 0:
            Navigator.of(
              context,
            ).pushReplacementNamed(AppRoutes.managerDashboard);
            return;
          case 1:
            Navigator.of(
              context,
            ).pushReplacementNamed(AppRoutes.managerLeaveRequests);
            return;
          case 2:
            Navigator.of(
              context,
            ).pushReplacementNamed(AppRoutes.managerEmployeeDetails);
            return;
          case 3:
            Navigator.of(
              context,
            ).pushReplacementNamed(AppRoutes.managerBroadcasts);
            return;
          case 4:
            Navigator.of(
              context,
            ).pushReplacementNamed(AppRoutes.notifications, arguments: role);
            return;
          case 5:
            return;
        }
      case AppUserRole.hr:
      case AppUserRole.admin:
        switch (index) {
          case 0:
            Navigator.of(context).pushReplacementNamed(
              role == AppUserRole.admin
                  ? AppRoutes.adminDashboard
                  : AppRoutes.hrDashboard,
            );
            return;
          case 1:
            Navigator.of(
              context,
            ).pushReplacementNamed(AppRoutes.hrLeaveRequests);
            return;
          case 2:
            Navigator.of(
              context,
            ).pushReplacementNamed(AppRoutes.hrEmployeeDetails);
            return;
          case 3:
            Navigator.of(
              context,
            ).pushReplacementNamed(AppRoutes.notifications, arguments: role);
            return;
          case 4:
            return;
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 920;
    final profile = _profile ?? AppServices.session.currentSession?.profile;
    final role = profile?.role ?? widget.role;

    return Scaffold(
      bottomNavigationBar: RoleBottomNavigationBar(
        role: role,
        selectedIndex: role == AppUserRole.manager ? 5 : 4,
        onDestinationSelected: _handlePrimaryNavigation,
      ),
      appBar: AppBar(title: const Text('الحساب الشخصي'), centerTitle: true),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FAFC), Color(0xFFF0F9FF)],
          ),
        ),
        child: SafeArea(
          top: false,
          child: _isLoading
              ? const AppLoadingState(
                  title: 'جاري تحميل الحساب',
                  message: 'نجهز بيانات الحساب والإعدادات الخاصة بك.',
                )
              : _errorMessage != null
              ? AppErrorState(
                  title: 'تعذر تحميل الحساب',
                  message: _errorMessage!,
                  onRetry: _loadProfile,
                )
              : profile == null
              ? AppErrorState(
                  title: 'تعذر تحميل الحساب',
                  message:
                      'لا توجد بيانات حساب متاحة حالياً. سجّل الدخول مجدداً أو أعد المحاولة.',
                  onRetry: _loadProfile,
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Hero(profile: profile),
                          const SizedBox(height: 20),
                          Wrap(
                            spacing: 14,
                            runSpacing: 14,
                            children:
                                [
                                      _MetricCard(
                                        title: 'نوع الحساب',
                                        value: role.label,
                                        icon: role.icon,
                                        color: role.color,
                                      ),
                                      _MetricCard(
                                        title: 'القسم',
                                        value: profile.department,
                                        icon: Icons.apartment_rounded,
                                        color: const Color(0xFF0F766E),
                                      ),
                                      _MetricCard(
                                        title: 'الدوام',
                                        value: profile.workSchedule,
                                        icon: Icons.schedule_rounded,
                                        color: const Color(0xFFEA580C),
                                      ),
                                      _MetricCard(
                                        title: 'الصلاحيات',
                                        value: '${profile.permissions.length}',
                                        icon: Icons.verified_user_outlined,
                                        color: const Color(0xFF7C3AED),
                                      ),
                                    ]
                                    .map(
                                      (card) => SizedBox(
                                        width: isWide ? 250 : width - 40,
                                        child: card,
                                      ),
                                    )
                                    .toList(),
                          ),
                          const SizedBox(height: 20),
                          if (isWide)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _InfoCard(profile: profile)),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _SecurityCard(
                                    deviceLabel: profile.deviceLabel,
                                    lastLogin: profile.lastLogin,
                                    biometricLock: _biometricLock,
                                    rememberDevice: _rememberDevice,
                                    isBiometricBusy: _isUpdatingBiometric,
                                    onBiometricChanged: _handleBiometricChanged,
                                    onRememberChanged: (value) {
                                      setState(() {
                                        _rememberDevice = value;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            )
                          else ...[
                            _InfoCard(profile: profile),
                            const SizedBox(height: 16),
                            _SecurityCard(
                              deviceLabel: profile.deviceLabel,
                              lastLogin: profile.lastLogin,
                              biometricLock: _biometricLock,
                              rememberDevice: _rememberDevice,
                              isBiometricBusy: _isUpdatingBiometric,
                              onBiometricChanged: _handleBiometricChanged,
                              onRememberChanged: (value) {
                                setState(() {
                                  _rememberDevice = value;
                                });
                              },
                            ),
                          ],
                          const SizedBox(height: 20),
                          if (isWide)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _PreferencesCard(
                                    pushNotifications: _pushNotifications,
                                    onPushChanged: (value) {
                                      setState(() {
                                        _pushNotifications = value;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _PermissionsCard(
                                    permissions: profile.permissions,
                                  ),
                                ),
                              ],
                            )
                          else ...[
                            _PreferencesCard(
                              pushNotifications: _pushNotifications,
                              onPushChanged: (value) {
                                setState(() {
                                  _pushNotifications = value;
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            _PermissionsCard(permissions: profile.permissions),
                          ],
                          const SizedBox(height: 20),
                          _ActionsCard(
                            isRequestingPasswordChange:
                                _isRequestingPasswordChange,
                            onChangePassword: _requestPasswordChange,
                            onLogout: () async {
                              await AppServices.authRepository.signOut();
                              await AppServices.session.clear();

                              if (!context.mounted) {
                                return;
                              }

                              Navigator.of(context).pushNamedAndRemoveUntil(
                                AppRoutes.login,
                                (route) => false,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _PasswordChangeRequestDialog extends StatefulWidget {
  const _PasswordChangeRequestDialog();

  @override
  State<_PasswordChangeRequestDialog> createState() =>
      _PasswordChangeRequestDialogState();
}

class _PasswordChangeRequestDialogState
    extends State<_PasswordChangeRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }
    Navigator.of(context).pop(_passwordController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('طلب تغيير كلمة المرور'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'سيتم إرسال الطلب إلى الموارد البشرية، ولن تتغير كلمة المرور إلا بعد الموافقة.',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'كلمة المرور الجديدة',
                    prefixIcon: Icon(Icons.lock_reset_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'أدخل كلمة المرور الجديدة';
                    }
                    if (value.trim().length < 6) {
                      return 'الحد الأدنى 6 أحرف';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'تأكيد كلمة المرور',
                    prefixIcon: Icon(Icons.verified_user_outlined),
                  ),
                  onFieldSubmitted: (_) => _submit(),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'أعد إدخال كلمة المرور';
                    }
                    if (value.trim() != _passwordController.text.trim()) {
                      return 'كلمتا المرور غير متطابقتين';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        ElevatedButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.send_outlined),
          label: const Text('إرسال الطلب'),
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.profile});

  final AccountProfileData profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF0F172A), Color(0xFF102A5C), Color(0xFF1D4ED8)],
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 58,
                width: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(profile.role.icon, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${profile.jobTitle} - ${profile.department}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.78),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: profile.permissions
                .take(3)
                .map(
                  (permission) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      permission,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 14),
          Text(title, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _PanelCard extends StatelessWidget {
  const _PanelCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.profile});

  final AccountProfileData profile;

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      title: 'معلومات الحساب',
      child: Column(
        children: [
          _InfoLine(label: 'الرقم', value: profile.code),
          _InfoLine(label: 'البريد الإلكتروني', value: profile.email),
          _InfoLine(label: 'الهاتف', value: profile.phone),
          _InfoLine(label: 'تاريخ الانضمام', value: profile.joinDate),
          _InfoLine(label: 'موقع العمل', value: profile.workLocation),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: const Color(0xFF64748B)),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecurityCard extends StatelessWidget {
  const _SecurityCard({
    required this.deviceLabel,
    required this.lastLogin,
    required this.biometricLock,
    required this.rememberDevice,
    required this.isBiometricBusy,
    required this.onBiometricChanged,
    required this.onRememberChanged,
  });

  final String deviceLabel;
  final String lastLogin;
  final bool biometricLock;
  final bool rememberDevice;
  final bool isBiometricBusy;
  final Future<void> Function(bool value) onBiometricChanged;
  final ValueChanged<bool> onRememberChanged;

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      title: 'الأمان والجهاز',
      child: Column(
        children: [
          _InfoLine(label: 'آخر تسجيل دخول', value: lastLogin),
          _InfoLine(label: 'الجهاز الحالي', value: deviceLabel),
          SwitchListTile(
            value: biometricLock,
            onChanged: isBiometricBusy
                ? null
                : (value) => unawaited(onBiometricChanged(value)),
            title: const Text('تفعيل القفل البيومتري'),
            subtitle: const Text('طلب البصمة أو الوجه عند فتح التطبيق'),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            value: rememberDevice,
            onChanged: onRememberChanged,
            title: const Text('تذكر هذا الجهاز'),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

class _PreferencesCard extends StatelessWidget {
  const _PreferencesCard({
    required this.pushNotifications,
    required this.onPushChanged,
  });

  final bool pushNotifications;
  final ValueChanged<bool> onPushChanged;

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      title: 'تفضيلات الإشعارات',
      child: Column(
        children: [
          SwitchListTile(
            value: pushNotifications,
            onChanged: onPushChanged,
            title: const Text('إشعارات داخل التطبيق'),
            subtitle: const Text('استقبال التنبيهات مباشرة من النظام'),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

class _PermissionsCard extends StatelessWidget {
  const _PermissionsCard({required this.permissions});

  final List<String> permissions;

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      title: 'الصلاحيات الحالية',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: permissions
            .map(
              (permission) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Text(
                  permission,
                  style: const TextStyle(
                    color: Color(0xFF1D4ED8),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ActionsCard extends StatelessWidget {
  const _ActionsCard({
    required this.isRequestingPasswordChange,
    required this.onChangePassword,
    required this.onLogout,
  });

  final bool isRequestingPasswordChange;
  final Future<void> Function() onChangePassword;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      title: 'إجراءات الحساب',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final changePasswordButton = _FixedHeightButton(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: isRequestingPasswordChange
                  ? null
                  : () => unawaited(onChangePassword()),
              icon: isRequestingPasswordChange
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.lock_reset_rounded),
              label: Text(
                isRequestingPasswordChange
                    ? 'جاري الإرسال'
                    : 'تغيير كلمة المرور',
              ),
            ),
          );
          final logoutButton = _FixedHeightButton(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: onLogout,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('تسجيل الخروج'),
            ),
          );

          if (constraints.maxWidth < 430) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                changePasswordButton,
                const SizedBox(height: 12),
                logoutButton,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: changePasswordButton),
              const SizedBox(width: 12),
              Expanded(child: logoutButton),
            ],
          );
        },
      ),
    );
  }
}

class _FixedHeightButton extends StatelessWidget {
  const _FixedHeightButton({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 50, child: child);
  }
}
