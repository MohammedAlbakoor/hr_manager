import '../domain/models/employee_manager_option.dart';
import '../domain/models/manager_employee_profile.dart';
import '../domain/models/manager_leave_request.dart';

const List<EmployeeManagerOption> mockManagerOptions = [
  EmployeeManagerOption(
    id: 1,
    name: 'محمد العتيبي',
    code: 'MGR-002',
    department: 'إدارة المبيعات',
    jobTitle: 'مدير مباشر',
  ),
];

final List<ManagerEmployeeProfile> mockManagerEmployeeProfiles = [
  ManagerEmployeeProfile(
    id: 'EMP-014',
    name: 'أحمد خالد',
    code: 'EMP-014',
    jobTitle: 'أخصائي مبيعات',
    department: 'المبيعات',
    email: 'ahmad.khaled@company.com',
    phone: '+966500000014',
    leaveBalanceLabel: '18.5 يوم',
    usedLeavesLabel: '6 أيام',
    monthlyIncrement: 1.5,
    pendingLeavesCount: 1,
    todayAttendanceLabel: 'حضور',
    lastCheckInLabel: '11 أبريل 2026 - 08:12 ص',
    workLocation: 'المكتب الرئيسي',
    workSchedule: '08:00 - 16:00',
    joinDate: '2024-01-12',
    birthDate: '1993-05-18',
    identityNumber: '01020304050',
    identityPlace: 'دمشق',
    nationality: 'سوري',
    shamCashAccount: 'SC-014-9988',
    address: 'دمشق - المزة',
    emergencyContact: '+963944000014',
    jobLevel: EmployeeJobLevel.officeMember,
    managerId: 1,
    managerName: 'محمد العتيبي',
    managerCode: 'MGR-002',
    leaveItems: const [
      ManagerEmployeeLeaveItem(
        title: 'إجازة سنوية',
        periodLabel: '20 مايو - 24 مايو 2026',
        daysCount: 5,
        status: ManagerLeaveWorkflowStatus.pendingReview,
      ),
      ManagerEmployeeLeaveItem(
        title: 'إجازة سنوية',
        periodLabel: '12 مارس - 14 مارس 2026',
        daysCount: 3,
        status: ManagerLeaveWorkflowStatus.fullyApproved,
      ),
    ],
    attendanceItems: const [
      ManagerEmployeeAttendanceItem(
        dateLabel: '11 أبريل 2026',
        checkInLabel: '08:12 ص',
        status: ManagerAttendanceStatus.present,
      ),
      ManagerEmployeeAttendanceItem(
        dateLabel: '10 أبريل 2026',
        checkInLabel: '08:27 ص',
        status: ManagerAttendanceStatus.late,
      ),
      ManagerEmployeeAttendanceItem(
        dateLabel: '09 أبريل 2026',
        checkInLabel: '08:03 ص',
        status: ManagerAttendanceStatus.present,
      ),
    ],
  ),
  ManagerEmployeeProfile(
    id: 'EMP-019',
    name: 'سارة ناصر',
    code: 'EMP-019',
    jobTitle: 'مهندسة دعم فني',
    department: 'الدعم الفني',
    email: 'sara.nasser@company.com',
    phone: '+966500000019',
    leaveBalanceLabel: '11 يوم',
    usedLeavesLabel: '4 أيام',
    monthlyIncrement: 1.5,
    pendingLeavesCount: 1,
    todayAttendanceLabel: 'حضور',
    lastCheckInLabel: '10 أبريل 2026 - 08:05 ص',
    workLocation: 'المكتب الرئيسي',
    workSchedule: '08:00 - 16:00',
    joinDate: '2024-02-06',
    birthDate: '1995-09-22',
    identityNumber: '01020304019',
    identityPlace: 'حلب',
    nationality: 'سوري',
    shamCashAccount: 'SC-019-4410',
    address: 'حلب - الفرقان',
    emergencyContact: '+963944000019',
    jobLevel: EmployeeJobLevel.officeManager,
    managerId: 1,
    managerName: 'محمد العتيبي',
    managerCode: 'MGR-002',
    leaveItems: const [
      ManagerEmployeeLeaveItem(
        title: 'إجازة مرضية',
        periodLabel: '14 أبريل - 15 أبريل 2026',
        daysCount: 2,
        status: ManagerLeaveWorkflowStatus.pendingReview,
      ),
      ManagerEmployeeLeaveItem(
        title: 'إجازة سنوية',
        periodLabel: '02 فبراير - 04 فبراير 2026',
        daysCount: 3,
        status: ManagerLeaveWorkflowStatus.fullyApproved,
      ),
    ],
    attendanceItems: const [
      ManagerEmployeeAttendanceItem(
        dateLabel: '11 أبريل 2026',
        checkInLabel: '08:01 ص',
        status: ManagerAttendanceStatus.present,
      ),
      ManagerEmployeeAttendanceItem(
        dateLabel: '10 أبريل 2026',
        checkInLabel: '08:05 ص',
        status: ManagerAttendanceStatus.present,
      ),
      ManagerEmployeeAttendanceItem(
        dateLabel: '09 أبريل 2026',
        checkInLabel: '08:16 ص',
        status: ManagerAttendanceStatus.late,
      ),
    ],
  ),
  ManagerEmployeeProfile(
    id: 'EMP-007',
    name: 'محمد سامي',
    code: 'EMP-007',
    jobTitle: 'منسق عمليات',
    department: 'العمليات',
    email: 'mohamed.sami@company.com',
    phone: '+966500000007',
    leaveBalanceLabel: '6 أيام',
    usedLeavesLabel: '8 أيام',
    monthlyIncrement: 2.0,
    pendingLeavesCount: 0,
    todayAttendanceLabel: 'حضور',
    lastCheckInLabel: '10 أبريل 2026 - 07:56 ص',
    workLocation: 'الفرع الشرقي',
    workSchedule: '08:00 - 16:00',
    joinDate: '2023-08-15',
    birthDate: '1990-12-02',
    identityNumber: '01020304007',
    identityPlace: 'حمص',
    nationality: 'سوري',
    shamCashAccount: 'SC-007-7721',
    address: 'حمص - الوعر',
    emergencyContact: '+963944000007',
    jobLevel: EmployeeJobLevel.seniorOfficeManager,
    managerId: 1,
    managerName: 'محمد العتيبي',
    managerCode: 'MGR-002',
    leaveItems: const [
      ManagerEmployeeLeaveItem(
        title: 'إجازة بدون راتب',
        periodLabel: '02 يونيو - 06 يونيو 2026',
        daysCount: 5,
        status: ManagerLeaveWorkflowStatus.managerApproved,
      ),
      ManagerEmployeeLeaveItem(
        title: 'إجازة سنوية',
        periodLabel: '18 يناير - 20 يناير 2026',
        daysCount: 3,
        status: ManagerLeaveWorkflowStatus.fullyApproved,
      ),
    ],
    attendanceItems: const [
      ManagerEmployeeAttendanceItem(
        dateLabel: '11 أبريل 2026',
        checkInLabel: '07:58 ص',
        status: ManagerAttendanceStatus.present,
      ),
      ManagerEmployeeAttendanceItem(
        dateLabel: '10 أبريل 2026',
        checkInLabel: '07:56 ص',
        status: ManagerAttendanceStatus.present,
      ),
      ManagerEmployeeAttendanceItem(
        dateLabel: '09 أبريل 2026',
        checkInLabel: '--',
        status: ManagerAttendanceStatus.absent,
      ),
    ],
  ),
];

ManagerEmployeeProfile get firstManagerEmployeeProfile =>
    mockManagerEmployeeProfiles.first;

ManagerEmployeeProfile profileByCode(String code) {
  return mockManagerEmployeeProfiles.firstWhere(
    (profile) => profile.code == code,
    orElse: () => firstManagerEmployeeProfile,
  );
}
