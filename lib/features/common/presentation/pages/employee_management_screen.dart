import 'dart:async';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/services/app_services.dart';
import '../../domain/models/app_user_role.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_error_state.dart';
import '../widgets/app_loading_state.dart';
import '../widgets/employee_administrative_record_dialog.dart';
import '../widgets/employee_cv_editor_dialog.dart';
import '../widgets/employee_editor_dialog.dart';
import '../widgets/employee_password_dialog.dart';
import '../widgets/role_bottom_navigation_bar.dart';
import '../../../manager/domain/models/employee_manager_option.dart';
import '../../../manager/domain/models/employee_upsert_payload.dart';
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

  Future<void> _uploadDocument({
    required ManagerEmployeeProfile employee,
    required EmployeeDocumentType type,
    required EmployeeDocumentSource source,
  }) async {
    final file = await _pickAttachment(source: source, imagesOnly: false);
    if (file == null) {
      return;
    }

    ManagerEmployeeProfile? updatedProfile;
    await _mutateProfile(() async {
      updatedProfile = await AppServices.employeeProfileRepository
          .uploadEmployeeDocument(
            employeeCode: employee.code,
            type: type,
            source: source,
            title: type.label,
            file: file,
            runOcr: type == EmployeeDocumentType.identityImage,
          );
      return updatedProfile!;
    }, 'تم رفع المستند وربطه بملف الموظف.');

    final updated = updatedProfile;
    if (!mounted ||
        updated == null ||
        type != EmployeeDocumentType.identityImage) {
      return;
    }

    final identityDocument = updated.documents
        .where(
          (document) => document.type == EmployeeDocumentType.identityImage,
        )
        .cast<EmployeeProfileDocument?>()
        .firstWhere(
          (document) => document?.hasOcrSuggestions == true,
          orElse: () => null,
        );
    if (identityDocument != null) {
      await _reviewIdentitySuggestions(updated, identityDocument);
    }
  }

  Future<void> _editCv(ManagerEmployeeProfile employee) async {
    final cv = await showEmployeeCvEditorDialog(
      context: context,
      initialCv: employee.cvProfile,
    );
    if (cv == null) {
      return;
    }

    await _mutateProfile(() {
      return AppServices.employeeProfileRepository.saveEmployeeCv(
        employeeCode: employee.code,
        cvProfile: cv,
      );
    }, 'تم حفظ السيرة الذاتية اليدوية.');
  }

  Future<void> _uploadCvPdf(ManagerEmployeeProfile employee) async {
    final file = await _pickAttachment(
      source: EmployeeDocumentSource.scanner,
      imagesOnly: false,
    );
    if (file == null) {
      return;
    }

    await _mutateProfile(() {
      return AppServices.employeeProfileRepository.uploadEmployeeCvPdf(
        employeeCode: employee.code,
        file: file,
        suggestAutofill: true,
      );
    }, 'تم رفع ملف السيرة الذاتية واستخراج النص المتاح.');
  }

  Future<void> _autofillCvFromFile(ManagerEmployeeProfile employee) async {
    if (employee.cvProfile.extractedText.trim().isEmpty &&
        !employee.cvProfile.hasPdf) {
      _showSnack('ارفع ملف PDF للسيرة الذاتية قبل التعبئة التلقائية.');
      return;
    }

    await _mutateProfile(() {
      return AppServices.employeeProfileRepository.autofillEmployeeCvFromFile(
        employee.code,
      );
    }, 'تم اقتراح تعبئة الحقول اليدوية من الملف.');
  }

  Future<void> _regenerateCvSummary(ManagerEmployeeProfile employee) async {
    await _mutateProfile(() {
      return AppServices.employeeProfileRepository.regenerateEmployeeCvSummary(
        employee.code,
      );
    }, 'تمت إعادة توليد الملخص المهني.');
  }

  Future<void> _addAdministrativeRecord(ManagerEmployeeProfile employee) async {
    final record = await showAdministrativeRecordDialog(context: context);
    if (record == null) {
      return;
    }

    final attachment = await _pickOptionalAttachment();
    await _mutateProfile(() {
      return AppServices.employeeProfileRepository.addAdministrativeRecord(
        employeeCode: employee.code,
        record: record,
        attachment: attachment,
      );
    }, 'تمت إضافة السجل الإداري.');
  }

  Future<void> _mutateProfile(
    Future<ManagerEmployeeProfile> Function() action,
    String successMessage,
  ) async {
    await _mutate(() async {
      final updated = await action();
      _replaceProfile(updated);
      _showSnack(successMessage);
    });
  }

  void _replaceProfile(ManagerEmployeeProfile updated) {
    final nextProfiles = _profiles.map((employee) {
      return employee.id == updated.id || employee.code == updated.code
          ? updated
          : employee;
    }).toList();

    setState(() {
      _profiles = nextProfiles;
      _selected = updated;
    });
  }

  Future<EmployeeProfileAttachmentFile?> _pickOptionalAttachment() async {
    final source = await showModalBottomSheet<EmployeeDocumentSource?>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              runSpacing: 8,
              children: [
                ListTile(
                  leading: const Icon(Icons.block_outlined),
                  title: const Text('بدون مرفق'),
                  onTap: () => Navigator.of(context).pop(null),
                ),
                ...EmployeeDocumentSource.values.map(
                  (source) => ListTile(
                    leading: Icon(source.icon),
                    title: Text(source.label),
                    onTap: () => Navigator.of(context).pop(source),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null) {
      return null;
    }
    return _pickAttachment(source: source, imagesOnly: false);
  }

  Future<EmployeeProfileAttachmentFile?> _pickAttachment({
    required EmployeeDocumentSource source,
    required bool imagesOnly,
  }) async {
    if (source == EmployeeDocumentSource.camera ||
        source == EmployeeDocumentSource.gallery) {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: source == EmployeeDocumentSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        imageQuality: 88,
      );
      if (image == null) {
        return null;
      }
      return EmployeeProfileAttachmentFile(
        name: image.name,
        path: kIsWeb ? null : image.path,
        bytes: kIsWeb ? await image.readAsBytes() : null,
        sizeBytes: await image.length(),
        mimeType: image.mimeType,
      );
    }

    final file = await openFile(
      acceptedTypeGroups: [
        XTypeGroup(
          label: imagesOnly ? 'Images' : 'Documents',
          extensions: imagesOnly
              ? const ['jpg', 'jpeg', 'png']
              : const ['pdf', 'jpg', 'jpeg', 'png'],
          mimeTypes: imagesOnly
              ? const ['image/jpeg', 'image/png']
              : const ['application/pdf', 'image/jpeg', 'image/png'],
          uniformTypeIdentifiers: imagesOnly
              ? const ['public.jpeg', 'public.png']
              : const ['com.adobe.pdf', 'public.jpeg', 'public.png'],
        ),
      ],
    );
    if (file == null) {
      return null;
    }
    return EmployeeProfileAttachmentFile(
      name: file.name,
      path: kIsWeb ? null : file.path,
      bytes: kIsWeb ? await file.readAsBytes() : null,
      sizeBytes: await file.length(),
      mimeType: file.mimeType ?? _mimeTypeForName(file.name),
    );
  }

  String? _mimeTypeForName(String name) {
    final dotIndex = name.lastIndexOf('.');
    final extension = dotIndex == -1 ? null : name.substring(dotIndex + 1);
    switch (extension?.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return null;
    }
  }

  Future<void> _reviewIdentitySuggestions(
    ManagerEmployeeProfile employee,
    EmployeeProfileDocument document,
  ) async {
    final suggestions = document.ocrSuggestions;
    final nameController = TextEditingController(
      text: suggestions['name'] ?? employee.name,
    );
    final identityController = TextEditingController(
      text: suggestions['identity_number'] ?? employee.identityNumber,
    );
    final birthDateController = TextEditingController(
      text: suggestions['birth_date'] ?? employee.birthDate,
    );
    final placeController = TextEditingController(
      text: suggestions['identity_place'] ?? employee.identityPlace,
    );
    final nationalityController = TextEditingController(
      text: suggestions['nationality'] ?? employee.nationality,
    );

    final shouldApply = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('مراجعة بيانات الهوية'),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'الاسم'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: identityController,
                    decoration: const InputDecoration(labelText: 'رقم الهوية'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: birthDateController,
                    decoration: const InputDecoration(
                      labelText: 'تاريخ الميلاد',
                      hintText: 'YYYY-MM-DD',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: placeController,
                    decoration: const InputDecoration(labelText: 'مكان القيد'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nationalityController,
                    decoration: const InputDecoration(labelText: 'الجنسية'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('تجاهل الاقتراح'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('اعتماد البيانات'),
            ),
          ],
        );
      },
    );

    final payload = EmployeeUpsertPayload(
      name: nameController.text.trim(),
      code: employee.code,
      email: employee.email,
      phone: employee.phone == '--' ? '' : employee.phone,
      department: employee.department == '--' ? '' : employee.department,
      jobTitle: employee.jobTitle == '--' ? '' : employee.jobTitle,
      workLocation: employee.workLocation == '--' ? '' : employee.workLocation,
      workSchedule: employee.workSchedule == '--' ? '' : employee.workSchedule,
      joinDate: employee.joinDate == '--' ? '' : employee.joinDate,
      birthDate: birthDateController.text.trim(),
      identityNumber: identityController.text.trim(),
      identityIssueDate: employee.identityIssueDate,
      identityExpiryDate: employee.identityExpiryDate,
      identityPlace: placeController.text.trim(),
      nationality: nationalityController.text.trim(),
      shamCashAccount: employee.shamCashAccount,
      address: employee.address,
      emergencyContact: employee.emergencyContact,
      jobLevel: employee.jobLevel,
      managerId: employee.managerId,
      role: _isAdmin ? employee.role : null,
    );

    nameController.dispose();
    identityController.dispose();
    birthDateController.dispose();
    placeController.dispose();
    nationalityController.dispose();

    if (shouldApply != true || !mounted) {
      return;
    }

    await _mutateProfile(() {
      return AppServices.employeeProfileRepository.updateEmployee(
        employeeCode: employee.code,
        payload: payload,
      );
    }, 'تم اعتماد بيانات الهوية كمصدر أساسي.');
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
                              : _EmployeeDetailsColumn(
                                  employee: current,
                                  isBusy: _isBusy,
                                  onUploadDocument: (type, source) =>
                                      _uploadDocument(
                                        employee: current,
                                        type: type,
                                        source: source,
                                      ),
                                  onEditCv: () => _editCv(current),
                                  onUploadCvPdf: () => _uploadCvPdf(current),
                                  onAutofillCv: () =>
                                      _autofillCvFromFile(current),
                                  onRegenerateCvSummary: () =>
                                      _regenerateCvSummary(current),
                                  onAddAdministrativeRecord: () =>
                                      _addAdministrativeRecord(current),
                                );

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
                      _EmployeeDetailsColumn(
                        employee: current,
                        isBusy: _isBusy,
                        onUploadDocument: (type, source) => _uploadDocument(
                          employee: current,
                          type: type,
                          source: source,
                        ),
                        onEditCv: () => _editCv(current),
                        onUploadCvPdf: () => _uploadCvPdf(current),
                        onAutofillCv: () => _autofillCvFromFile(current),
                        onRegenerateCvSummary: () =>
                            _regenerateCvSummary(current),
                        onAddAdministrativeRecord: () =>
                            _addAdministrativeRecord(current),
                      ),
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
