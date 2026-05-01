import '../models/employee_manager_option.dart';
import '../models/employee_upsert_payload.dart';
import '../models/manager_employee_profile.dart';

abstract class EmployeeProfileRepository {
  Future<List<ManagerEmployeeProfile>> fetchEmployeeProfiles();

  Future<ManagerEmployeeProfile?> fetchEmployeeProfileByCode(String code);

  Future<List<EmployeeManagerOption>> fetchManagerOptions();

  Future<ManagerEmployeeProfile> createEmployee(EmployeeUpsertPayload payload);

  Future<ManagerEmployeeProfile> updateEmployee({
    required String employeeCode,
    required EmployeeUpsertPayload payload,
  });

  Future<void> updateEmployeePassword({
    required String employeeCode,
    required String password,
  });

  Future<void> deleteEmployee(String employeeCode);

  Future<ManagerEmployeeProfile> restoreEmployee(String employeeCode);

  Future<void> broadcastManagerMessage({
    required String title,
    required String message,
  });

  Future<ManagerEmployeeProfile> updateEmployeeMonthlyIncrement({
    required String employeeCode,
    required double monthlyIncrement,
  });

  Future<List<ManagerEmployeeProfile>> updateAllMonthlyIncrements(
    double monthlyIncrement,
  );

  Future<ManagerEmployeeProfile> uploadEmployeeDocument({
    required String employeeCode,
    required EmployeeDocumentType type,
    required EmployeeDocumentSource source,
    required String title,
    required EmployeeProfileAttachmentFile file,
    bool runOcr = false,
  });

  Future<ManagerEmployeeProfile> saveEmployeeCv({
    required String employeeCode,
    required EmployeeCvProfile cvProfile,
  });

  Future<ManagerEmployeeProfile> uploadEmployeeCvPdf({
    required String employeeCode,
    required EmployeeProfileAttachmentFile file,
    bool suggestAutofill = true,
  });

  Future<ManagerEmployeeProfile> autofillEmployeeCvFromFile(
    String employeeCode,
  );

  Future<ManagerEmployeeProfile> regenerateEmployeeCvSummary(
    String employeeCode,
  );

  Future<ManagerEmployeeProfile> addAdministrativeRecord({
    required String employeeCode,
    required EmployeeAdministrativeRecordDraft record,
    EmployeeProfileAttachmentFile? attachment,
  });
}
