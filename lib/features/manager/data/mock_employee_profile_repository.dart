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
      birthDate: payload.birthDate,
      identityNumber: payload.identityNumber,
      identityIssueDate: payload.identityIssueDate,
      identityExpiryDate: payload.identityExpiryDate,
      identityPlace: payload.identityPlace,
      nationality: payload.nationality,
      shamCashAccount: payload.shamCashAccount,
      address: payload.address,
      emergencyContact: payload.emergencyContact,
      jobLevel: payload.jobLevel,
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
      birthDate: payload.birthDate,
      identityNumber: payload.identityNumber,
      identityIssueDate: payload.identityIssueDate,
      identityExpiryDate: payload.identityExpiryDate,
      identityPlace: payload.identityPlace,
      nationality: payload.nationality,
      shamCashAccount: payload.shamCashAccount,
      address: payload.address,
      emergencyContact: payload.emergencyContact,
      jobLevel: payload.jobLevel,
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

  @override
  Future<ManagerEmployeeProfile> uploadEmployeeDocument({
    required String employeeCode,
    required EmployeeDocumentType type,
    required EmployeeDocumentSource source,
    required String title,
    required EmployeeProfileAttachmentFile file,
    bool runOcr = false,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 320));
    final profile = _profileOrThrow(employeeCode);
    final document = EmployeeProfileDocument(
      id: 'doc-${DateTime.now().microsecondsSinceEpoch}',
      type: type,
      title: title.trim().isEmpty ? type.label : title.trim(),
      fileName: file.name,
      uploadedAt: DateTime.now().toIso8601String(),
      source: source,
      mimeType: file.mimeType,
      sizeBytes: file.sizeBytes ?? file.bytes?.length,
      ocrText: runOcr ? _mockOcrText(profile) : null,
      ocrSuggestions: runOcr && type == EmployeeDocumentType.identityImage
          ? _mockIdentitySuggestions(profile)
          : const {},
    );
    return _replaceProfile(
      profile.copyWith(documents: [document, ...profile.documents]),
    );
  }

  @override
  Future<ManagerEmployeeProfile> saveEmployeeCv({
    required String employeeCode,
    required EmployeeCvProfile cvProfile,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 240));
    final profile = _profileOrThrow(employeeCode);
    return _replaceProfile(
      profile.copyWith(
        cvProfile: cvProfile.copyWith(
          updatedAt: DateTime.now().toIso8601String(),
        ),
      ),
    );
  }

  @override
  Future<ManagerEmployeeProfile> uploadEmployeeCvPdf({
    required String employeeCode,
    required EmployeeProfileAttachmentFile file,
    bool suggestAutofill = true,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 360));
    final profile = _profileOrThrow(employeeCode);
    final document = EmployeeProfileDocument(
      id: 'cv-${DateTime.now().microsecondsSinceEpoch}',
      type: EmployeeDocumentType.cvPdf,
      title: 'السيرة الذاتية PDF',
      fileName: file.name,
      uploadedAt: DateTime.now().toIso8601String(),
      source: EmployeeDocumentSource.scanner,
      mimeType: file.mimeType ?? 'application/pdf',
      sizeBytes: file.sizeBytes ?? file.bytes?.length,
      ocrText: _mockCvText(profile),
    );
    final cv = profile.cvProfile.copyWith(
      pdfDocument: document,
      extractedText: _mockCvText(profile),
      updatedAt: DateTime.now().toIso8601String(),
    );
    final next = profile.copyWith(
      documents: [document, ...profile.documents],
      cvProfile: suggestAutofill ? _cvWithSuggestions(profile, cv) : cv,
    );
    return _replaceProfile(next);
  }

  @override
  Future<ManagerEmployeeProfile> autofillEmployeeCvFromFile(
    String employeeCode,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 260));
    final profile = _profileOrThrow(employeeCode);
    return _replaceProfile(
      profile.copyWith(
        cvProfile: _cvWithSuggestions(profile, profile.cvProfile),
      ),
    );
  }

  @override
  Future<ManagerEmployeeProfile> regenerateEmployeeCvSummary(
    String employeeCode,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 280));
    final profile = _profileOrThrow(employeeCode);
    final summary =
        '${profile.name} يعمل ضمن ${profile.department} بمسمى ${profile.jobTitle}، '
        'ويمتلك خبرة عملية قابلة للتطوير في مهام ${profile.jobLevel.label}.';
    return _replaceProfile(
      profile.copyWith(
        cvProfile: profile.cvProfile.copyWith(
          professionalSummary: summary,
          generatedSummary: summary,
          updatedAt: DateTime.now().toIso8601String(),
        ),
      ),
    );
  }

  @override
  Future<ManagerEmployeeProfile> addAdministrativeRecord({
    required String employeeCode,
    required EmployeeAdministrativeRecordDraft record,
    EmployeeProfileAttachmentFile? attachment,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final profile = _profileOrThrow(employeeCode);
    final document = attachment == null
        ? null
        : EmployeeProfileDocument(
            id: 'adm-doc-${DateTime.now().microsecondsSinceEpoch}',
            type: EmployeeDocumentType.administrativeRecord,
            title: record.title,
            fileName: attachment.name,
            uploadedAt: DateTime.now().toIso8601String(),
            source: EmployeeDocumentSource.upload,
            mimeType: attachment.mimeType,
            sizeBytes: attachment.sizeBytes ?? attachment.bytes?.length,
          );
    final administrativeRecord = EmployeeAdministrativeRecord(
      id: 'adm-${DateTime.now().microsecondsSinceEpoch}',
      category: record.category,
      title: record.title,
      recordDate: record.recordDate,
      referenceNumber: record.referenceNumber,
      description: record.description,
      document: document,
      createdAt: DateTime.now().toIso8601String(),
    );
    return _replaceProfile(
      profile.copyWith(
        documents: document == null
            ? profile.documents
            : [document, ...profile.documents],
        administrativeRecords: [
          administrativeRecord,
          ...profile.administrativeRecords,
        ],
      ),
    );
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

  ManagerEmployeeProfile _profileOrThrow(String employeeCode) {
    for (final profile in _profiles) {
      if (profile.code == employeeCode) {
        return profile;
      }
    }
    throw const ApiException('لم يتم العثور على ملف الموظف المطلوب.');
  }

  ManagerEmployeeProfile _replaceProfile(ManagerEmployeeProfile updated) {
    final index = _profiles.indexWhere((item) => item.code == updated.code);
    if (index == -1) {
      throw const ApiException('لم يتم العثور على ملف الموظف المطلوب.');
    }
    _profiles[index] = updated;
    return updated;
  }

  String _mockOcrText(ManagerEmployeeProfile profile) {
    return [
      'الاسم: ${profile.name}',
      'رقم الهوية: ${profile.identityNumber.isEmpty ? '12345678901' : profile.identityNumber}',
      'تاريخ الميلاد: ${profile.birthDate.isEmpty ? '1994-01-01' : profile.birthDate}',
      'مكان القيد: ${profile.identityPlace.isEmpty ? 'دمشق' : profile.identityPlace}',
    ].join('\n');
  }

  Map<String, String> _mockIdentitySuggestions(ManagerEmployeeProfile profile) {
    return {
      'name': profile.name,
      'identity_number': profile.identityNumber.isEmpty
          ? '12345678901'
          : profile.identityNumber,
      'birth_date': profile.birthDate.isEmpty
          ? '1994-01-01'
          : profile.birthDate,
      'identity_place': profile.identityPlace.isEmpty
          ? 'دمشق'
          : profile.identityPlace,
      'nationality': profile.nationality.isEmpty ? 'سوري' : profile.nationality,
    };
  }

  String _mockCvText(ManagerEmployeeProfile profile) {
    return [
      profile.name,
      profile.jobTitle,
      'مهارات: تواصل، إدارة وقت، متابعة إدارية، أرشفة وثائق',
      'خبرة: ${profile.department} - ${profile.workLocation}',
      'تعليم: بكالوريوس أو شهادة مهنية مناسبة',
      'دورات: إدارة الموارد البشرية، السلامة المهنية',
    ].join('\n');
  }

  EmployeeCvProfile _cvWithSuggestions(
    ManagerEmployeeProfile profile,
    EmployeeCvProfile current,
  ) {
    final summary = current.professionalSummary.trim().isNotEmpty
        ? current.professionalSummary
        : '${profile.name} موظف ضمن ${profile.department} بخبرة في ${profile.jobTitle} ومتابعة الأعمال اليومية باحترافية.';
    return current.copyWith(
      professionalSummary: summary,
      generatedSummary: summary,
      skills: current.skills.isNotEmpty
          ? current.skills
          : const ['التواصل', 'إدارة الوقت', 'الأرشفة', 'متابعة المعاملات'],
      experience: current.experience.isNotEmpty
          ? current.experience
          : [
              EmployeeCvItem(
                title: profile.jobTitle,
                organization: profile.department,
                period: profile.joinDate.isEmpty
                    ? 'حالي'
                    : '${profile.joinDate} - حالي',
                description:
                    'متابعة المهام التشغيلية والإدارية ضمن نطاق العمل.',
              ),
            ],
      education: current.education.isNotEmpty
          ? current.education
          : const [
              EmployeeCvItem(
                title: 'شهادة علمية',
                organization: 'جهة تعليمية',
                period: '',
                description: 'بيانات قابلة للتعديل بعد مراجعة الملف.',
              ),
            ],
      courses: current.courses.isNotEmpty
          ? current.courses
          : const [
              EmployeeCvItem(title: 'إدارة الموارد البشرية'),
              EmployeeCvItem(title: 'السلامة المهنية'),
            ],
      updatedAt: DateTime.now().toIso8601String(),
    );
  }
}
