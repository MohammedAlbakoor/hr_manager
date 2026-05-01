import 'package:flutter/material.dart';

import '../../../manager/domain/models/manager_employee_profile.dart';

Future<EmployeeAdministrativeRecordDraft?> showAdministrativeRecordDialog({
  required BuildContext context,
}) {
  return showDialog<EmployeeAdministrativeRecordDraft>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _AdministrativeRecordDialog(),
  );
}

class _AdministrativeRecordDialog extends StatefulWidget {
  const _AdministrativeRecordDialog();

  @override
  State<_AdministrativeRecordDialog> createState() =>
      _AdministrativeRecordDialogState();
}

class _AdministrativeRecordDialogState
    extends State<_AdministrativeRecordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _referenceController = TextEditingController();
  final _dateController = TextEditingController();
  final _descriptionController = TextEditingController();
  EmployeeAdministrativeRecordCategory _category =
      EmployeeAdministrativeRecordCategory.decision;

  @override
  void dispose() {
    _titleController.dispose();
    _referenceController.dispose();
    _dateController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إضافة سجل إداري'),
      content: SizedBox(
        width: 620,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<EmployeeAdministrativeRecordCategory>(
                  initialValue: _category,
                  decoration: const InputDecoration(
                    labelText: 'تصنيف السجل',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: EmployeeAdministrativeRecordCategory.values
                      .map(
                        (category) =>
                            DropdownMenuItem<
                              EmployeeAdministrativeRecordCategory
                            >(value: category, child: Text(category.label)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _category = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'عنوان السجل'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'أدخل عنوان السجل';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _referenceController,
                  decoration: const InputDecoration(
                    labelText: 'رقم المرجع / الكتاب',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _dateController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'تاريخ السجل',
                    hintText: 'YYYY-MM-DD',
                    prefixIcon: const Icon(Icons.calendar_month_outlined),
                    suffixIcon: IconButton(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.edit_calendar_outlined),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'اختر تاريخ السجل';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(labelText: 'الوصف'),
                ),
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
        ElevatedButton(onPressed: _submit, child: const Text('إضافة السجل')),
      ],
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = DateTime.tryParse(_dateController.text) ?? now;
    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selected == null || !mounted) {
      return;
    }
    _dateController.text =
        '${selected.year}-${selected.month.toString().padLeft(2, '0')}-${selected.day.toString().padLeft(2, '0')}';
  }

  void _submit() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    Navigator.of(context).pop(
      EmployeeAdministrativeRecordDraft(
        category: _category,
        title: _titleController.text.trim(),
        recordDate: _dateController.text.trim(),
        referenceNumber: _referenceController.text.trim(),
        description: _descriptionController.text.trim(),
      ),
    );
  }
}
