import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/services/app_services.dart';
import '../../../common/domain/models/app_user_role.dart';
import '../../../common/presentation/widgets/app_error_state.dart';
import '../../../common/presentation/widgets/app_loading_state.dart';
import '../../../common/presentation/widgets/role_bottom_navigation_bar.dart';
import '../../../manager/domain/models/employee_manager_option.dart';
import '../../../manager/domain/models/manager_employee_profile.dart';
import '../../domain/models/report_export_filter.dart';
import '../../domain/models/report_table_models.dart';
import '../models/report_workspace_state.dart';
import '../widgets/report_column_manager_sheet.dart';
import '../widgets/report_workspace_view.dart';
import '../widgets/reports_hero.dart';

class HrReportsScreen extends StatefulWidget {
  const HrReportsScreen({super.key});

  @override
  State<HrReportsScreen> createState() => _HrReportsScreenState();
}

class _HrReportsScreenState extends State<HrReportsScreen> {
  final TextEditingController _attendanceSearchController =
      TextEditingController();
  final TextEditingController _leaveSearchController = TextEditingController();

  List<String> _departments = const [];
  List<EmployeeManagerOption> _managers = const [];
  bool _isBootstrapping = true;
  String? _bootstrapErrorMessage;
  ReportWorkspaceState _attendanceWorkspace = ReportWorkspaceState.initial(
    ReportTableType.attendance,
  );
  ReportWorkspaceState _leaveWorkspace = ReportWorkspaceState.initial(
    ReportTableType.leaves,
  );

  AppUserRole get _role =>
      AppServices.session.currentSession?.role == AppUserRole.admin
      ? AppUserRole.admin
      : AppUserRole.hr;

  static const _attendanceStatuses = [
    ReportFilterOption('all', 'كل الحالات'),
    ReportFilterOption('present', 'حاضر'),
    ReportFilterOption('late', 'متأخر'),
    ReportFilterOption('absent', 'غائب'),
  ];

  static const _leaveStatuses = [
    ReportFilterOption('all', 'كل الطلبات'),
    ReportFilterOption('pending', 'بانتظار المدير'),
    ReportFilterOption('manager_approved', 'بانتظار HR'),
    ReportFilterOption('approved', 'معتمد'),
    ReportFilterOption('rejected', 'مرفوض'),
  ];

  @override
  void initState() {
    super.initState();
    unawaited(_loadBootstrap());
  }

  @override
  void dispose() {
    _attendanceSearchController.dispose();
    _leaveSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadBootstrap() async {
    setState(() {
      _isBootstrapping = true;
      _bootstrapErrorMessage = null;
    });

    try {
      final results = await Future.wait([
        AppServices.employeeProfileRepository.fetchEmployeeProfiles(),
        AppServices.employeeProfileRepository.fetchManagerOptions(),
      ]);

      if (!mounted) {
        return;
      }

      final profiles = results[0] as List<ManagerEmployeeProfile>;
      final managers = results[1] as List<EmployeeManagerOption>;
      final departments =
          profiles
              .map((profile) => profile.department.trim())
              .where(
                (department) => department.isNotEmpty && department != '--',
              )
              .toSet()
              .toList()
            ..sort();

      setState(() {
        _departments = departments;
        _managers = managers;
        _attendanceWorkspace = _sanitizeWorkspace(_attendanceWorkspace);
        _leaveWorkspace = _sanitizeWorkspace(_leaveWorkspace);
        _isBootstrapping = false;
      });

      await Future.wait([
        _reloadWorkspace(ReportTableType.attendance),
        _reloadWorkspace(ReportTableType.leaves),
      ]);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isBootstrapping = false;
        _bootstrapErrorMessage = 'تعذر تجهيز شاشة التقارير حاليًا.';
      });
    }
  }

  ReportWorkspaceState _sanitizeWorkspace(ReportWorkspaceState workspace) {
    final hasDepartment =
        workspace.filter.department != null &&
        _departments.contains(workspace.filter.department);
    final hasManager =
        workspace.filter.managerId != null &&
        _managers.any((manager) => manager.id == workspace.filter.managerId);

    return workspace.copyWith(
      filter: workspace.filter.copyWith(
        clearDepartment: !hasDepartment,
        clearManager: !hasManager,
      ),
      appliedFilter: workspace.appliedFilter.copyWith(
        clearDepartment: !hasDepartment,
        clearManager: !hasManager,
      ),
    );
  }

  ReportWorkspaceState _workspaceFor(ReportTableType type) {
    return type == ReportTableType.attendance
        ? _attendanceWorkspace
        : _leaveWorkspace;
  }

  void _setWorkspace(ReportTableType type, ReportWorkspaceState workspace) {
    setState(() {
      if (type == ReportTableType.attendance) {
        _attendanceWorkspace = workspace;
      } else {
        _leaveWorkspace = workspace;
      }
    });
  }

  Future<void> _reloadWorkspace(ReportTableType type) async {
    final workspace = _workspaceFor(type);
    _setWorkspace(type, workspace.copyWith(isLoading: true, clearError: true));

    try {
      final rows = type == ReportTableType.attendance
          ? await AppServices.reportRepository.fetchAttendanceReportRows(
              workspace.filter,
            )
          : await AppServices.reportRepository.fetchLeaveReportRows(
              workspace.filter,
            );

      if (!mounted) {
        return;
      }

      _setWorkspace(
        type,
        _workspaceFor(type).copyWith(
          rows: rows,
          appliedFilter: _workspaceFor(type).filter,
          isLoading: false,
          clearError: true,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      _setWorkspace(
        type,
        _workspaceFor(type).copyWith(
          isLoading: false,
          errorMessage: _normalizeRemoteError(error),
        ),
      );
    }
  }

  Future<void> _pickDate({
    required ReportTableType type,
    required bool isStart,
  }) async {
    final workspace = _workspaceFor(type);
    final filter = workspace.filter;
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('ar'),
      initialDate: isStart ? filter.dateFrom : filter.dateTo,
      firstDate: DateTime(2024),
      lastDate: DateTime(DateTime.now().year + 2, 12, 31),
      helpText: isStart ? 'اختر تاريخ البداية' : 'اختر تاريخ النهاية',
    );

    if (picked == null || !mounted) {
      return;
    }

    final normalized = DateTime(picked.year, picked.month, picked.day);
    final updatedFilter = isStart
        ? filter.copyWith(
            dateFrom: normalized,
            dateTo: filter.dateTo.isBefore(normalized)
                ? normalized
                : filter.dateTo,
          )
        : filter.copyWith(
            dateTo: normalized,
            dateFrom: filter.dateFrom.isAfter(normalized)
                ? normalized
                : filter.dateFrom,
          );

    _setWorkspace(type, workspace.copyWith(filter: updatedFilter));
  }

  Future<void> _openColumnManager(ReportTableType type) async {
    final workspace = _workspaceFor(type);
    final updatedColumns = await showModalBottomSheet<List<ReportTableColumn>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => ReportColumnManagerSheet(
        title: workspace.type.title,
        initialColumns: workspace.columns,
        defaultColumns: ReportTableDefaults.columnsFor(type),
      ),
    );

    if (!mounted || updatedColumns == null) {
      return;
    }

    final currentSortColumnId = workspace.sortColumnId;
    final sortColumnStillVisible =
        currentSortColumnId != null &&
        updatedColumns.any(
          (column) => column.id == currentSortColumnId && column.isVisible,
        );

    _setWorkspace(
      type,
      workspace.copyWith(
        columns: updatedColumns,
        clearSortColumn: !sortColumnStillVisible,
      ),
    );
  }

  void _resetColumnLayout(ReportTableType type) {
    final workspace = _workspaceFor(type);
    _setWorkspace(
      type,
      workspace.copyWith(
        columns: ReportTableDefaults.columnsFor(type),
        clearSortColumn: true,
      ),
    );
  }

  Future<void> _exportWorkspace(ReportTableType type) async {
    final workspace = _workspaceFor(type);
    if (workspace.hasPendingFilterChanges) {
      _showSnackBar(
        'طبّق الفلاتر أولًا قبل التصدير حتى يطابق الملف شكل الجدول.',
      );
      return;
    }

    final visibleColumns = workspace.visibleColumns;
    final displayedRows = _displayedRows(workspace);
    if (visibleColumns.isEmpty) {
      _showSnackBar('اختر عمودًا واحدًا على الأقل قبل التصدير.');
      return;
    }
    if (displayedRows.isEmpty) {
      _showSnackBar('لا توجد صفوف حالية يمكن تصديرها.');
      return;
    }

    _setWorkspace(type, workspace.copyWith(isExporting: true));
    try {
      final file = AppServices.reportTableExportBuilder.buildCsv(
        type: type,
        filter: workspace.appliedFilter,
        columns: visibleColumns,
        rows: displayedRows,
      );
      await AppServices.reportFileSaver.save(file);
      if (!mounted) {
        return;
      }
      _showSnackBar('تم تنزيل ${type.title} حسب الشكل الحالي للجدول.');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showSnackBar(error.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) {
        _setWorkspace(type, _workspaceFor(type).copyWith(isExporting: false));
      }
    }
  }

  List<ReportTableRow> _displayedRows(ReportWorkspaceState workspace) {
    final filteredRows = workspace.rows
        .where((row) => row.matchesQuery(workspace.searchQuery))
        .toList();
    final sortColumnId = workspace.sortColumnId;
    if (sortColumnId == null) {
      return filteredRows;
    }

    filteredRows.sort((left, right) {
      final comparison = _compareSortValues(
        left.sortValueFor(sortColumnId),
        right.sortValueFor(sortColumnId),
      );
      return workspace.sortAscending ? comparison : -comparison;
    });

    return filteredRows;
  }

  int _compareSortValues(Object left, Object right) {
    if (left is DateTime && right is DateTime) {
      return left.compareTo(right);
    }
    if (left is num && right is num) {
      return left.compareTo(right);
    }
    return left.toString().toLowerCase().compareTo(
      right.toString().toLowerCase(),
    );
  }

  String _normalizeRemoteError(Object error) {
    final message = error.toString().replaceFirst('Bad state: ', '').trim();
    if (message == 'No employees matched the selected filters.') {
      return 'لا يوجد موظفون مطابقون للفلاتر الحالية.';
    }
    return message;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  void _handlePrimaryNavigation(int index) {
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed(
          _role == AppUserRole.admin
              ? AppRoutes.adminDashboard
              : AppRoutes.hrDashboard,
        );
        return;
      case 1:
        Navigator.of(context).pushReplacementNamed(AppRoutes.hrLeaveRequests);
        return;
      case 2:
        Navigator.of(context).pushReplacementNamed(AppRoutes.hrEmployeeDetails);
        return;
      case 3:
        Navigator.of(
          context,
        ).pushReplacementNamed(AppRoutes.notifications, arguments: _role);
        return;
      case 4:
        Navigator.of(
          context,
        ).pushReplacementNamed(AppRoutes.profileAccount, arguments: _role);
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isBootstrapping) {
      return const Scaffold(
        body: SafeArea(
          child: AppLoadingState(
            title: 'جارٍ تجهيز التقارير',
            message:
                'نجهز الفلاتر والجداول وخيارات العرض الخاصة بالموارد البشرية.',
          ),
        ),
      );
    }

    if (_bootstrapErrorMessage != null) {
      return Scaffold(
        body: SafeArea(
          child: AppErrorState(
            title: 'تعذر تحميل الشاشة',
            message: _bootstrapErrorMessage!,
            onRetry: _loadBootstrap,
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        bottomNavigationBar: RoleBottomNavigationBar(
          role: _role,
          selectedIndex: 0,
          onDestinationSelected: _handlePrimaryNavigation,
        ),
        appBar: AppBar(title: const Text('التقارير'), centerTitle: true),
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
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: ReportsHero(),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const TabBar(
                    tabs: [
                      Tab(text: 'الحضور'),
                      Tab(text: 'الإجازات'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: TabBarView(
                    children: [_buildAttendanceTab(), _buildLeavesTab()],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceTab() {
    return ReportWorkspaceView(
      workspace: _attendanceWorkspace,
      displayedRows: _displayedRows(_attendanceWorkspace),
      departments: _departments,
      managers: _managers,
      statusItems: _attendanceStatuses,
      searchController: _attendanceSearchController,
      onDatePressed: (isStart) =>
          _pickDate(type: ReportTableType.attendance, isStart: isStart),
      onDepartmentChanged: (value) => _setWorkspace(
        ReportTableType.attendance,
        _attendanceWorkspace.copyWith(
          filter: _attendanceWorkspace.filter.copyWith(
            department: value,
            clearDepartment: value == null,
          ),
        ),
      ),
      onManagerChanged: (value) => _setWorkspace(
        ReportTableType.attendance,
        _attendanceWorkspace.copyWith(
          filter: _attendanceWorkspace.filter.copyWith(
            managerId: value,
            clearManager: value == null,
          ),
        ),
      ),
      onStatusChanged: (value) => _setWorkspace(
        ReportTableType.attendance,
        _attendanceWorkspace.copyWith(
          filter: _attendanceWorkspace.filter.copyWith(status: value),
        ),
      ),
      onApplyFilters: () => _reloadWorkspace(ReportTableType.attendance),
      onResetFilters: () {
        _attendanceSearchController.clear();
        _setWorkspace(
          ReportTableType.attendance,
          _attendanceWorkspace.copyWith(
            filter: ReportExportFilter.currentMonth(),
            searchQuery: '',
          ),
        );
        return _reloadWorkspace(ReportTableType.attendance);
      },
      onSearchChanged: (value) => _setWorkspace(
        ReportTableType.attendance,
        _attendanceWorkspace.copyWith(searchQuery: value),
      ),
      onSort: (columnId, ascending) => _setWorkspace(
        ReportTableType.attendance,
        _attendanceWorkspace.copyWith(
          sortColumnId: columnId,
          sortAscending: ascending,
        ),
      ),
      onManageColumns: () => _openColumnManager(ReportTableType.attendance),
      onResetLayout: () => _resetColumnLayout(ReportTableType.attendance),
      onExport: () => _exportWorkspace(ReportTableType.attendance),
      onRetry: () => _reloadWorkspace(ReportTableType.attendance),
    );
  }

  Widget _buildLeavesTab() {
    return ReportWorkspaceView(
      workspace: _leaveWorkspace,
      displayedRows: _displayedRows(_leaveWorkspace),
      departments: _departments,
      managers: _managers,
      statusItems: _leaveStatuses,
      searchController: _leaveSearchController,
      onDatePressed: (isStart) =>
          _pickDate(type: ReportTableType.leaves, isStart: isStart),
      onDepartmentChanged: (value) => _setWorkspace(
        ReportTableType.leaves,
        _leaveWorkspace.copyWith(
          filter: _leaveWorkspace.filter.copyWith(
            department: value,
            clearDepartment: value == null,
          ),
        ),
      ),
      onManagerChanged: (value) => _setWorkspace(
        ReportTableType.leaves,
        _leaveWorkspace.copyWith(
          filter: _leaveWorkspace.filter.copyWith(
            managerId: value,
            clearManager: value == null,
          ),
        ),
      ),
      onStatusChanged: (value) => _setWorkspace(
        ReportTableType.leaves,
        _leaveWorkspace.copyWith(
          filter: _leaveWorkspace.filter.copyWith(status: value),
        ),
      ),
      onApplyFilters: () => _reloadWorkspace(ReportTableType.leaves),
      onResetFilters: () {
        _leaveSearchController.clear();
        _setWorkspace(
          ReportTableType.leaves,
          _leaveWorkspace.copyWith(
            filter: ReportExportFilter.currentMonth(),
            searchQuery: '',
          ),
        );
        return _reloadWorkspace(ReportTableType.leaves);
      },
      onSearchChanged: (value) => _setWorkspace(
        ReportTableType.leaves,
        _leaveWorkspace.copyWith(searchQuery: value),
      ),
      onSort: (columnId, ascending) => _setWorkspace(
        ReportTableType.leaves,
        _leaveWorkspace.copyWith(
          sortColumnId: columnId,
          sortAscending: ascending,
        ),
      ),
      onManageColumns: () => _openColumnManager(ReportTableType.leaves),
      onResetLayout: () => _resetColumnLayout(ReportTableType.leaves),
      onExport: () => _exportWorkspace(ReportTableType.leaves),
      onRetry: () => _reloadWorkspace(ReportTableType.leaves),
    );
  }
}
