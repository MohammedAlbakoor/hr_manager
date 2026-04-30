import 'package:flutter/material.dart';

Future<String?> showEmployeePasswordDialog({
  required BuildContext context,
  required String employeeName,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _EmployeePasswordDialog(employeeName: employeeName),
  );
}

class _EmployeePasswordDialog extends StatefulWidget {
  const _EmployeePasswordDialog({required this.employeeName});

  final String employeeName;

  @override
  State<_EmployeePasswordDialog> createState() =>
      _EmployeePasswordDialogState();
}

class _EmployeePasswordDialogState extends State<_EmployeePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تغيير كلمة مرور الموظف'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('سيتم تعيين كلمة مرور جديدة للموظف ${widget.employeeName}.'),
              const SizedBox(height: 8),
              Text(
                'هذا الإجراء مخصص للموارد البشرية فقط، وسيؤدي إلى إنهاء جلسات الموظف الحالية.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'كلمة المرور الجديدة',
                  prefixIcon: Icon(Icons.lock_reset_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'أدخل كلمة المرور الجديدة';
                  }
                  if (value.trim().length < 6) {
                    return 'الحد الأدنى 6 أحرف';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'تأكيد كلمة المرور',
                  prefixIcon: Icon(Icons.verified_user_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'أعد إدخال كلمة المرور';
                  }
                  if (value.trim() != _passwordController.text.trim()) {
                    return 'كلمتا المرور غير متطابقتين';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        ElevatedButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.password_rounded),
          label: const Text('حفظ كلمة المرور'),
        ),
      ],
    );
  }

  void _submit() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    Navigator.of(context).pop(_passwordController.text.trim());
  }
}
