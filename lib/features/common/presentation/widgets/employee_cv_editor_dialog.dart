import 'package:flutter/material.dart';

import '../../../manager/domain/models/manager_employee_profile.dart';

Future<EmployeeCvProfile?> showEmployeeCvEditorDialog({
  required BuildContext context,
  required EmployeeCvProfile initialCv,
}) {
  return showDialog<EmployeeCvProfile>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _EmployeeCvEditorDialog(initialCv: initialCv),
  );
}

class _EmployeeCvEditorDialog extends StatefulWidget {
  const _EmployeeCvEditorDialog({required this.initialCv});

  final EmployeeCvProfile initialCv;

  @override
  State<_EmployeeCvEditorDialog> createState() =>
      _EmployeeCvEditorDialogState();
}

class _EmployeeCvEditorDialogState extends State<_EmployeeCvEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _summaryController;
  late final TextEditingController _skillsController;
  late final TextEditingController _experienceController;
  late final TextEditingController _educationController;
  late final TextEditingController _coursesController;

  @override
  void initState() {
    super.initState();
    final cv = widget.initialCv;
    _summaryController = TextEditingController(text: cv.professionalSummary);
    _skillsController = TextEditingController(text: cv.skills.join('\n'));
    _experienceController = TextEditingController(
      text: _formatItems(cv.experience),
    );
    _educationController = TextEditingController(
      text: _formatItems(cv.education),
    );
    _coursesController = TextEditingController(text: _formatItems(cv.courses));
  }

  @override
  void dispose() {
    _summaryController.dispose();
    _skillsController.dispose();
    _experienceController.dispose();
    _educationController.dispose();
    _coursesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('السيرة الذاتية اليدوية'),
      content: SizedBox(
        width: 700,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextArea(
                  controller: _summaryController,
                  label: 'الملخص المهني',
                  minLines: 3,
                ),
                const SizedBox(height: 12),
                _buildTextArea(
                  controller: _skillsController,
                  label: 'المهارات',
                  hint: 'اكتب كل مهارة في سطر مستقل',
                ),
                const SizedBox(height: 12),
                _buildStructuredArea(
                  controller: _experienceController,
                  label: 'الخبرات العملية',
                ),
                const SizedBox(height: 12),
                _buildStructuredArea(
                  controller: _educationController,
                  label: 'الشهادات',
                ),
                const SizedBox(height: 12),
                _buildStructuredArea(
                  controller: _coursesController,
                  label: 'الدورات',
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
        ElevatedButton(
          onPressed: _submit,
          child: const Text('حفظ السيرة الذاتية'),
        ),
      ],
    );
  }

  Widget _buildTextArea({
    required TextEditingController controller,
    required String label,
    String? hint,
    int minLines = 2,
  }) {
    return TextFormField(
      controller: controller,
      minLines: minLines,
      maxLines: 6,
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }

  Widget _buildStructuredArea({
    required TextEditingController controller,
    required String label,
  }) {
    return _buildTextArea(
      controller: controller,
      label: label,
      minLines: 3,
      hint: 'العنوان | الجهة | الفترة | الوصف',
    );
  }

  void _submit() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    Navigator.of(context).pop(
      widget.initialCv.copyWith(
        professionalSummary: _summaryController.text.trim(),
        skills: _parseLines(_skillsController.text),
        experience: _parseItems(_experienceController.text),
        education: _parseItems(_educationController.text),
        courses: _parseItems(_coursesController.text),
      ),
    );
  }

  String _formatItems(List<EmployeeCvItem> items) {
    return items
        .map(
          (item) => [
            item.title,
            item.organization,
            item.period,
            item.description,
          ].join(' | '),
        )
        .join('\n');
  }

  List<String> _parseLines(String value) {
    return value
        .split(RegExp(r'[\n,]'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  List<EmployeeCvItem> _parseItems(String value) {
    return value
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .map((line) {
          final parts = line.split('|').map((part) => part.trim()).toList();
          return EmployeeCvItem(
            title: parts.isEmpty ? '' : parts[0],
            organization: parts.length > 1 ? parts[1] : '',
            period: parts.length > 2 ? parts[2] : '',
            description: parts.length > 3 ? parts.sublist(3).join(' | ') : '',
          );
        })
        .where((item) => !item.isEmpty)
        .toList();
  }
}
