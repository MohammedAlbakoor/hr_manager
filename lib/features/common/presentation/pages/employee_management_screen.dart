import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/services/app_services.dart';
import '../../domain/models/app_user_role.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_error_state.dart';
import '../widgets/app_loading_state.dart';
import '../widgets/employee_editor_dialog.dart';
import '../widgets/employee_password_dialog.dart';
import '../widgets/role_bottom_navigation_bar.dart';
import '../../../manager/domain/models/employee_manager_option.dart';
import '../../../manager/domain/models/manager_employee_profile.dart';

part 'employee_management_sections.dart';

class EmployeeManagementScreen extends StatefulWidget {
  const EmployeeManagementScreen({
    super.key,
    required this.role,
    this.initialProfile,
  });

  final AppUserRole role;
  final ManagerEmployeeProfile? initialProfile;

  @override
  State<EmployeeManagementScreen> createState() =>
      _EmployeeManagementScreenState();
}

class _EmployeeManagementScreenState extends State<EmployeeManagementScreen> {
  final _searchController = TextEditingController();

  List<ManagerEmployeeProfile> _profiles = const [];
  List<EmployeeManagerOption> _managerOptions = const [];
  ManagerEmployeeProfile? _selected;
  bool _isLoading = true;
  bool _isBusy = false;
  String? _error;
  String _query = '';
  String _status = 'active';
  String? _department;
  int? _managerId;

  bool get _isHr => widget.role == AppUserRole.hr;
  bool get _isAdmin => widget.role == AppUserRole.admin;
  bool get _canAssignManagers => _isHr || _isAdmin;
  bool get _canManagePasswords => _isHr || _isAdmin;
  bool get _showDirectory => widget.initialProfile == null;
  bool get _hasFilters =>
      _query.trim().isNotEmpty ||
      _department != null ||
      _managerId != null ||
      _status != 'active';

  int get _activeCount =>
      _profiles.where((employee) => employee.isActive).length;
  int get _deletedCount =>
      _profiles.where((employee) => employee.isDeleted).length;

  String? get _departmentFilterValue =>
      _department != null && _departments.contains(_department)
      ? _department
      : null;

  int? get _managerFilterValue =>
      _managerId != null &&
          _managerOptions.any((manager) => manager.id == _managerId)
      ? _managerId
      : null;

  List<String> get _departments =>
      _profiles
          .map((employee) => employee.department)
          .where((department) => department.isNotEmpty && department != '--')
          .toSet()
          .toList()
        ..sort();

  List<ManagerEmployeeProfile> get _filtered {
    final normalizedQuery = _query.trim().toLowerCase();

    return _profiles.where((employee) {
      final matchesSearch =
          normalizedQuery.isEmpty ||
          employee.name.toLowerCase().contains(normalizedQuery) ||
          employee.code.toLowerCase().contains(normalizedQuery);
      final matchesDepartment =
          _department == null || employee.department == _department;
      final matchesManager =
          _managerId == null || employee.managerId == _managerId;
      final matchesStatus = switch (_status) {
        'deleted' => employee.isDeleted,
        'all' => true,
        _ => employee.isActive,
      };

      return matchesSearch &&
          matchesDepartment &&
          matchesManager &&
          matchesStatus;
    }).toList();
  }

  ManagerEmployeeProfile? get _current {
    if (_filtered.isEmpty) {
      return null;
    }

    final selected = _selected;
    if (selected == null) {
      return _filtered.first;
    }

    for (final employee in _filtered) {
      if (employee.code == selected.code) {
        return employee;
      }
    }

    return _filtered.first;
  }

  @override
  void initState() {
    super.initState();
    _selected = widget.initialProfile;
    unawaited(_load(preferredCode: widget.initialProfile?.code));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({String? preferredCode}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait<dynamic>([
        _showDirectory
            ? AppServices.employeeProfileRepository.fetchEmployeeProfiles()
            : _loadSingle(),
        _canAssignManagers
            ? AppServices.employeeProfileRepository.fetchManagerOptions()
            : Future<List<EmployeeManagerOption>>.value(const []),
      ]);

      final profiles = results[0] as List<ManagerEmployeeProfile>;
      final managers = results[1] as List<EmployeeManagerOption>;

      ManagerEmployeeProfile? selected;
      final nextDepartment =
          _department != null &&
              profiles.any((employee) => employee.department == _department)
          ? _department
          : null;
      final nextManagerId =
          _managerId != null &&
              managers.any((manager) => manager.id == _managerId)
          ? _managerId
          : null;
      if (preferredCode != null) {
        for (final employee in profiles) {
          if (employee.code == preferredCode) {
            selected = employee;
            break;
          }
        }
      }

      selected ??= profiles.isEmpty ? null : profiles.first;

      if (!mounted) {
        return;
      }

      setState(() {
        _profiles = profiles;
        _managerOptions = managers;
        _selected = selected;
        _department = nextDepartment;
        _managerId = nextManagerId;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = _message(error, 'تعذر تحميل بيانات الموظفين حالياً.');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<List<ManagerEmployeeProfile>> _loadSingle() async {
    final code = widget.initialProfile?.code;
    if (code == null) {
      return const [];
    }

    final profile = await AppServices.employeeProfileRepository
        .fetchEmployeeProfileByCode(code);
    return profile == null ? const [] : [profile];
  }

  Future<void> _mutate(Future<void> Function() action) async {
    setState(() {
      _isBusy = true;
    });

    try {
      await action();
    } catch (error) {
      if (mounted) {
        _showSnack(_message(error, 'تعذر تنفيذ العملية حالياً.'));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  Future<void> _create() async {
    final payload = await showEmployeeEditorDialog(
      context: context,
      role: widget.role,
      managerOptions: _managerOptions,
    );
    if (payload == null) {
      return;
    }

    await _mutate(() async {
      final created = await AppServices.employeeProfileRepository
          .createEmployee(payload);
      _status = 'active';
      await _load(preferredCode: created.code);
      _showSnack('تمت إضافة الموظف بنجاح.');
    });
  }

  Future<void> _edit() async {
    final employee = _current;
    if (employee == null || employee.isDeleted) {
      return;
    }

    final payload = await showEmployeeEditorDialog(
      context: context,
      role: widget.role,
      managerOptions: _managerOptions,
      initialProfile: employee,
    );
    if (payload == null) {
      return;
    }

    await _mutate(() async {
      final updated = await AppServices.employeeProfileRepository
          .updateEmployee(employeeCode: employee.code, payload: payload);
      await _load(preferredCode: updated.code);
      _showSnack('تم تحديث بيانات الموظف.');
    });
  }

  Future<void> _changePassword() async {
    if (!_canManagePasswords) {
      return;
    }

    final employee = _current;
    if (employee == null || employee.isDeleted) {
      return;
    }

    final password = await showEmployeePasswordDialog(
      context: context,
      employeeName: employee.name,
    );
    if (password == null) {
      return;
    }

    await _mutate(() async {
      await AppServices.employeeProfileRepository.updateEmployeePassword(
        employeeCode: employee.code,
        password: password,
      );
      _showSnack('تم تحديث كلمة مرور الموظف وسيُطلب منه تسجيل الدخول من جديد.');
    });
  }

  Future<void> _archive() async {
    final employee = _current;
    if (employee == null || employee.isDeleted) {
      return;
    }

    final confirmed = await _confirmAction(
      title: 'أرشفة الموظف',
      message:
          'سيتم نقل ${employee.name} إلى شاشة المحذوفين مع الاحتفاظ بسجلات الإجازات والحضور.',
      confirmLabel: 'أرشفة',
      isDestructive: true,
    );
    if (!confirmed) {
      return;
    }

    await _mutate(() async {
      await AppServices.employeeProfileRepository.deleteEmployee(employee.code);
      _status = 'deleted';
      await _load(preferredCode: employee.code);
      _showSnack('تمت أرشفة الموظف ويمكن استرجاعه لاحقاً.');
    });
  }

  Future<void> _restore() async {
    final employee = _current;
    if (employee == null || employee.isActive) {
      return;
    }

    final confirmed = await _confirmAction(
      title: 'استرجاع الموظف',
      message: 'سيعود ${employee.name} إلى قائمة الموظفين النشطين مباشرة.',
      confirmLabel: 'استرجاع',
    );
    if (!confirmed) {
      return;
    }

    await _mutate(() async {
      final restored = await AppServices.employeeProfileRepository
          .restoreEmployee(employee.code);
      _status = 'active';
      await _load(preferredCode: restored.code);
      _showSnack('تم استرجاع الموظف بنجاح.');
    });
  }

  Future<bool> _confirmAction({
    required String title,
    required String message,
    required String confirmLabel,
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: isDestructive
                  ? ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                    )
                  : null,
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );

    return result == true;
  }

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _query = '';
      _status = 'active';
      _department = null;
      _managerId = null;
    });
  }

  String _message(Object error, String fallback) {
    final text = error.toString().replaceFirst('Bad state: ', '').trim();
    return text.isEmpty ? fallback : text;
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  Widget build(BuildContext context) {
    final current = _current;

    return Scaffold(
      bottomNavigationBar: RoleBottomNavigationBar(
        role: widget.role,
        selectedIndex: 2,
        onDestinationSelected: _onPrimaryNavigation,
      ),
      appBar: AppBar(
        title: Text(
          _isAdmin
              ? 'إدارة الموظفين - الإدارة'
              : _isHr
              ? 'إدارة الموظفين - الموارد البشرية'
              : 'إدارة الموظفين - المدير',
        ),
        actions: [
          IconButton(
            onPressed: _isBusy
                ? null
                : () => _load(preferredCode: _current?.code),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: _isLoading
          ? const AppLoadingState()
          : _error != null
          ? AppErrorState(
              title: 'حدث خطأ',
              message: _error!,
              onRetry: () => _load(preferredCode: _current?.code),
            )
          : RefreshIndicator(
              onRefresh: () => _load(preferredCode: _current?.code),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _HeroPanel(
                    role: widget.role,
                    activeCount: _activeCount,
                    deletedCount: _deletedCount,
                    visibleCount: _filtered.length,
                    showDirectory: _showDirectory,
                  ),
                  const SizedBox(height: 16),
                  _buildActionBar(current),
                  if (_showDirectory) ...[
                    const SizedBox(height: 16),
                    _buildFiltersCard(),
                    const SizedBox(height: 16),
                    if (_filtered.isEmpty)
                      const AppEmptyState(
                        title: 'لا توجد نتائج',
                        message:
                            'جرّب تعديل البحث أو الفلاتر لعرض موظفين مطابقين.',
                        icon: Icons.filter_alt_off_outlined,
                      )
                    else
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final wide = constraints.maxWidth >= 980;
                          final listCard = _EmployeeListCard(
                            title: _directoryTitle,
                            subtitle: _directorySubtitle,
                            employees: _filtered,
                            selectedCode: current?.code,
                            onSelect: (employee) {
                              setState(() {
                                _selected = employee;
                              });
                            },
                          );
                          final details = current == null
                              ? const AppEmptyState(
                                  title: 'اختر موظفاً',
                                  message:
                                      'اختر موظفاً من القائمة لعرض ملفه وسجلاته.',
                                  icon: Icons.badge_outlined,
                                )
                              : _EmployeeDetailsColumn(employee: current);

                          if (!wide) {
                            return Column(
                              children: [
                                listCard,
                                const SizedBox(height: 16),
                                details,
                              ],
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 4, child: listCard),
                              const SizedBox(width: 16),
                              Expanded(flex: 6, child: details),
                            ],
                          );
                        },
                      ),
                  ] else ...[
                    const SizedBox(height: 16),
                    if (current == null)
                      const AppEmptyState(
                        title: 'لم يتم العثور على الموظف',
                        message:
                            'قد يكون الملف غير متاح أو لا تملك صلاحية الوصول إليه.',
                        icon: Icons.person_search_outlined,
                      )
                    else
                      _EmployeeDetailsColumn(employee: current),
                  ],
                ],
              ),
            ),
    );
  }

  String get _directoryTitle => switch (_status) {
    'deleted' => 'شاشة المحذوفين',
    'all' => 'كل الموظفين',
    _ => 'الموظفون النشطون',
  };

  String get _directorySubtitle => switch (_status) {
    'deleted' => 'يمكن استرجاع أي موظف مؤرشف مباشرة من هذه الشاشة.',
    'all' => 'قائمة موحدة تتأثر بالبحث والفلاتر الحالية.',
    _ => 'البحث والفلترة يعملان بالاسم أو الرقم الوظيفي والقسم.',
  };

  Widget _buildActionBar(ManagerEmployeeProfile? current) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ElevatedButton.icon(
              onPressed: _isBusy ? null : _create,
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: const Text('إضافة موظف'),
            ),
            OutlinedButton.icon(
              onPressed: _isBusy || current == null || current.isDeleted
                  ? null
                  : _edit,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('تعديل البيانات'),
            ),
            if (_canManagePasswords)
              OutlinedButton.icon(
                onPressed: _isBusy || current == null || current.isDeleted
                    ? null
                    : _changePassword,
                icon: const Icon(Icons.lock_reset_outlined),
                label: const Text('تغيير كلمة المرور'),
              ),
            OutlinedButton.icon(
              onPressed: _isBusy || current == null || current.isDeleted
                  ? null
                  : _archive,
              icon: const Icon(Icons.archive_outlined),
              label: const Text('أرشفة الموظف'),
            ),
            OutlinedButton.icon(
              onPressed: _isBusy || current == null || current.isActive
                  ? null
                  : _restore,
              icon: const Icon(Icons.restore_rounded),
              label: const Text('استرجاع الموظف'),
            ),
            if (_showDirectory)
              TextButton.icon(
                onPressed: _hasFilters ? _resetFilters : null,
                icon: const Icon(Icons.layers_clear_outlined),
                label: const Text('مسح الفلاتر'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _query = value;
                });
              },
              decoration: InputDecoration(
                labelText: 'بحث بالاسم أو الرقم الوظيفي',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _query = '';
                          });
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _StatusChip(
                  label: 'نشطون',
                  count: _activeCount,
                  selected: _status == 'active',
                  onTap: () {
                    setState(() {
                      _status = 'active';
                    });
                  },
                ),
                _StatusChip(
                  label: 'محذوفون',
                  count: _deletedCount,
                  selected: _status == 'deleted',
                  onTap: () {
                    setState(() {
                      _status = 'deleted';
                    });
                  },
                ),
                _StatusChip(
                  label: 'الكل',
                  count: _profiles.length,
                  selected: _status == 'all',
                  onTap: () {
                    setState(() {
                      _status = 'all';
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 240,
                  child: DropdownButtonFormField<String?>(
                    key: ValueKey<String>(
                      'department-filter:${_departments.join('|')}:${_departmentFilterValue ?? 'all'}',
                    ),
                    initialValue: _departmentFilterValue,
                    decoration: const InputDecoration(labelText: 'القسم'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('كل الأقسام'),
                      ),
                      ..._departments.map(
                        (department) => DropdownMenuItem<String?>(
                          value: department,
                          child: Text(department),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _department = value;
                      });
                    },
                  ),
                ),
                if (_canAssignManagers)
                  SizedBox(
                    width: 260,
                    child: DropdownButtonFormField<int?>(
                      key: ValueKey<String>(
                        'manager-filter:${_managerOptions.map((manager) => manager.id).join(',')}:${_managerFilterValue?.toString() ?? 'all'}',
                      ),
                      initialValue: _managerFilterValue,
                      decoration: const InputDecoration(
                        labelText: 'المدير المباشر',
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('كل المدراء'),
                        ),
                        ..._managerOptions.map(
                          (manager) => DropdownMenuItem<int?>(
                            value: manager.id,
                            child: Text(manager.displayLabel),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _managerId = value;
                        });
                      },
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _onPrimaryNavigation(int index) {
    if (widget.role == AppUserRole.manager) {
      if (index == 0) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.managerDashboard);
      }
      if (index == 1) {
        Navigator.of(
          context,
        ).pushReplacementNamed(AppRoutes.managerLeaveRequests);
      }
      if (index == 3) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.managerBroadcasts);
      }
      if (index == 4) {
        Navigator.of(
          context,
        ).pushReplacementNamed(AppRoutes.notifications, arguments: widget.role);
      }
      if (index == 5) {
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.profileAccount,
          arguments: widget.role,
        );
      }
    } else if (widget.role == AppUserRole.hr ||
        widget.role == AppUserRole.admin) {
      if (index == 0) {
        Navigator.of(context).pushReplacementNamed(
          widget.role == AppUserRole.admin
              ? AppRoutes.adminDashboard
              : AppRoutes.hrDashboard,
        );
      }
      if (index == 1) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.hrLeaveRequests);
      }
      if (index == 2) {
        return;
      }
      if (index == 3) {
        Navigator.of(
          context,
        ).pushReplacementNamed(AppRoutes.notifications, arguments: widget.role);
      }
      if (index == 4) {
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.profileAccount,
          arguments: widget.role,
        );
      }
    }
  }
}
