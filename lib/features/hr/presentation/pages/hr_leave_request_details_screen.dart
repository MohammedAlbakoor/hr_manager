import 'package:flutter/material.dart';

import '../../../../core/services/app_services.dart';
import '../../domain/models/hr_leave_request.dart';
import 'hr_employee_details_screen.dart';

class HrLeaveRequestDetailsScreen extends StatefulWidget {
  const HrLeaveRequestDetailsScreen({super.key, required this.request});

  final HrLeaveRequest request;

  @override
  State<HrLeaveRequestDetailsScreen> createState() =>
      _HrLeaveRequestDetailsScreenState();
}

class _HrLeaveRequestDetailsScreenState
    extends State<HrLeaveRequestDetailsScreen> {
  late HrLeaveRequest _request;
  final _decisionNoteController = TextEditingController();
  bool _isSubmittingDecision = false;
  bool _isOpeningEmployeeFile = false;

  bool get _canDecide => _request.status == HrLeaveWorkflowStatus.pendingHr;

  @override
  void initState() {
    super.initState();
    _request = widget.request;
  }

  @override
  void dispose() {
    _decisionNoteController.dispose();
    super.dispose();
  }

  Future<void> _openEmployeeFile() async {
    setState(() {
      _isOpeningEmployeeFile = true;
    });

    try {
      final profile = await AppServices.employeeProfileRepository
          .fetchEmployeeProfileByCode(_request.employeeCode);
      if (!mounted) {
        return;
      }
      if (profile == null) {
        _showDecisionSnackBar('تعذر العثور على ملف الموظف.');
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => HrEmployeeDetailsScreen(profile: profile),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showDecisionSnackBar(error.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isOpeningEmployeeFile = false;
        });
      }
    }
  }

  Future<void> _approveRequest() async {
    await _submitDecision(approve: true);
  }

  Future<void> _rejectRequest() async {
    await _submitDecision(approve: false);
  }

  Future<void> _submitDecision({required bool approve}) async {
    setState(() {
      _isSubmittingDecision = true;
    });

    try {
      final updatedRequest = await AppServices.leaveRepository.submitHrDecision(
        leaveId: _request.id,
        approve: approve,
        note: _decisionNoteController.text.trim(),
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _request = updatedRequest;
      });

      _showDecisionSnackBar(
        approve
            ? 'تم اعتماد الطلب نهائياً من الموارد البشرية.'
            : 'تم رفض الطلب من الموارد البشرية.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showDecisionSnackBar(error.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingDecision = false;
        });
      }
    }
  }

  void _showDecisionSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 900;
    final cardWidth = isWide
        ? 250.0
        : ((width - 40).clamp(240.0, 460.0)).toDouble();

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل طلب الإجازة'),
        centerTitle: true,
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FAFC), Color(0xFFF0F9FF)],
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _DetailsHero(request: _request),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      children:
                          [
                                _MetricCard(
                                  title: 'الموظف',
                                  value: _request.employeeName,
                                  icon: Icons.person_outline_rounded,
                                  color: const Color(0xFF1D4ED8),
                                ),
                                _MetricCard(
                                  title: 'عدد الأيام',
                                  value: '${_request.daysCount} يوم',
                                  icon: Icons.date_range_rounded,
                                  color: const Color(0xFFEA580C),
                                ),
                                _MetricCard(
                                  title: 'الرصيد الحالي',
                                  value: _request.currentBalanceLabel,
                                  icon: Icons.account_balance_wallet_outlined,
                                  color: const Color(0xFF0F766E),
                                ),
                                _MetricCard(
                                  title: 'الرصيد بعد الطلب',
                                  value: _request.remainingBalanceLabel,
                                  icon: Icons.stacked_line_chart_rounded,
                                  color: const Color(0xFF7C3AED),
                                ),
                              ]
                              .map(
                                (card) =>
                                    SizedBox(width: cardWidth, child: card),
                              )
                              .toList(),
                    ),
                    const SizedBox(height: 20),
                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _SectionCard(
                              title: 'بيانات الطلب',
                              children: [
                                _InfoRow(
                                  label: 'اسم الموظف',
                                  value: _request.employeeName,
                                ),
                                _InfoRow(
                                  label: 'الرقم الوظيفي',
                                  value: _request.employeeCode,
                                ),
                                _InfoRow(
                                  label: 'القسم',
                                  value: _request.department,
                                ),
                                _InfoRow(
                                  label: 'نوع الإجازة',
                                  value: _request.leaveType,
                                ),
                                _InfoRow(
                                  label: 'الفترة',
                                  value: _request.periodLabel,
                                ),
                                _InfoRow(
                                  label: 'تاريخ التقديم',
                                  value: _request.submittedAtLabel,
                                ),
                                _InfoRow(
                                  label: 'ملاحظة الموظف',
                                  value: _request.employeeNote,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _StatusCard(request: _request),
                                const SizedBox(height: 16),
                                OutlinedButton.icon(
                                  onPressed: _isOpeningEmployeeFile
                                      ? null
                                      : _openEmployeeFile,
                                  icon: _isOpeningEmployeeFile
                                      ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.badge_outlined),
                                  label: Text(
                                    _isOpeningEmployeeFile
                                        ? 'جاري فتح ملف الموظف'
                                        : 'فتح ملف الموظف',
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _DecisionCard(
                                  controller: _decisionNoteController,
                                  canDecide:
                                      _canDecide && !_isSubmittingDecision,
                                  isSubmitting: _isSubmittingDecision,
                                  onApprove: _approveRequest,
                                  onReject: _rejectRequest,
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    else ...[
                      _SectionCard(
                        title: 'بيانات الطلب',
                        children: [
                          _InfoRow(
                            label: 'اسم الموظف',
                            value: _request.employeeName,
                          ),
                          _InfoRow(
                            label: 'الرقم الوظيفي',
                            value: _request.employeeCode,
                          ),
                          _InfoRow(label: 'القسم', value: _request.department),
                          _InfoRow(
                            label: 'نوع الإجازة',
                            value: _request.leaveType,
                          ),
                          _InfoRow(
                            label: 'الفترة',
                            value: _request.periodLabel,
                          ),
                          _InfoRow(
                            label: 'تاريخ التقديم',
                            value: _request.submittedAtLabel,
                          ),
                          _InfoRow(
                            label: 'ملاحظة الموظف',
                            value: _request.employeeNote,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _StatusCard(request: _request),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _isOpeningEmployeeFile
                            ? null
                            : _openEmployeeFile,
                        icon: _isOpeningEmployeeFile
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.badge_outlined),
                        label: Text(
                          _isOpeningEmployeeFile
                              ? 'جاري فتح ملف الموظف'
                              : 'فتح ملف الموظف',
                        ),
                      ),
                      const SizedBox(height: 16),
                      _DecisionCard(
                        controller: _decisionNoteController,
                        canDecide: _canDecide && !_isSubmittingDecision,
                        isSubmitting: _isSubmittingDecision,
                        onApprove: _approveRequest,
                        onReject: _rejectRequest,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailsHero extends StatelessWidget {
  const _DetailsHero({required this.request});

  final HrLeaveRequest request;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF0F172A), Color(0xFF102A5C), Color(0xFF1D4ED8)],
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 54,
                width: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(request.status.icon, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.employeeName,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${request.leaveType} - ${request.periodLabel}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              _StatusPill(status: request.status),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'تتحقق الموارد البشرية من الرصيد والسجل وقرار المدير، ثم تعتمد الطلب نهائياً أو ترفضه.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.88),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final HrLeaveWorkflowStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 14),
          Text(title, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: const Color(0xFF64748B)),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.request});

  final HrLeaveRequest request;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('حالة القرارين', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          _StatusBlock(
            title: 'قرار المدير المباشر',
            statusLabel: request.managerStatusLabel,
            note: request.managerNote,
            color: request.status == HrLeaveWorkflowStatus.waitingManager
                ? const Color(0xFF7C3AED)
                : request.status == HrLeaveWorkflowStatus.rejected
                ? const Color(0xFFDC2626)
                : const Color(0xFF0F766E),
          ),
          const SizedBox(height: 14),
          _StatusBlock(
            title: 'قرار الموارد البشرية',
            statusLabel: request.status.label,
            note: request.hrNote,
            color: request.status.color,
          ),
        ],
      ),
    );
  }
}

class _StatusBlock extends StatelessWidget {
  const _StatusBlock({
    required this.title,
    required this.statusLabel,
    required this.note,
    required this.color,
  });

  final String title;
  final String statusLabel;
  final String note;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            statusLabel,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            note,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFF475569)),
          ),
        ],
      ),
    );
  }
}

class _DecisionCard extends StatelessWidget {
  const _DecisionCard({
    required this.controller,
    required this.canDecide,
    required this.isSubmitting,
    required this.onApprove,
    required this.onReject,
  });

  final TextEditingController controller;
  final bool canDecide;
  final bool isSubmitting;
  final Future<void> Function() onApprove;
  final Future<void> Function() onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'قرار الموارد البشرية',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Text(
            canDecide
                ? 'يمكنك إضافة ملاحظة قبل اتخاذ القرار النهائي.'
                : 'هذا الطلب ليس في مرحلة قرار الموارد البشرية حالياً.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            minLines: 4,
            maxLines: 5,
            enabled: canDecide,
            decoration: const InputDecoration(
              labelText: 'ملاحظة HR',
              hintText: 'أضف سبب الاعتماد أو الرفض إن لزم',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: canDecide ? onReject : null,
                  icon: const Icon(Icons.close_rounded),
                  label: Text(isSubmitting ? '...' : 'رفض'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: canDecide ? onApprove : null,
                  icon: isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(isSubmitting ? '...' : 'اعتماد'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
