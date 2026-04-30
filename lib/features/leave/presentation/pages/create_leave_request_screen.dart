import 'package:flutter/material.dart';

import '../../../../core/services/app_services.dart';
import '../../../common/domain/models/app_dashboard_summary.dart';
import '../../../common/domain/models/app_user_role.dart';
import '../../../common/presentation/widgets/app_error_state.dart';
import '../../../common/presentation/widgets/app_loading_state.dart';
import '../../domain/models/create_leave_request_payload.dart';

class CreateLeaveRequestScreen extends StatefulWidget {
  const CreateLeaveRequestScreen({super.key});

  @override
  State<CreateLeaveRequestScreen> createState() =>
      _CreateLeaveRequestScreenState();
}

class _CreateLeaveRequestScreenState extends State<CreateLeaveRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();

  static const _leaveTypes = [
    DropdownMenuItem(value: 'annual', child: Text('إجازة سنوية')),
    DropdownMenuItem(value: 'sick', child: Text('إجازة مرضية')),
    DropdownMenuItem(value: 'emergency', child: Text('إجازة اضطرارية')),
    DropdownMenuItem(value: 'unpaid', child: Text('إجازة بدون راتب')),
  ];

  AppDashboardSummary? _summary;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _selectedType;
  DateTime? _startDate;
  DateTime? _endDate;

  double get _currentBalance => _summary?.leaveBalanceDays ?? 0;
  double get _monthlyIncrement => _summary?.monthlyIncrement ?? 1.5;
  String? get _selectedLeaveTypeValue =>
      _leaveTypes.any((item) => item.value == _selectedType)
      ? _selectedType
      : null;

  int get _daysCount {
    if (_startDate == null || _endDate == null) {
      return 0;
    }
    return _endDate!.difference(_startDate!).inDays + 1;
  }

  bool get _hasValidRange {
    if (_startDate == null || _endDate == null) {
      return false;
    }
    return !_endDate!.isBefore(_startDate!);
  }

  bool get _hasEnoughBalance =>
      !_hasValidRange || _daysCount <= _currentBalance;

  double get _remainingBalance {
    if (!_hasValidRange) {
      return _currentBalance;
    }
    final remaining = _currentBalance - _daysCount;
    return remaining < 0 ? 0 : remaining;
  }

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadSummary({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    try {
      final summary = await AppServices.commonRepository.fetchDashboardSummary(
        AppUserRole.employee,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _summary = summary;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      if (showLoader) {
        setState(() {
          _errorMessage = 'تعذر تحميل رصيد الإجازات الحالي.';
        });
      }
    } finally {
      if (mounted && showLoader) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('ar'),
      initialDate: isStart
          ? (_startDate ?? now)
          : (_endDate ?? _startDate ?? now),
      firstDate: isStart ? now : (_startDate ?? now),
      lastDate: DateTime(now.year + 2),
      helpText: isStart ? 'اختر تاريخ البداية' : 'اختر تاريخ النهاية',
    );
    if (picked == null) {
      return;
    }
    setState(() {
      final normalized = DateTime(picked.year, picked.month, picked.day);
      if (isStart) {
        _startDate = normalized;
        if (_endDate != null && _endDate!.isBefore(normalized)) {
          _endDate = normalized;
        }
      } else {
        _endDate = normalized;
      }
    });
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      return;
    }
    if (!_hasValidRange) {
      _showSnackBar('اختر تاريخ البداية والنهاية بشكل صحيح.');
      return;
    }
    if (!_hasEnoughBalance) {
      _showSnackBar('لا يمكن إرسال الطلب لأن الرصيد الحالي غير كافٍ.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });
    try {
      final request = await AppServices.leaveRepository.createLeaveRequest(
        CreateLeaveRequestPayload(
          leaveType: _selectedType!,
          startDate: _startDate!,
          endDate: _endDate!,
          note: _noteController.text.trim(),
        ),
      );
      if (!mounted) {
        return;
      }
      await _loadSummary(showLoader: false);
      if (!mounted) {
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('تم إنشاء الطلب'),
          content: Text(
            'نوع الإجازة: ${request.title}\n'
            'الفترة: ${request.periodLabel}\n'
            'عدد الأيام: ${request.daysCount}\n'
            'سيتم إرسال الطلب إلى المدير ثم الموارد البشرية.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedType = null;
        _startDate = null;
        _endDate = null;
        _noteController.clear();
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showSnackBar(error.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: SafeArea(
          child: AppLoadingState(
            title: 'جاري تحميل الطلب',
            message: 'نجهز الرصيد الحقيقي وسياسة الإجازات الحالية.',
          ),
        ),
      );
    }

    if (_errorMessage != null || _summary == null) {
      return Scaffold(
        body: SafeArea(
          child: AppErrorState(
            title: 'حدث خطأ',
            message: _errorMessage ?? 'تعذر تحميل الصفحة.',
            onRetry: _loadSummary,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('طلب إجازة جديد'), centerTitle: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'أنشئ طلب الإجازة بثقة قبل الإرسال',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'الرصيد الحالي: ${_currentBalance.toStringAsFixed(1)} يوم',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'الزيادة الشهرية الحالية: ${_monthlyIncrement.toStringAsFixed(1)} يوم',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _daysCount == 0
                          ? 'أدخل تواريخ الطلب لحساب الأيام تلقائياً.'
                          : 'الرصيد بعد الطلب: ${_remainingBalance.toStringAsFixed(1)} يوم',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _Stat(
                  'الرصيد الحالي',
                  '${_currentBalance.toStringAsFixed(1)} يوم',
                ),
                _Stat(
                  'الأيام المطلوبة',
                  _daysCount == 0 ? '--' : '$_daysCount يوم',
                ),
                _Stat(
                  'الرصيد بعد الطلب',
                  '${_remainingBalance.toStringAsFixed(1)} يوم',
                ),
                const _Stat('تدفق الموافقة', 'مدير + HR'),
              ],
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        key: ValueKey<String>(
                          'leave-type:${_selectedLeaveTypeValue ?? 'none'}',
                        ),
                        initialValue: _selectedLeaveTypeValue,
                        items: _leaveTypes,
                        onChanged: _isSubmitting
                            ? null
                            : (value) => setState(() => _selectedType = value),
                        decoration: const InputDecoration(
                          labelText: 'نوع الإجازة',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        validator: (value) =>
                            value == null ? 'اختر نوع الإجازة' : null,
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.event_outlined),
                        title: const Text('من تاريخ'),
                        subtitle: Text(_formatDate(_startDate)),
                        onTap: _isSubmitting
                            ? null
                            : () => _pickDate(isStart: true),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.event_available_outlined),
                        title: const Text('إلى تاريخ'),
                        subtitle: Text(_formatDate(_endDate)),
                        onTap: _isSubmitting
                            ? null
                            : () => _pickDate(isStart: false),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _noteController,
                        minLines: 4,
                        maxLines: 5,
                        enabled: !_isSubmitting,
                        decoration: const InputDecoration(
                          labelText: 'ملاحظة',
                          alignLabelWithHint: true,
                          prefixIcon: Padding(
                            padding: EdgeInsets.only(bottom: 56),
                            child: Icon(Icons.notes_rounded),
                          ),
                        ),
                        validator: (value) =>
                            value != null && value.length > 300
                            ? 'الحد الأقصى 300 حرف'
                            : null,
                      ),
                      if (!_hasEnoughBalance && _hasValidRange) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'عدد الأيام المطلوبة أكبر من الرصيد المتاح حالياً.',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _submit,
                        icon: _isSubmitting
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send_rounded),
                        label: Text(
                          _isSubmitting ? 'جاري إرسال الطلب' : 'إرسال الطلب',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'اختر التاريخ';
    }
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.title, this.value);
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 255,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            const SizedBox(height: 10),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    ),
  );
}
