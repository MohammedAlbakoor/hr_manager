part of 'employee_management_screen.dart';

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({
    required this.role,
    required this.activeCount,
    required this.deletedCount,
    required this.visibleCount,
    required this.showDirectory,
  });

  final AppUserRole role;
  final int activeCount;
  final int deletedCount;
  final int visibleCount;
  final bool showDirectory;

  @override
  Widget build(BuildContext context) {
    final roleLabel = switch (role) {
      AppUserRole.admin => 'الإدارة',
      AppUserRole.hr => 'الموارد البشرية',
      _ => 'المدير',
    };
    final description = showDirectory
        ? 'ابحث عن الموظفين بالاسم أو الرقم الوظيفي، فلتر بالقسم والمدير والحالة، وادخل مباشرة إلى شاشة المحذوفين مع الاسترجاع.'
        : 'عرض ملف الموظف مع كل التفاصيل وسجل الإجازات والحضور، مع إمكانية التعديل أو الأرشفة أو الاسترجاع حسب الحالة.';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFC4561F), Color(0xFF5C2410), Color(0xFF382113)],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'إدارة الموظفين - $roleLabel',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.86),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _QuickMetric(
                label: 'نشطون',
                value: '$activeCount',
                color: const Color(0xFF0F766E),
              ),
              _QuickMetric(
                label: 'محذوفون',
                value: '$deletedCount',
                color: const Color(0xFFDC2626),
              ),
              _QuickMetric(
                label: 'نتائج حالية',
                value: '$visibleCount',
                color: const Color(0xFFEA580C),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickMetric extends StatelessWidget {
  const _QuickMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 10,
            width: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: Colors.white)),
          const SizedBox(width: 10),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text('$label ($count)'),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _EmployeeListCard extends StatelessWidget {
  const _EmployeeListCard({
    required this.title,
    required this.subtitle,
    required this.employees,
    required this.selectedCode,
    required this.onSelect,
  });

  final String title;
  final String subtitle;
  final List<ManagerEmployeeProfile> employees;
  final String? selectedCode;
  final ValueChanged<ManagerEmployeeProfile> onSelect;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(subtitle),
            const SizedBox(height: 16),
            ...employees.map(
              (employee) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _EmployeeListTile(
                  employee: employee,
                  selected: employee.code == selectedCode,
                  onTap: () => onSelect(employee),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmployeeListTile extends StatelessWidget {
  const _EmployeeListTile({
    required this.employee,
    required this.selected,
    required this.onTap,
  });

  final ManagerEmployeeProfile employee;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = employee.isDeleted
        ? const Color(0xFFFECACA)
        : const Color(0xFFDBEAFE);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? const Color(0xFF2563EB) : borderColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    employee.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _StateBadge(isDeleted: employee.isDeleted),
              ],
            ),
            const SizedBox(height: 8),
            Text('${employee.code} - ${employee.department}'),
            const SizedBox(height: 4),
            Text(employee.jobTitle),
            const SizedBox(height: 8),
            Text(
              employee.managerName == null
                  ? 'لا يوجد مدير مباشر مسجل'
                  : 'المدير المباشر: ${employee.managerName}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _StateBadge extends StatelessWidget {
  const _StateBadge({required this.isDeleted});

  final bool isDeleted;

  @override
  Widget build(BuildContext context) {
    final color = isDeleted ? const Color(0xFFDC2626) : const Color(0xFF0F766E);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isDeleted ? 'مؤرشف' : 'نشط',
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _EmployeeDetailsColumn extends StatelessWidget {
  const _EmployeeDetailsColumn({required this.employee});

  final ManagerEmployeeProfile employee;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _MetricCard(
              label: 'الحالة',
              value: employee.isDeleted ? 'مؤرشف' : 'نشط',
            ),
            _MetricCard(label: 'القسم', value: employee.department),
            _MetricCard(label: 'الرصيد', value: employee.leaveBalanceLabel),
            _MetricCard(
              label: 'طلبات معلقة',
              value: '${employee.pendingLeavesCount}',
            ),
          ],
        ),
        const SizedBox(height: 16),
        _InfoCard(employee: employee),
        const SizedBox(height: 16),
        _HistoryCard(
          title: 'آخر الإجازات',
          icon: Icons.event_note_outlined,
          child: employee.leaveItems.isEmpty
              ? const Text('لا توجد طلبات إجازة حديثة لهذا الموظف.')
              : Column(
                  children: employee.leaveItems
                      .map(
                        (item) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: item.status.color.withValues(
                              alpha: 0.12,
                            ),
                            child: Icon(
                              item.status.icon,
                              color: item.status.color,
                            ),
                          ),
                          title: Text(item.title),
                          subtitle: Text(
                            '${item.periodLabel} - ${item.daysCount} يوم',
                          ),
                          trailing: Text(
                            item.status.label,
                            style: TextStyle(
                              color: item.status.color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
        const SizedBox(height: 16),
        _HistoryCard(
          title: 'سجل الحضور',
          icon: Icons.access_time_rounded,
          child: employee.attendanceItems.isEmpty
              ? const Text('لا توجد سجلات حضور حديثة لهذا الموظف.')
              : Column(
                  children: employee.attendanceItems
                      .map(
                        (item) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: item.status.color.withValues(
                              alpha: 0.12,
                            ),
                            child: Icon(
                              item.status.icon,
                              color: item.status.color,
                            ),
                          ),
                          title: Text(item.dateLabel),
                          subtitle: Text('وقت الحضور: ${item.checkInLabel}'),
                          trailing: Text(
                            item.status.label,
                            style: TextStyle(
                              color: item.status.color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.employee});

  final ManagerEmployeeProfile employee;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'بيانات الموظف',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            _InfoRow(label: 'الرقم الوظيفي', value: employee.code),
            _InfoRow(
              label: 'الحالة',
              value: employee.isDeleted ? 'مؤرشف' : 'نشط',
            ),
            _InfoRow(
              label: 'نوع الحساب',
              value: employee.roleLabel ?? employee.role.label,
            ),
            _InfoRow(label: 'المسمى الوظيفي', value: employee.jobTitle),
            _InfoRow(label: 'القسم', value: employee.department),
            _InfoRow(label: 'البريد الإلكتروني', value: employee.email),
            _InfoRow(label: 'الهاتف', value: employee.phone),
            _InfoRow(label: 'موقع العمل', value: employee.workLocation),
            _InfoRow(label: 'ساعات العمل', value: employee.workSchedule),
            _InfoRow(label: 'تاريخ الانضمام', value: employee.joinDate),
            _InfoRow(
              label: 'المدير المباشر',
              value: employee.managerName == null
                  ? '--'
                  : '${employee.managerName!} (${employee.managerCode ?? '--'})',
            ),
            if (employee.deletedAt != null)
              _InfoRow(label: 'تاريخ الأرشفة', value: employee.deletedAt!),
            _InfoRow(label: 'آخر حضور', value: employee.lastCheckInLabel),
            _InfoRow(label: 'حالة اليوم', value: employee.todayAttendanceLabel),
          ],
        ),
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}
