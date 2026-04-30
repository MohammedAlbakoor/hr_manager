import '../../../core/network/api_exception.dart';
import '../../../core/session/app_user_session.dart';
import '../../auth/data/mock_credentials_store.dart';
import '../../common/data/mock_notification_store.dart';
import '../../common/domain/models/app_user_role.dart';
import '../domain/models/employee_manager_option.dart';
import '../domain/models/employee_upsert_payload.dart';
import '../domain/models/manager_employee_profile.dart';
import '../domain/repositories/employee_profile_repository.dart';
import 'mock_manager_employee_profiles.dart';

class MockEmployeeProfileRepository implements EmployeeProfileRepository {
  MockEmployeeProfileRepository({required this.sessionController})
    : _profiles = mockManagerEmployeeProfiles
          .map((profile) => profile.copyWith())
          .toList();

  final AppSessionController sessionController;
  final List<ManagerEmployeeProfile> _profiles;

  AppUserRole get _currentRole =>
      sessionController.currentSession?.role ?? AppUserRole.manager;

  @override
  Future<List<ManagerEmployeeProfile>> fetchEmployeeProfiles() async {
    await Future<void>.delayed(const Duration(milliseconds: 360));
    return List<ManagerEmployeeProfile>.from(_visibleProfiles);
  }

  @override
  Future<ManagerEmployeeProfile?> fetchEmployeeProfileByCode(
    String code,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    for (final profile in _visibleProfiles) {
      if (profile.code == code) {
        return profile;
      }
    }

    return null;
  }

  @override
  Future<List<EmployeeManagerOption>> fetchManagerOptions() async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    return mockManagerOptions;
  }

  @override
  Future<ManagerEmployeeProfile> createEmployee(
    EmployeeUpsertPayload payload,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 280));

    final manager = _resolveManager(payload.managerId);
    final role = _currentRole == AppUserRole.admin
        ? (payload.role ?? AppUserRole.employee)
        : AppUserRole.employee;
    final profile = ManagerEmployeeProfile(
      id: payload.code,
      name: payload.name,
      code: payload.code,
      jobTitle: payload.jobTitle,
      department: payload.department,
      email: payload.email,
      phone: payload.phone,
      leaveBalanceLabel: '0.0 يوم',
      usedLeavesLabel: '0 أيام',
      monthlyIncrement: 1.5,
      pendingLeavesCount: 0,
      todayAttendanceLabel: 'لا يوجد',
      lastCheckInLabel: '--',
      workLocation: payload.workLocation,
      workSchedule: payload.workSchedule,
      joinDate: payload.joinDate,
      role: role,
      roleLabel: role.label,
      managerId: role != AppUserRole.employee
          ? null
          : _currentRole == AppUserRole.manager
          ? mockManagerOptions.first.id
          : manager?.id,
      managerName: role != AppUserRole.employee
          ? null
          : _currentRole == AppUserRole.manager
          ? mockManagerOptions.first.name
          : manager?.name,
      managerCode: role != AppUserRole.employee
          ? null
          : _currentRole == AppUserRole.manager
          ? mockManagerOptions.first.code
          : manager?.code,
      leaveItems: const [],
      attendanceItems: const [],
    );

    _profiles.add(profile);
    return profile;
  }

  @override
  Future<ManagerEmployeeProfile> updateEmployee({
    required String employeeCode,
    required EmployeeUpsertPayload payload,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 260));

    final index = _profiles.indexWhere(
      (profile) => profile.code == employeeCode,
    );
    if (index == -1) {
      throw const ApiException('لم يتم العثور على ملف الموظف المطلوب.');
    }

    final current = _profiles[index];
    final manager = _resolveManager(payload.managerId);
    final role = _currentRole == AppUserRole.admin
        ? (payload.role ?? current.role)
        : AppUserRole.employee;
    final updated = current.copyWith(
      name: payload.name,
      code: payload.code,
      jobTitle: payload.jobTitle,
      department: payload.department,
      email: payload.email,
      phone: payload.phone,
      workLocation: payload.workLocation,
      workSchedule: payload.workSchedule,
      joinDate: payload.joinDate,
      role: role,
      roleLabel: role.label,
      managerId: role != AppUserRole.employee
          ? null
          : _currentRole == AppUserRole.manager
          ? current.managerId
          : manager?.id,
      managerName: role != AppUserRole.employee
          ? null
          : _currentRole == AppUserRole.manager
          ? current.managerName
          : manager?.name,
      managerCode: role != AppUserRole.employee
          ? null
          : _currentRole == AppUserRole.manager
          ? current.managerCode
          : manager?.code,
      clearManager: role != AppUserRole.employee,
    );
    _profiles[index] = updated;
    return updated;
  }

  @override
  Future<void> updateEmployeePassword({
    required String employeeCode,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));

    if (_currentRole != AppUserRole.hr && _currentRole != AppUserRole.admin) {
      throw const ApiException('Only HR can update employee passwords.');
    }

    final index = _profiles.indexWhere(
      (profile) => profile.code == employeeCode,
    );
    if (index == -1) {
      throw const ApiException('لم يتم العثور على ملف الموظف المطلوب.');
    }

    MockCredentialsStore.setPasswordForEmail(_profiles[index].email, password);
  }

  @override
  Future<void> deleteEmployee(String employeeCode) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final index = _profiles.indexWhere(
      (profile) => profile.code == employeeCode,
    );
    if (index == -1) {
      throw const ApiException('لم يتم العثور على ملف الموظف المطلوب.');
    }
    _profiles[index] = _profiles[index].copyWith(
      deletedAt: DateTime.now().toIso8601String(),
    );
  }

  @override
  Future<ManagerEmployeeProfile> restoreEmployee(String employeeCode) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final index = _profiles.indexWhere(
      (profile) => profile.code == employeeCode,
    );
    if (index == -1) {
      throw const ApiException('لم يتم العثور على ملف الموظف المطلوب.');
    }
    final restored = _profiles[index].copyWith(clearDeletedAt: true);
    _profiles[index] = restored;
    return restored;
  }

  @override
  Future<void> broadcastManagerMessage({
    required String title,
    required String message,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    MockNotificationStore.broadcastFromManager(title: title, message: message);
  }

  @override
  Future<ManagerEmployeeProfile> updateEmployeeMonthlyIncrement({
    required String employeeCode,
    required double monthlyIncrement,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 260));

    final index = _profiles.indexWhere(
      (profile) => profile.code == employeeCode,
    );
    if (index == -1) {
      throw const ApiException('لم يتم العثور على ملف الموظف المطلوب.');
    }

    final updated = _profiles[index].copyWith(
      monthlyIncrement: monthlyIncrement,
    );
    _profiles[index] = updated;
    return updated;
  }

  @override
  Future<List<ManagerEmployeeProfile>> updateAllMonthlyIncrements(
    double monthlyIncrement,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 320));

    for (var i = 0; i < _profiles.length; i++) {
      _profiles[i] = _profiles[i].copyWith(monthlyIncrement: monthlyIncrement);
    }

    return List<ManagerEmployeeProfile>.from(_visibleProfiles);
  }

  List<ManagerEmployeeProfile> get _visibleProfiles {
    // Mock mode keeps all employees visible to simplify demos.
    return _profiles;
  }

  EmployeeManagerOption? _resolveManager(int? managerId) {
    if (managerId == null) {
      return null;
    }

    for (final manager in mockManagerOptions) {
      if (manager.id == managerId) {
        return manager;
      }
    }

    return null;
  }
}
