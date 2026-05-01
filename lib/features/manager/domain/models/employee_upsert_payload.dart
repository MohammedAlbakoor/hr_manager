import '../../../common/domain/models/app_user_role.dart';
import 'manager_employee_profile.dart';

class EmployeeUpsertPayload {
  const EmployeeUpsertPayload({
    required this.name,
    required this.code,
    required this.email,
    required this.phone,
    required this.department,
    required this.jobTitle,
    required this.workLocation,
    required this.workSchedule,
    required this.joinDate,
    this.birthDate = '',
    this.identityNumber = '',
    this.identityIssueDate = '',
    this.identityExpiryDate = '',
    this.identityPlace = '',
    this.nationality = '',
    this.shamCashAccount = '',
    this.address = '',
    this.emergencyContact = '',
    this.jobLevel = EmployeeJobLevel.member,
    this.password,
    this.managerId,
    this.role,
  });

  final String name;
  final String code;
  final String email;
  final String phone;
  final String department;
  final String jobTitle;
  final String workLocation;
  final String workSchedule;
  final String joinDate;
  final String birthDate;
  final String identityNumber;
  final String identityIssueDate;
  final String identityExpiryDate;
  final String identityPlace;
  final String nationality;
  final String shamCashAccount;
  final String address;
  final String emergencyContact;
  final EmployeeJobLevel jobLevel;
  final String? password;
  final int? managerId;
  final AppUserRole? role;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'name': name,
      'code': code,
      'email': email,
      'phone': phone,
      'department': department,
      'job_title': jobTitle,
      'work_location': workLocation,
      'work_schedule': workSchedule,
      'joined_at': joinDate.isEmpty ? null : joinDate,
      'birth_date': birthDate.isEmpty ? null : birthDate,
      'identity_number': identityNumber.isEmpty ? null : identityNumber,
      'identity_issue_date': identityIssueDate.isEmpty
          ? null
          : identityIssueDate,
      'identity_expiry_date': identityExpiryDate.isEmpty
          ? null
          : identityExpiryDate,
      'identity_place': identityPlace.isEmpty ? null : identityPlace,
      'nationality': nationality.isEmpty ? null : nationality,
      'sham_cash_account': shamCashAccount.isEmpty ? null : shamCashAccount,
      'address': address.isEmpty ? null : address,
      'emergency_contact': emergencyContact.isEmpty ? null : emergencyContact,
      'job_level': jobLevel.apiValue,
      'manager_id': managerId,
      'role': role?.name,
    };

    final trimmedPassword = password?.trim();
    if (trimmedPassword != null && trimmedPassword.isNotEmpty) {
      json['password'] = trimmedPassword;
    }

    return json;
  }
}
