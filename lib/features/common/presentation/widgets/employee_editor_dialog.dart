import 'package:flutter/material.dart';

import '../../../common/domain/models/app_user_role.dart';
import '../../../manager/domain/models/employee_manager_option.dart';
import '../../../manager/domain/models/employee_upsert_payload.dart';
import '../../../manager/domain/models/manager_employee_profile.dart';

Future<EmployeeUpsertPayload?> showEmployeeEditorDialog({
  required BuildContext context,
  required AppUserRole role,
  required List<EmployeeManagerOption> managerOptions,
  ManagerEmployeeProfile? initialProfile,
}) {
  return showDialog<EmployeeUpsertPayload>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _EmployeeEditorDialog(
      role: role,
      managerOptions: managerOptions,
      initialProfile: initialProfile,
    ),
  );
}

class _EmployeeEditorDialog extends StatefulWidget {
  const _EmployeeEditorDialog({
    required this.role,
    required this.managerOptions,
    this.initialProfile,
  });

  final AppUserRole role;
  final List<EmployeeManagerOption> managerOptions;
  final ManagerEmployeeProfile? initialProfile;

  @override
  State<_EmployeeEditorDialog> createState() => _EmployeeEditorDialogState();
}

class _EmployeeEditorDialogState extends State<_EmployeeEditorDialog> {
  static const _defaultWorkSchedule = '08:00 - 16:00';

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _birthDateController;
  late final TextEditingController _identityNumberController;
  late final TextEditingController _identityIssueDateController;
  late final TextEditingController _identityExpiryDateController;
  late final TextEditingController _identityPlaceController;
  late final TextEditingController _nationalityController;
  late final TextEditingController _shamCashAccountController;
  late final TextEditingController _addressController;
  late final TextEditingController _emergencyContactController;
  late final TextEditingController _departmentController;
  late final TextEditingController _jobTitleController;
  late final TextEditingController _workLocationController;
  late final TextEditingController _workScheduleController;
  late final TextEditingController _joinDateController;
  late final TextEditingController _passwordController;
  late AppUserRole _selectedAccountRole;
  late EmployeeJobLevel _selectedJobLevel;
  int? _selectedManagerId;

  bool get _isEdit => widget.initialProfile != null;
  bool get _isAdmin => widget.role == AppUserRole.admin;
  bool get _canAssignManagers =>
      widget.role == AppUserRole.hr || widget.role == AppUserRole.admin;
  bool get _showManagerPicker =>
      _canAssignManagers && _selectedAccountRole == AppUserRole.employee;
  int? get _selectedManagerValue =>
      widget.managerOptions.any((option) => option.id == _selectedManagerId)
      ? _selectedManagerId
      : null;

  @override
  void initState() {
    super.initState();
    final profile = widget.initialProfile;
    _selectedAccountRole = _isAdmin
        ? (profile?.role ?? AppUserRole.employee)
        : AppUserRole.employee;
    _nameController = TextEditingController(text: profile?.name ?? '');
    _codeController = TextEditingController(text: profile?.code ?? '');
    _emailController = TextEditingController(
      text: profile == null || profile.email == '--' ? '' : profile.email,
    );
    _phoneController = TextEditingController(
      text: profile == null || profile.phone == '--' ? '' : profile.phone,
    );
    _birthDateController = TextEditingController(
      text: profile?.birthDate ?? '',
    );
    _identityNumberController = TextEditingController(
      text: profile?.identityNumber ?? '',
    );
    _identityIssueDateController = TextEditingController(
      text: profile?.identityIssueDate ?? '',
    );
    _identityExpiryDateController = TextEditingController(
      text: profile?.identityExpiryDate ?? '',
    );
    _identityPlaceController = TextEditingController(
      text: profile?.identityPlace ?? '',
    );
    _nationalityController = TextEditingController(
      text: profile?.nationality ?? '',
    );
    _shamCashAccountController = TextEditingController(
      text: profile?.shamCashAccount ?? '',
    );
    _addressController = TextEditingController(text: profile?.address ?? '');
    _emergencyContactController = TextEditingController(
      text: profile?.emergencyContact ?? '',
    );
    _departmentController = TextEditingController(
      text: profile == null || profile.department == '--'
          ? ''
          : profile.department,
    );
    _jobTitleController = TextEditingController(
      text: profile == null || profile.jobTitle == '--' ? '' : profile.jobTitle,
    );
    _workLocationController = TextEditingController(
      text: profile == null || profile.workLocation == '--'
          ? ''
          : profile.workLocation,
    );
    _workScheduleController = TextEditingController(
      text: profile == null || profile.workSchedule == '--'
          ? _defaultWorkSchedule
          : profile.workSchedule,
    );
    _joinDateController = TextEditingController(
      text: profile == null || profile.joinDate == '--' ? '' : profile.joinDate,
    );
    _passwordController = TextEditingController();
    _selectedJobLevel = profile?.jobLevel ?? EmployeeJobLevel.member;
    _selectedManagerId = _selectedAccountRole == AppUserRole.employee
        ? profile?.managerId ??
              (widget.managerOptions.isEmpty
                  ? null
                  : widget.managerOptions.first.id)
        : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    _identityNumberController.dispose();
    _identityIssueDateController.dispose();
    _identityExpiryDateController.dispose();
    _identityPlaceController.dispose();
    _nationalityController.dispose();
    _shamCashAccountController.dispose();
    _addressController.dispose();
    _emergencyContactController.dispose();
    _departmentController.dispose();
    _jobTitleController.dispose();
    _workLocationController.dispose();
    _workScheduleController.dispose();
    _joinDateController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'تعديل بيانات الموظف' : 'إضافة موظف جديد'),
      content: SizedBox(
        width: 620,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionTitle(context, 'البيانات الأساسية'),
                _buildTextField(
                  controller: _nameController,
                  label: 'اسم الموظف',
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _codeController,
                  label: 'الرقم الوظيفي',
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _emailController,
                  label: 'البريد الإلكتروني',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'أدخل البريد الإلكتروني';
                    }
                    if (!value.contains('@')) {
                      return 'صيغة البريد غير صحيحة';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _phoneController,
                  label: 'رقم الجوال',
                  keyboardType: TextInputType.phone,
                  requiredField: false,
                ),
                const SizedBox(height: 12),
                _buildDateField(
                  context,
                  controller: _birthDateController,
                  label: 'تاريخ الميلاد',
                  requiredField: false,
                  firstDate: DateTime(1940),
                  lastDate: DateTime.now(),
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _addressController,
                  label: 'العنوان',
                  requiredField: false,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _emergencyContactController,
                  label: 'رقم الطوارئ',
                  keyboardType: TextInputType.phone,
                  requiredField: false,
                ),
                const SizedBox(height: 18),
                _buildSectionTitle(context, 'الهوية الرسمية والحسابات'),
                _buildTextField(
                  controller: _identityNumberController,
                  label: 'رقم الهوية',
                  keyboardType: TextInputType.number,
                  requiredField: false,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _identityPlaceController,
                  label: 'مكان القيد / الإصدار',
                  requiredField: false,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _nationalityController,
                  label: 'الجنسية',
                  requiredField: false,
                ),
                const SizedBox(height: 12),
                _buildDateField(
                  context,
                  controller: _identityIssueDateController,
                  label: 'تاريخ إصدار الهوية',
                  requiredField: false,
                  firstDate: DateTime(1980),
                  lastDate: DateTime(2100),
                ),
                const SizedBox(height: 12),
                _buildDateField(
                  context,
                  controller: _identityExpiryDateController,
                  label: 'تاريخ انتهاء الهوية',
                  requiredField: false,
                  firstDate: DateTime(1980),
                  lastDate: DateTime(2100),
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _shamCashAccountController,
                  label: 'رقم حساب شام كاش',
                  requiredField: false,
                ),
                const SizedBox(height: 18),
                _buildSectionTitle(context, 'البيانات الوظيفية'),
                DropdownButtonFormField<EmployeeJobLevel>(
                  initialValue: _selectedJobLevel,
                  decoration: const InputDecoration(
                    labelText: 'السوية الوظيفية',
                    prefixIcon: Icon(Icons.account_tree_outlined),
                  ),
                  items: EmployeeJobLevel.values
                      .map(
                        (level) => DropdownMenuItem<EmployeeJobLevel>(
                          value: level,
                          child: Text(level.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _selectedJobLevel = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _departmentController,
                  label: 'القسم',
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _jobTitleController,
                  label: 'المسمى الوظيفي',
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _workLocationController,
                  label: 'موقع العمل',
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _workScheduleController,
                  label: 'ساعات العمل',
                  hintText: _defaultWorkSchedule,
                ),
                const SizedBox(height: 12),
                _buildDateField(
                  context,
                  controller: _joinDateController,
                  label: 'تاريخ الانضمام',
                ),
                if (_isAdmin) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<AppUserRole>(
                    initialValue: _selectedAccountRole,
                    decoration: const InputDecoration(
                      labelText: 'دور الحساب',
                      prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                    ),
                    items: const [
                      DropdownMenuItem<AppUserRole>(
                        value: AppUserRole.employee,
                        child: Text('موظف'),
                      ),
                      DropdownMenuItem<AppUserRole>(
                        value: AppUserRole.manager,
                        child: Text('مدير'),
                      ),
                      DropdownMenuItem<AppUserRole>(
                        value: AppUserRole.hr,
                        child: Text('موارد بشرية'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _selectedAccountRole = value;
                        if (value == AppUserRole.employee) {
                          _selectedManagerId ??= widget.managerOptions.isEmpty
                              ? null
                              : widget.managerOptions.first.id;
                        } else {
                          _selectedManagerId = null;
                        }
                      });
                    },
                  ),
                ],
                if (_showManagerPicker) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    key: ValueKey<String>(
                      'employee-manager:${widget.managerOptions.map((option) => option.id).join(',')}:${_selectedManagerValue?.toString() ?? 'none'}',
                    ),
                    initialValue: _selectedManagerValue,
                    decoration: const InputDecoration(
                      labelText: 'المدير المباشر',
                      prefixIcon: Icon(Icons.manage_accounts_outlined),
                    ),
                    items: widget.managerOptions
                        .map(
                          (option) => DropdownMenuItem<int>(
                            value: option.id,
                            child: Text(option.displayLabel),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedManagerId = value;
                      });
                    },
                    validator: (value) {
                      if (_showManagerPicker && value == null) {
                        return 'اختر المدير المباشر';
                      }
                      return null;
                    },
                  ),
                ],
                if (!_isEdit) ...[
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _passwordController,
                    label: 'كلمة المرور',
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'أدخل كلمة المرور';
                      }
                      if (value.trim().length < 6) {
                        return 'الحد الأدنى 6 أحرف';
                      }
                      return null;
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(_isEdit ? 'حفظ التعديلات' : 'إضافة الموظف'),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _buildDateField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    bool requiredField = true,
    DateTime? firstDate,
    DateTime? lastDate,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        hintText: 'YYYY-MM-DD',
        prefixIcon: const Icon(Icons.calendar_month_outlined),
        suffixIcon: IconButton(
          onPressed: () => _pickDate(
            context,
            controller: controller,
            firstDate: firstDate,
            lastDate: lastDate,
          ),
          icon: const Icon(Icons.edit_calendar_outlined),
        ),
      ),
      validator: (value) {
        if (!requiredField) {
          return null;
        }
        if (value == null || value.trim().isEmpty) {
          return 'اختر $label';
        }
        return null;
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    TextInputType? keyboardType,
    bool obscureText = false,
    bool requiredField = true,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(labelText: label, hintText: hintText),
      validator:
          validator ??
          (value) {
            if (!requiredField) {
              return null;
            }
            if (value == null || value.trim().isEmpty) {
              return 'هذا الحقل مطلوب';
            }
            return null;
          },
    );
  }

  Future<void> _pickDate(
    BuildContext context, {
    required TextEditingController controller,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    final initial = DateTime.tryParse(controller.text) ?? DateTime.now();
    final first = firstDate ?? DateTime(2000);
    final last = lastDate ?? DateTime(2100);
    final selected = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(first)
          ? first
          : initial.isAfter(last)
          ? last
          : initial,
      firstDate: first,
      lastDate: last,
    );
    if (selected == null || !mounted) {
      return;
    }

    final month = selected.month.toString().padLeft(2, '0');
    final day = selected.day.toString().padLeft(2, '0');
    controller.text = '${selected.year}-$month-$day';
  }

  void _submit() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    Navigator.of(context).pop(
      EmployeeUpsertPayload(
        name: _nameController.text.trim(),
        code: _codeController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        birthDate: _birthDateController.text.trim(),
        identityNumber: _identityNumberController.text.trim(),
        identityIssueDate: _identityIssueDateController.text.trim(),
        identityExpiryDate: _identityExpiryDateController.text.trim(),
        identityPlace: _identityPlaceController.text.trim(),
        nationality: _nationalityController.text.trim(),
        shamCashAccount: _shamCashAccountController.text.trim(),
        address: _addressController.text.trim(),
        emergencyContact: _emergencyContactController.text.trim(),
        jobLevel: _selectedJobLevel,
        department: _departmentController.text.trim(),
        jobTitle: _jobTitleController.text.trim(),
        workLocation: _workLocationController.text.trim(),
        workSchedule: _workScheduleController.text.trim(),
        joinDate: _joinDateController.text.trim(),
        password: _isEdit ? null : _passwordController.text.trim(),
        managerId: _showManagerPicker ? _selectedManagerId : null,
        role: _isAdmin ? _selectedAccountRole : null,
      ),
    );
  }
}
