import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../common/domain/models/app_user_role.dart';
import 'manager_leave_request.dart';

enum ManagerAttendanceStatus {
  present(
    label: 'حضور',
    color: Color(0xFF0F766E),
    icon: Icons.check_circle_rounded,
  ),
  late(
    label: 'متأخر',
    color: Color(0xFFEA580C),
    icon: Icons.watch_later_rounded,
  ),
  absent(
    label: 'غياب',
    color: Color(0xFFDC2626),
    icon: Icons.person_off_rounded,
  );

  const ManagerAttendanceStatus({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;
}

enum EmployeeJobLevel {
  branchManager('branch_manager', 'مدير فرع'),
  departmentHead('department_head', 'رئيس قسم'),
  officeManager('office_manager', 'مسؤول مكتب'),
  seniorOfficeManager('senior_office_manager', 'مسؤول مكتب أول'),
  officeMember('office_member', 'عنصر مكتب'),
  member('member', 'عنصر');

  const EmployeeJobLevel(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static EmployeeJobLevel fromStorage(String? value) {
    for (final level in values) {
      if (level.apiValue == value || level.name == value) {
        return level;
      }
    }
    return EmployeeJobLevel.member;
  }
}

enum EmployeeDocumentType {
  identityImage(
    'identity_image',
    'صورة الهوية',
    Icons.badge_outlined,
    Color(0xFF2563EB),
  ),
  familyStatement(
    'family_statement',
    'بيان عائلي',
    Icons.family_restroom_outlined,
    Color(0xFF0F766E),
  ),
  educationCertificate(
    'education_certificate',
    'شهادة علمية',
    Icons.school_outlined,
    Color(0xFF7C3AED),
  ),
  trainingCertificate(
    'training_certificate',
    'شهادة تدريب',
    Icons.workspace_premium_outlined,
    Color(0xFFB45309),
  ),
  cvPdf(
    'cv_pdf',
    'السيرة الذاتية PDF',
    Icons.picture_as_pdf_outlined,
    Color(0xFFDC2626),
  ),
  administrativeRecord(
    'administrative_record',
    'مرفق سجل إداري',
    Icons.gavel_outlined,
    Color(0xFF475569),
  ),
  additionalAttachment(
    'additional_attachment',
    'مرفق إضافي',
    Icons.attach_file_rounded,
    Color(0xFF0891B2),
  );

  const EmployeeDocumentType(this.apiValue, this.label, this.icon, this.color);

  final String apiValue;
  final String label;
  final IconData icon;
  final Color color;

  static EmployeeDocumentType fromStorage(String? value) {
    for (final type in values) {
      if (type.apiValue == value || type.name == value) {
        return type;
      }
    }
    return EmployeeDocumentType.additionalAttachment;
  }
}

enum EmployeeDocumentSource {
  camera('camera', 'كاميرا الجوال', Icons.photo_camera_outlined),
  gallery('gallery', 'المعرض', Icons.photo_library_outlined),
  scanner('scanner', 'ملف سكانر', Icons.document_scanner_outlined),
  upload('upload', 'رفع ملف', Icons.upload_file_outlined);

  const EmployeeDocumentSource(this.apiValue, this.label, this.icon);

  final String apiValue;
  final String label;
  final IconData icon;

  static EmployeeDocumentSource fromStorage(String? value) {
    for (final source in values) {
      if (source.apiValue == value || source.name == value) {
        return source;
      }
    }
    return EmployeeDocumentSource.upload;
  }
}

enum EmployeeAdministrativeRecordCategory {
  incoming('incoming', 'واردات', Icons.move_to_inbox_outlined),
  outgoing('outgoing', 'صادرات', Icons.outbox_outlined),
  decision('decision', 'قرار إداري', Icons.verified_user_outlined),
  telegram('telegram', 'برقية', Icons.mark_email_unread_outlined),
  other('other', 'أخرى', Icons.folder_copy_outlined);

  const EmployeeAdministrativeRecordCategory(
    this.apiValue,
    this.label,
    this.icon,
  );

  final String apiValue;
  final String label;
  final IconData icon;

  static EmployeeAdministrativeRecordCategory fromStorage(String? value) {
    for (final category in values) {
      if (category.apiValue == value || category.name == value) {
        return category;
      }
    }
    return EmployeeAdministrativeRecordCategory.other;
  }
}

class EmployeeProfileAttachmentFile {
  const EmployeeProfileAttachmentFile({
    required this.name,
    this.path,
    this.bytes,
    this.sizeBytes,
    this.mimeType,
  });

  final String name;
  final String? path;
  final Uint8List? bytes;
  final int? sizeBytes;
  final String? mimeType;
}

class EmployeeProfileDocument {
  const EmployeeProfileDocument({
    required this.id,
    required this.type,
    required this.title,
    required this.fileName,
    required this.uploadedAt,
    this.source = EmployeeDocumentSource.upload,
    this.mimeType,
    this.sizeBytes,
    this.url,
    this.ocrText,
    this.ocrSuggestions = const {},
  });

  final String id;
  final EmployeeDocumentType type;
  final String title;
  final String fileName;
  final String uploadedAt;
  final EmployeeDocumentSource source;
  final String? mimeType;
  final int? sizeBytes;
  final String? url;
  final String? ocrText;
  final Map<String, String> ocrSuggestions;

  bool get hasOcrSuggestions => ocrSuggestions.isNotEmpty;

  String get sizeLabel {
    final bytes = sizeBytes;
    if (bytes == null || bytes <= 0) {
      return '--';
    }
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }

  EmployeeProfileDocument copyWith({
    String? id,
    EmployeeDocumentType? type,
    String? title,
    String? fileName,
    String? uploadedAt,
    EmployeeDocumentSource? source,
    String? mimeType,
    int? sizeBytes,
    String? url,
    String? ocrText,
    Map<String, String>? ocrSuggestions,
  }) {
    return EmployeeProfileDocument(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      fileName: fileName ?? this.fileName,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      source: source ?? this.source,
      mimeType: mimeType ?? this.mimeType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      url: url ?? this.url,
      ocrText: ocrText ?? this.ocrText,
      ocrSuggestions: ocrSuggestions ?? this.ocrSuggestions,
    );
  }
}

class EmployeeCvItem {
  const EmployeeCvItem({
    required this.title,
    this.organization = '',
    this.period = '',
    this.description = '',
  });

  final String title;
  final String organization;
  final String period;
  final String description;

  bool get isEmpty =>
      title.trim().isEmpty &&
      organization.trim().isEmpty &&
      period.trim().isEmpty &&
      description.trim().isEmpty;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'organization': organization,
      'period': period,
      'description': description,
    };
  }

  static EmployeeCvItem fromJson(Map<String, dynamic> json) {
    return EmployeeCvItem(
      title: (json['title'] ?? '').toString(),
      organization: (json['organization'] ?? '').toString(),
      period: (json['period'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
    );
  }
}

class EmployeeCvProfile {
  const EmployeeCvProfile({
    this.professionalSummary = '',
    this.skills = const [],
    this.experience = const [],
    this.education = const [],
    this.courses = const [],
    this.pdfDocument,
    this.extractedText = '',
    this.generatedSummary = '',
    this.updatedAt = '',
  });

  const EmployeeCvProfile.empty() : this();

  final String professionalSummary;
  final List<String> skills;
  final List<EmployeeCvItem> experience;
  final List<EmployeeCvItem> education;
  final List<EmployeeCvItem> courses;
  final EmployeeProfileDocument? pdfDocument;
  final String extractedText;
  final String generatedSummary;
  final String updatedAt;

  bool get hasManualData =>
      professionalSummary.trim().isNotEmpty ||
      skills.isNotEmpty ||
      experience.isNotEmpty ||
      education.isNotEmpty ||
      courses.isNotEmpty;

  bool get hasPdf => pdfDocument != null;

  EmployeeCvProfile copyWith({
    String? professionalSummary,
    List<String>? skills,
    List<EmployeeCvItem>? experience,
    List<EmployeeCvItem>? education,
    List<EmployeeCvItem>? courses,
    EmployeeProfileDocument? pdfDocument,
    String? extractedText,
    String? generatedSummary,
    String? updatedAt,
    bool clearPdfDocument = false,
  }) {
    return EmployeeCvProfile(
      professionalSummary: professionalSummary ?? this.professionalSummary,
      skills: skills ?? this.skills,
      experience: experience ?? this.experience,
      education: education ?? this.education,
      courses: courses ?? this.courses,
      pdfDocument: clearPdfDocument ? null : (pdfDocument ?? this.pdfDocument),
      extractedText: extractedText ?? this.extractedText,
      generatedSummary: generatedSummary ?? this.generatedSummary,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'professional_summary': professionalSummary,
      'skills': skills,
      'experience': experience.map((item) => item.toJson()).toList(),
      'education': education.map((item) => item.toJson()).toList(),
      'courses': courses.map((item) => item.toJson()).toList(),
    };
  }
}

class EmployeeAdministrativeRecord {
  const EmployeeAdministrativeRecord({
    required this.id,
    required this.category,
    required this.title,
    required this.recordDate,
    this.referenceNumber = '',
    this.description = '',
    this.document,
    this.createdAt = '',
  });

  final String id;
  final EmployeeAdministrativeRecordCategory category;
  final String title;
  final String recordDate;
  final String referenceNumber;
  final String description;
  final EmployeeProfileDocument? document;
  final String createdAt;
}

class EmployeeAdministrativeRecordDraft {
  const EmployeeAdministrativeRecordDraft({
    required this.category,
    required this.title,
    required this.recordDate,
    this.referenceNumber = '',
    this.description = '',
  });

  final EmployeeAdministrativeRecordCategory category;
  final String title;
  final String recordDate;
  final String referenceNumber;
  final String description;

  Map<String, dynamic> toJson() {
    return {
      'category': category.apiValue,
      'title': title,
      'record_date': recordDate,
      'reference_number': referenceNumber,
      'description': description,
    };
  }
}

class ManagerEmployeeProfile {
  const ManagerEmployeeProfile({
    required this.id,
    required this.name,
    required this.code,
    required this.jobTitle,
    required this.department,
    required this.email,
    required this.phone,
    required this.leaveBalanceLabel,
    required this.usedLeavesLabel,
    required this.monthlyIncrement,
    required this.pendingLeavesCount,
    required this.todayAttendanceLabel,
    required this.lastCheckInLabel,
    required this.leaveItems,
    required this.attendanceItems,
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
    this.documents = const [],
    this.cvProfile = const EmployeeCvProfile.empty(),
    this.administrativeRecords = const [],
    this.role = AppUserRole.employee,
    this.roleLabel,
    this.deletedAt,
    this.managerId,
    this.managerName,
    this.managerCode,
  });

  final String id;
  final String name;
  final String code;
  final String jobTitle;
  final String department;
  final String email;
  final String phone;
  final String leaveBalanceLabel;
  final String usedLeavesLabel;
  final double monthlyIncrement;
  final int pendingLeavesCount;
  final String todayAttendanceLabel;
  final String lastCheckInLabel;
  final List<ManagerEmployeeLeaveItem> leaveItems;
  final List<ManagerEmployeeAttendanceItem> attendanceItems;
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
  final List<EmployeeProfileDocument> documents;
  final EmployeeCvProfile cvProfile;
  final List<EmployeeAdministrativeRecord> administrativeRecords;
  final AppUserRole role;
  final String? roleLabel;
  final String? deletedAt;
  final int? managerId;
  final String? managerName;
  final String? managerCode;

  bool get isDeleted => deletedAt != null;
  bool get isActive => !isDeleted;

  ManagerEmployeeProfile copyWith({
    String? id,
    String? name,
    String? code,
    String? jobTitle,
    String? department,
    String? email,
    String? phone,
    String? leaveBalanceLabel,
    String? usedLeavesLabel,
    double? monthlyIncrement,
    int? pendingLeavesCount,
    String? todayAttendanceLabel,
    String? lastCheckInLabel,
    List<ManagerEmployeeLeaveItem>? leaveItems,
    List<ManagerEmployeeAttendanceItem>? attendanceItems,
    String? workLocation,
    String? workSchedule,
    String? joinDate,
    String? birthDate,
    String? identityNumber,
    String? identityIssueDate,
    String? identityExpiryDate,
    String? identityPlace,
    String? nationality,
    String? shamCashAccount,
    String? address,
    String? emergencyContact,
    EmployeeJobLevel? jobLevel,
    List<EmployeeProfileDocument>? documents,
    EmployeeCvProfile? cvProfile,
    List<EmployeeAdministrativeRecord>? administrativeRecords,
    AppUserRole? role,
    String? roleLabel,
    String? deletedAt,
    int? managerId,
    String? managerName,
    String? managerCode,
    bool clearManager = false,
    bool clearDeletedAt = false,
  }) {
    return ManagerEmployeeProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      jobTitle: jobTitle ?? this.jobTitle,
      department: department ?? this.department,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      leaveBalanceLabel: leaveBalanceLabel ?? this.leaveBalanceLabel,
      usedLeavesLabel: usedLeavesLabel ?? this.usedLeavesLabel,
      monthlyIncrement: monthlyIncrement ?? this.monthlyIncrement,
      pendingLeavesCount: pendingLeavesCount ?? this.pendingLeavesCount,
      todayAttendanceLabel: todayAttendanceLabel ?? this.todayAttendanceLabel,
      lastCheckInLabel: lastCheckInLabel ?? this.lastCheckInLabel,
      leaveItems: leaveItems ?? this.leaveItems,
      attendanceItems: attendanceItems ?? this.attendanceItems,
      workLocation: workLocation ?? this.workLocation,
      workSchedule: workSchedule ?? this.workSchedule,
      joinDate: joinDate ?? this.joinDate,
      birthDate: birthDate ?? this.birthDate,
      identityNumber: identityNumber ?? this.identityNumber,
      identityIssueDate: identityIssueDate ?? this.identityIssueDate,
      identityExpiryDate: identityExpiryDate ?? this.identityExpiryDate,
      identityPlace: identityPlace ?? this.identityPlace,
      nationality: nationality ?? this.nationality,
      shamCashAccount: shamCashAccount ?? this.shamCashAccount,
      address: address ?? this.address,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      jobLevel: jobLevel ?? this.jobLevel,
      documents: documents ?? this.documents,
      cvProfile: cvProfile ?? this.cvProfile,
      administrativeRecords:
          administrativeRecords ?? this.administrativeRecords,
      role: role ?? this.role,
      roleLabel: roleLabel ?? this.roleLabel,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      managerId: clearManager ? null : (managerId ?? this.managerId),
      managerName: clearManager ? null : (managerName ?? this.managerName),
      managerCode: clearManager ? null : (managerCode ?? this.managerCode),
    );
  }
}

class ManagerEmployeeLeaveItem {
  const ManagerEmployeeLeaveItem({
    required this.title,
    required this.periodLabel,
    required this.daysCount,
    required this.status,
  });

  final String title;
  final String periodLabel;
  final int daysCount;
  final ManagerLeaveWorkflowStatus status;
}

class ManagerEmployeeAttendanceItem {
  const ManagerEmployeeAttendanceItem({
    required this.dateLabel,
    required this.checkInLabel,
    required this.status,
  });

  final String dateLabel;
  final String checkInLabel;
  final ManagerAttendanceStatus status;
}
