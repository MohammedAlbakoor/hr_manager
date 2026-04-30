import 'package:flutter/material.dart';

import '../../domain/models/employee_leave_request.dart';

class EmployeeLeaveDetailsScreen extends StatelessWidget {
  const EmployeeLeaveDetailsScreen({super.key, required this.request});

  final EmployeeLeaveRequest request;

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
                    _DetailsHero(request: request),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      children:
                          [
                                _DetailMetric(
                                  title: 'رقم الطلب',
                                  value: request.id,
                                  icon: Icons.tag_rounded,
                                  color: const Color(0xFF1D4ED8),
                                ),
                                _DetailMetric(
                                  title: 'عدد الأيام',
                                  value: '${request.daysCount} يوم',
                                  icon: Icons.date_range_rounded,
                                  color: const Color(0xFFEA580C),
                                ),
                                _DetailMetric(
                                  title: 'الرصيد قبل الطلب',
                                  value: request.currentBalanceLabel,
                                  icon: Icons.account_balance_wallet_outlined,
                                  color: const Color(0xFF0F766E),
                                ),
                                _DetailMetric(
                                  title: 'الرصيد بعد الطلب',
                                  value: request.remainingBalanceLabel,
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
                            child: _DetailsSection(
                              title: 'بيانات الطلب',
                              children: [
                                _InfoRow(
                                  label: 'نوع الإجازة',
                                  value: request.type,
                                ),
                                _InfoRow(
                                  label: 'من تاريخ',
                                  value: request.startDateLabel,
                                ),
                                _InfoRow(
                                  label: 'إلى تاريخ',
                                  value: request.endDateLabel,
                                ),
                                _InfoRow(
                                  label: 'تاريخ إنشاء الطلب',
                                  value: request.requestedAtLabel,
                                ),
                                _InfoRow(
                                  label: 'الملاحظة',
                                  value: request.note,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _ApprovalTimelineCard(request: request),
                          ),
                        ],
                      )
                    else ...[
                      _DetailsSection(
                        title: 'بيانات الطلب',
                        children: [
                          _InfoRow(label: 'نوع الإجازة', value: request.type),
                          _InfoRow(
                            label: 'من تاريخ',
                            value: request.startDateLabel,
                          ),
                          _InfoRow(
                            label: 'إلى تاريخ',
                            value: request.endDateLabel,
                          ),
                          _InfoRow(
                            label: 'تاريخ إنشاء الطلب',
                            value: request.requestedAtLabel,
                          ),
                          _InfoRow(label: 'الملاحظة', value: request.note),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _ApprovalTimelineCard(request: request),
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

  final EmployeeLeaveRequest request;

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
                      request.title,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      request.periodLabel,
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
            'هذه الصفحة تعرض حالة الطلب الحالية، الرصيد، وتفاصيل الموافقة من المدير والموارد البشرية.',
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

  final LeaveRequestStatus status;

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

class _DetailMetric extends StatelessWidget {
  const _DetailMetric({
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

class _DetailsSection extends StatelessWidget {
  const _DetailsSection({required this.title, required this.children});

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

class _ApprovalTimelineCard extends StatelessWidget {
  const _ApprovalTimelineCard({required this.request});

  final EmployeeLeaveRequest request;

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
          Text('حالة الموافقات', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          _ApprovalStepCard(
            title: 'مراجعة المدير المباشر',
            status: request.managerStatus,
            note: request.managerNote,
          ),
          const SizedBox(height: 14),
          _ApprovalStepCard(
            title: 'مراجعة الموارد البشرية',
            status: request.hrStatus,
            note: request.hrNote,
          ),
        ],
      ),
    );
  }
}

class _ApprovalStepCard extends StatelessWidget {
  const _ApprovalStepCard({
    required this.title,
    required this.status,
    required this.note,
  });

  final String title;
  final LeaveApprovalStatus status;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: status.color.withValues(alpha: 0.14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(status.icon, color: status.color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  status.label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: status.color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  note,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
