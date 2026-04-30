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
  late final TextEditingController _departmentController;
  late final TextEditingController _jobTitleController;
  late final TextEditingController _workLocationController;
  late final TextEditingController _workScheduleController;
  late final TextEditingController _joinDateController;
  late final TextEditingController _passwordController;
  late AppUserRole _selectedAccountRole;
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
                _buildDateField(context),
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

  Widget _buildDateField(BuildContext context) {
    return TextFormField(
      controller: _joinDateController,
      readOnly: true,
      decoration: InputDecoration(
        labelText: 'تاريخ الانضمام',
        hintText: 'YYYY-MM-DD',
        prefixIcon: const Icon(Icons.calendar_month_outlined),
        suffixIcon: IconButton(
          onPressed: () => _pickJoinDate(context),
          icon: const Icon(Icons.edit_calendar_outlined),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'اختر تاريخ الانضمام';
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

  Future<void> _pickJoinDate(BuildContext context) async {
    final initial =
        DateTime.tryParse(_joinDateController.text) ?? DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selected == null || !mounted) {
      return;
    }

    final month = selected.month.toString().padLeft(2, '0');
    final day = selected.day.toString().padLeft(2, '0');
    _joinDateController.text = '${selected.year}-$month-$day';
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
