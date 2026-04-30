import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/services/app_services.dart';
import '../../../common/presentation/widgets/app_empty_state.dart';
import '../../../common/presentation/widgets/app_error_state.dart';
import '../../../common/presentation/widgets/app_loading_state.dart';
import '../../domain/models/manager_employee_profile.dart';

class ManagerLeavePolicyScreen extends StatefulWidget {
  const ManagerLeavePolicyScreen({super.key});

  @override
  State<ManagerLeavePolicyScreen> createState() =>
      _ManagerLeavePolicyScreenState();
}

class _ManagerLeavePolicyScreenState extends State<ManagerLeavePolicyScreen> {
  List<ManagerEmployeeProfile> _profiles = const [];
  double _globalIncrement = 1.5;
  bool _isLoading = true;
  bool _isApplyingGlobal = false;
  String? _updatingEmployeeCode;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    unawaited(_loadProfiles());
  }

  Future<void> _loadProfiles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profiles = await AppServices.employeeProfileRepository
          .fetchEmployeeProfiles();
      if (!mounted) {
        return;
      }

      setState(() {
        _profiles = profiles.map((profile) => profile.copyWith()).toList();
        _globalIncrement = profiles.isEmpty
            ? 1.5
            : profiles
                      .map((profile) => profile.monthlyIncrement)
                      .reduce((sum, value) => sum + value) /
                  profiles.length;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'تعذر تحميل سياسة الإجازات حالياً.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  void _updateProfileIncrement(String code, double value) {
    setState(() {
      _profiles = _profiles
          .map(
            (profile) => profile.code == code
                ? profile.copyWith(monthlyIncrement: value)
                : profile,
          )
          .toList();
    });
  }

  Future<void> _applyGlobalIncrement() async {
    setState(() {
      _isApplyingGlobal = true;
    });

    try {
      final profiles = await AppServices.employeeProfileRepository
          .updateAllMonthlyIncrements(_globalIncrement);
      if (!mounted) {
        return;
      }

      setState(() {
        _profiles = profiles;
      });
      _showSnack(
        'تم تطبيق ${_globalIncrement.toStringAsFixed(1)} يوم شهرياً على جميع الموظفين.',
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showSnack('تعذر حفظ الزيادة العامة حالياً.');
    } finally {
      if (mounted) {
        setState(() {
          _isApplyingGlobal = false;
        });
      }
    }
  }

  Future<void> _saveEmployeeIncrement(String code) async {
    ManagerEmployeeProfile? profile;
    for (final item in _profiles) {
      if (item.code == code) {
        profile = item;
        break;
      }
    }
    if (profile == null) {
      return;
    }

    setState(() {
      _updatingEmployeeCode = code;
    });

    try {
      final updated = await AppServices.employeeProfileRepository
          .updateEmployeeMonthlyIncrement(
            employeeCode: code,
            monthlyIncrement: profile.monthlyIncrement,
          );
      if (!mounted) {
        return;
      }

      setState(() {
        _profiles = _profiles
            .map((item) => item.code == code ? updated : item)
            .toList();
      });
      _showSnack('تم حفظ الزيادة الشهرية للموظف ${updated.name}.');
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showSnack('تعذر حفظ قيمة هذا الموظف حالياً.');
    } finally {
      if (mounted) {
        setState(() {
          _updatingEmployeeCode = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 920;
    final cardWidth = isWide
        ? 340.0
        : ((width - 40).clamp(260.0, 480.0)).toDouble();

    return Scaffold(
      appBar: AppBar(title: const Text('سياسة الإجازات'), centerTitle: true),
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
                  title: 'جاري تحميل السياسة',
                  message: 'نجهز إعدادات الزيادة الشهرية للموظفين.',
                )
              : _errorMessage != null
              ? AppErrorState(
                  title: 'حدث خطأ',
                  message: _errorMessage!,
                  onRetry: _loadProfiles,
                )
              : _profiles.isEmpty
              ? const AppEmptyState(
                  title: 'لا توجد بيانات موظفين',
                  message: 'لا يوجد موظفون متاحون لتعديل السياسة حالياً.',
                  icon: Icons.groups_outlined,
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _PolicyHero(globalIncrement: _globalIncrement),
                          const SizedBox(height: 20),
                          _GlobalPolicyCard(
                            value: _globalIncrement,
                            isApplying: _isApplyingGlobal,
                            onChanged: (value) {
                              setState(() {
                                _globalIncrement = value;
                              });
                            },
                            onApply: _applyGlobalIncrement,
                          ),
                          const SizedBox(height: 20),
                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: _profiles
                                .map(
                                  (profile) => SizedBox(
                                    width: cardWidth,
                                    child: _EmployeePolicyCard(
                                      profile: profile,
                                      isSaving:
                                          _updatingEmployeeCode == profile.code,
                                      onChanged: (value) =>
                                          _updateProfileIncrement(
                                            profile.code,
                                            value,
                                          ),
                                      onSave: () =>
                                          _saveEmployeeIncrement(profile.code),
                                    ),
                                  ),
                                )
                                .toList(),
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

class _PolicyHero extends StatelessWidget {
  const _PolicyHero({required this.globalIncrement});

  final double globalIncrement;

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
          Text(
            'التحكم في الزيادة الشهرية للإجازات',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'يمكن للمدير تعديل القيمة الافتراضية لجميع الموظفين أو تخصيص قيمة مختلفة لموظف محدد حسب السياسة الداخلية.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.86),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'الإعداد العام الحالي: ${globalIncrement.toStringAsFixed(1)} يوم شهرياً',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlobalPolicyCard extends StatelessWidget {
  const _GlobalPolicyCard({
    required this.value,
    required this.isApplying,
    required this.onChanged,
    required this.onApply,
  });

  final double value;
  final bool isApplying;
  final ValueChanged<double> onChanged;
  final VoidCallback onApply;

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
          Text(
            'تطبيق قيمة عامة على الجميع',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Text(
            'القيمة الافتراضية المقترحة في المشروع هي 1.5 يوم شهرياً، ويمكنك تغييرها قبل التطبيق.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          Text(
            '${value.toStringAsFixed(1)} يوم',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          Slider(
            value: value,
            min: 0.5,
            max: 3.0,
            divisions: 10,
            label: value.toStringAsFixed(1),
            onChanged: isApplying ? null : onChanged,
          ),
          ElevatedButton.icon(
            onPressed: isApplying ? null : onApply,
            icon: Icon(
              isApplying ? Icons.hourglass_top_rounded : Icons.publish_rounded,
            ),
            label: Text(
              isApplying
                  ? 'جاري تطبيق القيمة العامة'
                  : 'تطبيق على جميع الموظفين',
            ),
          ),
        ],
      ),
    );
  }
}

class _EmployeePolicyCard extends StatelessWidget {
  const _EmployeePolicyCard({
    required this.profile,
    required this.isSaving,
    required this.onChanged,
    required this.onSave,
  });

  final ManagerEmployeeProfile profile;
  final bool isSaving;
  final ValueChanged<double> onChanged;
  final VoidCallback onSave;

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
          Row(
            children: [
              Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFE7EEFF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: Color(0xFF1D4ED8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${profile.department} • ${profile.code}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'الزيادة الحالية: ${profile.monthlyIncrement.toStringAsFixed(1)} يوم',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          Slider(
            value: profile.monthlyIncrement,
            min: 0.5,
            max: 3.0,
            divisions: 10,
            label: profile.monthlyIncrement.toStringAsFixed(1),
            onChanged: isSaving ? null : onChanged,
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              'الرصيد الحالي: ${profile.leaveBalanceLabel} • الإجازات المستخدمة: ${profile.usedLeavesLabel}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: isSaving ? null : onSave,
            icon: Icon(
              isSaving ? Icons.hourglass_top_rounded : Icons.save_outlined,
            ),
            label: Text(isSaving ? 'جاري الحفظ' : 'حفظ قيمة الموظف'),
          ),
        ],
      ),
    );
  }
}
