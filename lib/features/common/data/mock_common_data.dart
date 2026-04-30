import '../domain/models/account_profile_data.dart';
import '../domain/models/app_notification_item.dart';
import '../domain/models/app_user_role.dart';

List<AppNotificationItem> notificationsForRole(AppUserRole role) {
  switch (role) {
    case AppUserRole.employee:
      return const [
        AppNotificationItem(
          id: 'EMP-N-1',
          title: 'طلب الإجازة ما زال قيد المراجعة',
          message:
              'تمت مراجعة طلبك من المدير وهو بانتظار اعتماد الموارد البشرية.',
          timeLabel: 'منذ 12 دقيقة',
          category: AppNotificationCategory.leave,
          isRead: false,
          actionLabel: 'عرض الطلب',
        ),
        AppNotificationItem(
          id: 'EMP-N-2',
          title: 'تم تسجيل حضور اليوم',
          message: 'تم توثيق حضورك عبر QR عند الساعة 08:12 صباحاً.',
          timeLabel: 'اليوم 08:13 ص',
          category: AppNotificationCategory.attendance,
          isRead: true,
          actionLabel: 'عرض السجل',
        ),
        AppNotificationItem(
          id: 'EMP-N-3',
          title: 'تمت إضافة الرصيد الشهري',
          message: 'تم تحديث رصيدك الشهري وإضافة 1.5 يوم إلى حساب الإجازات.',
          timeLabel: 'أمس',
          category: AppNotificationCategory.system,
          isRead: true,
          actionLabel: 'عرض الرصيد',
        ),
      ];
    case AppUserRole.manager:
      return const [
        AppNotificationItem(
          id: 'MGR-N-1',
          title: 'يوجد طلبان بانتظار قرارك',
          message:
              'تم إرسال طلبي إجازة جديدين من الفريق ويحتاجان مراجعة المدير المباشر.',
          timeLabel: 'منذ 8 دقائق',
          category: AppNotificationCategory.leave,
          isRead: false,
          actionLabel: 'فتح الطلبات',
        ),
        AppNotificationItem(
          id: 'MGR-N-2',
          title: 'تم مسح QR من قبل أحد الموظفين',
          message: 'تم تسجيل حضور جديد باستخدام رمز المدير الحالي بنجاح.',
          timeLabel: 'اليوم 08:09 ص',
          category: AppNotificationCategory.attendance,
          isRead: false,
          actionLabel: 'عرض الدوام',
        ),
        AppNotificationItem(
          id: 'MGR-N-3',
          title: 'تم تطبيق سياسة الرصيد الجديدة',
          message:
              'أصبحت الزيادة الشهرية الافتراضية 1.5 يوم على الفريق الحالي.',
          timeLabel: 'قبل يومين',
          category: AppNotificationCategory.system,
          isRead: true,
          actionLabel: 'عرض السياسة',
        ),
      ];
    case AppUserRole.hr:
    case AppUserRole.admin:
      return const [
        AppNotificationItem(
          id: 'HR-N-1',
          title: 'طلب جاهز لاعتماد الموارد البشرية',
          message:
              'أكمل المدير مراجعة طلب محمد سامي وأصبح جاهزاً للقرار النهائي.',
          timeLabel: 'منذ 5 دقائق',
          category: AppNotificationCategory.leave,
          isRead: false,
          actionLabel: 'اعتماد الطلب',
        ),
        AppNotificationItem(
          id: 'HR-N-2',
          title: 'تم استخدام رمز حضور HR',
          message: 'سُجل حضور جديد بواسطة رمز الموارد البشرية في بداية الدوام.',
          timeLabel: 'اليوم 08:11 ص',
          category: AppNotificationCategory.attendance,
          isRead: true,
          actionLabel: 'عرض السجل',
        ),
        AppNotificationItem(
          id: 'HR-N-3',
          title: 'تحديث سجلات الموظفين',
          message: 'تمت مزامنة آخر سجلات الرصيد والدوام وأصبحت جاهزة للمراجعة.',
          timeLabel: 'أمس',
          category: AppNotificationCategory.system,
          isRead: true,
          actionLabel: 'فتح الملفات',
        ),
      ];
  }
}

AccountProfileData profileForRole(AppUserRole role) {
  switch (role) {
    case AppUserRole.employee:
      return const AccountProfileData(
        role: AppUserRole.employee,
        name: 'أحمد خالد',
        code: 'EMP-014',
        email: 'ahmad.khaled@company.com',
        phone: '+966500000014',
        department: 'المبيعات',
        jobTitle: 'أخصائي مبيعات',
        joinDate: '12 يناير 2024',
        workSchedule: '08:00 ص - 04:00 م',
        workLocation: 'المكتب الرئيسي',
        lastLogin: 'اليوم 07:52 ص',
        deviceLabel: 'Android - Galaxy A54',
        permissions: [
          'طلب إجازة',
          'مسح QR للحضور',
          'عرض سجل الدوام',
          'عرض سجل الإجازات',
        ],
      );
    case AppUserRole.manager:
      return const AccountProfileData(
        role: AppUserRole.manager,
        name: 'محمد العتيبي',
        code: 'MGR-002',
        email: 'm.alotaibi@company.com',
        phone: '+966500000002',
        department: 'إدارة المبيعات',
        jobTitle: 'مدير مباشر',
        joinDate: '04 سبتمبر 2022',
        workSchedule: '08:00 ص - 04:00 م',
        workLocation: 'المكتب الرئيسي',
        lastLogin: 'اليوم 07:40 ص',
        deviceLabel: 'iPhone 14',
        permissions: [
          'اعتماد طلبات الإجازة',
          'عرض ملفات الموظفين',
          'تعديل الزيادة الشهرية',
          'عرض QR الحضور',
        ],
      );
    case AppUserRole.hr:
      return const AccountProfileData(
        role: AppUserRole.hr,
        name: 'نورة السبيعي',
        code: 'HR-001',
        email: 'n.alsubaei@company.com',
        phone: '+966500000001',
        department: 'الموارد البشرية',
        jobTitle: 'أخصائية موارد بشرية',
        joinDate: '18 مايو 2023',
        workSchedule: '08:00 ص - 04:00 م',
        workLocation: 'المكتب الرئيسي',
        lastLogin: 'اليوم 07:46 ص',
        deviceLabel: 'Windows Desktop',
        permissions: [
          'اعتماد نهائي للإجازات',
          'عرض ملفات الموظفين',
          'عرض سجلات الدوام',
          'عرض QR الحضور',
        ],
      );
    case AppUserRole.admin:
      return const AccountProfileData(
        role: AppUserRole.admin,
        name: 'System Admin',
        code: 'ADM-001',
        email: 'admin@company.com',
        phone: '+966500000000',
        department: 'Administration',
        jobTitle: 'System Administrator',
        joinDate: '29 April 2026',
        workSchedule: '08:00 - 16:00',
        workLocation: 'Main Office',
        lastLogin: 'Today',
        deviceLabel: 'Windows Desktop',
        permissions: [
          'Full system administration',
          'Create and edit managers',
          'Create and edit HR accounts',
          'Create and edit employees',
          'Access reports and approvals',
        ],
      );
  }
}

AccountProfileData? profileForEmail(String email) {
  final normalizedEmail = email.trim().toLowerCase();

  for (final role in AppUserRole.values) {
    final profile = profileForRole(role);
    if (profile.email.toLowerCase() == normalizedEmail) {
      return profile;
    }
  }

  return null;
}
