import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hr_manager/app/app.dart';
import 'package:hr_manager/core/services/app_services.dart';
import 'package:hr_manager/features/attendance/domain/models/attendance_scan_payload.dart';
import 'package:hr_manager/features/auth/domain/models/login_request.dart';
import 'package:hr_manager/features/common/domain/models/app_notification_item.dart';
import 'package:hr_manager/features/common/domain/models/app_user_role.dart';
import 'package:hr_manager/features/employee/presentation/pages/employee_dashboard_screen.dart';
import 'package:hr_manager/features/hr/domain/models/hr_leave_request.dart';
import 'package:hr_manager/features/leave/domain/models/create_leave_request_payload.dart';
import 'package:hr_manager/features/manager/domain/models/manager_leave_request.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Flutter app completes a live login, leave approval, attendance, and notifications flow',
    (tester) async {
      Future<void> signInAs({
        required AppUserRole role,
        required String email,
      }) async {
        final session = await AppServices.authRepository.signIn(
          LoginRequest(
            email: email,
            password: 'password',
            // role: role,
            rememberMe: false,
          ),
        );
        AppServices.session.setSession(session);
      }

      AppServices.session.clear();

      await tester.pumpWidget(const HrManagerApp());
      await tester.pump(const Duration(milliseconds: 2300));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);
      expect(textFields, findsNWidgets(2));

      await tester.enterText(textFields.at(0), 'ahmad.khaled@company.com');
      await tester.enterText(textFields.at(1), 'password');
      await tester.tap(find.byType(ElevatedButton).first);
      await tester.pump();

      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(seconds: 1));
      });
      await tester.pumpAndSettle();

      expect(find.byType(EmployeeDashboardScreen), findsOneWidget);

      await tester.runAsync(() async {
        await signInAs(
          role: AppUserRole.employee,
          email: 'ahmad.khaled@company.com',
        );

        final createdLeave = await AppServices.leaveRepository
            .createLeaveRequest(
              CreateLeaveRequestPayload(
                leaveType: 'sick',
                startDate: DateTime(2026, 4, 24),
                endDate: DateTime(2026, 4, 25),
                note: 'فحص end-to-end من Flutter',
              ),
            );

        final employeeLeaves = await AppServices.leaveRepository
            .fetchEmployeeLeaveHistory();
        expect(
          employeeLeaves.any((item) => item.id == createdLeave.id),
          isTrue,
        );

        await signInAs(
          role: AppUserRole.manager,
          email: 'm.alotaibi@company.com',
        );

        final managerNotifications = await AppServices.commonRepository
            .fetchNotifications(AppUserRole.manager);
        expect(
          managerNotifications.any(
            (item) => item.category == AppNotificationCategory.leave,
          ),
          isTrue,
        );

        final managerRequest =
            (await AppServices.leaveRepository.fetchManagerLeaveRequests())
                .firstWhere((item) => item.id == createdLeave.id);

        final managerDecision = await AppServices.leaveRepository
            .submitManagerDecision(
              leaveId: managerRequest.id,
              approve: true,
              note: 'اعتماد من اختبار Flutter',
            );
        expect(
          managerDecision.status,
          ManagerLeaveWorkflowStatus.managerApproved,
        );

        await signInAs(role: AppUserRole.hr, email: 'n.alsubaei@company.com');

        final hrNotifications = await AppServices.commonRepository
            .fetchNotifications(AppUserRole.hr);
        expect(
          hrNotifications.any(
            (item) => item.category == AppNotificationCategory.leave,
          ),
          isTrue,
        );

        final hrRequest =
            (await AppServices.leaveRepository.fetchHrLeaveRequests())
                .firstWhere((item) => item.id == createdLeave.id);

        final hrDecision = await AppServices.leaveRepository.submitHrDecision(
          leaveId: hrRequest.id,
          approve: true,
          note: 'اعتماد نهائي من اختبار Flutter',
        );
        expect(hrDecision.status, HrLeaveWorkflowStatus.approved);

        await signInAs(
          role: AppUserRole.manager,
          email: 'm.alotaibi@company.com',
        );

        final qrSession = await AppServices.attendanceRepository
            .createAttendanceQrSession(role: AppUserRole.manager);
        expect(qrSession.token, isNotEmpty);

        await signInAs(
          role: AppUserRole.employee,
          email: 'ahmad.khaled@company.com',
        );

        final attendance = await AppServices.attendanceRepository
            .scanAttendance(
              AttendanceScanPayload(
                token: qrSession.token,
                deviceId: 'flutter-test-device-001',
              ),
            );
        expect(attendance.method.toUpperCase(), 'QR');

        final employeeNotifications = await AppServices.commonRepository
            .fetchNotifications(AppUserRole.employee);
        expect(
          employeeNotifications.any(
            (item) => item.category == AppNotificationCategory.leave,
          ),
          isTrue,
        );
        expect(
          employeeNotifications.any(
            (item) => item.category == AppNotificationCategory.attendance,
          ),
          isTrue,
        );

        await AppServices.commonRepository.markAllNotificationsRead(
          AppUserRole.employee,
        );

        final refreshedNotifications = await AppServices.commonRepository
            .fetchNotifications(AppUserRole.employee);
        expect(refreshedNotifications.every((item) => item.isRead), isTrue);
      });
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
