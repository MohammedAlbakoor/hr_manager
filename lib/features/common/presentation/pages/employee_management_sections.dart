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

enum _ProfileTab {
  info('البيانات', Icons.badge_outlined),
  documents('الوثائق', Icons.folder_copy_outlined),
  cv('السيرة الذاتية', Icons.description_outlined),
  admin('السجل الإداري', Icons.gavel_outlined);

  const _ProfileTab(this.label, this.icon);

  final String label;
  final IconData icon;
}

class _EmployeeDetailsColumn extends StatefulWidget {
  const _EmployeeDetailsColumn({
    required this.employee,
    required this.isBusy,
    required this.onUploadDocument,
    required this.onEditCv,
    required this.onUploadCvPdf,
    required this.onAutofillCv,
    required this.onRegenerateCvSummary,
    required this.onAddAdministrativeRecord,
  });

  final ManagerEmployeeProfile employee;
  final bool isBusy;
  final void Function(EmployeeDocumentType, EmployeeDocumentSource)
  onUploadDocument;
  final VoidCallback onEditCv;
  final VoidCallback onUploadCvPdf;
  final VoidCallback onAutofillCv;
  final VoidCallback onRegenerateCvSummary;
  final VoidCallback onAddAdministrativeRecord;

  @override
  State<_EmployeeDetailsColumn> createState() => _EmployeeDetailsColumnState();
}

class _EmployeeDetailsColumnState extends State<_EmployeeDetailsColumn> {
  _ProfileTab _tab = _ProfileTab.info;

  @override
  Widget build(BuildContext context) {
    final employee = widget.employee;

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
            _MetricCard(label: 'السوية', value: employee.jobLevel.label),
            _MetricCard(label: 'الرصيد', value: employee.leaveBalanceLabel),
            _MetricCard(label: 'وثائق', value: '${employee.documents.length}'),
          ],
        ),
        const SizedBox(height: 16),
        _ProfileHeaderCard(employee: employee),
        const SizedBox(height: 16),
        _ProfileTabBar(
          selected: _tab,
          onSelected: (tab) {
            setState(() {
              _tab = tab;
            });
          },
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: KeyedSubtree(
            key: ValueKey<_ProfileTab>(_tab),
            child: switch (_tab) {
              _ProfileTab.info => _ProfileInfoTab(employee: employee),
              _ProfileTab.documents => _DocumentManagementCard(
                employee: employee,
                isBusy: widget.isBusy,
                onUploadDocument: widget.onUploadDocument,
              ),
              _ProfileTab.cv => _CvProfileCard(
                employee: employee,
                isBusy: widget.isBusy,
                onEditCv: widget.onEditCv,
                onUploadCvPdf: widget.onUploadCvPdf,
                onAutofillCv: widget.onAutofillCv,
                onRegenerateCvSummary: widget.onRegenerateCvSummary,
              ),
              _ProfileTab.admin => _AdministrativeRecordsCard(
                employee: employee,
                isBusy: widget.isBusy,
                onAddRecord: widget.onAddAdministrativeRecord,
              ),
            },
          ),
        ),
      ],
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({required this.employee});

  final ManagerEmployeeProfile employee;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: employee.jobLevel == EmployeeJobLevel.member
                  ? const Color(0xFFEFF6FF)
                  : const Color(0xFFECFDF5),
              child: Text(
                employee.name.trim().isEmpty ? '?' : employee.name.trim()[0],
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    employee.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text('${employee.code} - ${employee.jobTitle}'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MiniPill(
                        label: employee.department,
                        icon: Icons.apartment_outlined,
                      ),
                      _MiniPill(
                        label: employee.jobLevel.label,
                        icon: Icons.account_tree_outlined,
                      ),
                      _MiniPill(
                        label: employee.isDeleted ? 'مؤرشف' : 'نشط',
                        icon: employee.isDeleted
                            ? Icons.archive_outlined
                            : Icons.check_circle_outline,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFDDE6F3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF64748B)),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _ProfileTabBar extends StatelessWidget {
  const _ProfileTabBar({required this.selected, required this.onSelected});

  final _ProfileTab selected;
  final ValueChanged<_ProfileTab> onSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _ProfileTab.values.map((tab) {
            final isSelected = tab == selected;
            return ChoiceChip(
              avatar: Icon(tab.icon, size: 18),
              label: Text(tab.label),
              selected: isSelected,
              onSelected: (_) => onSelected(tab),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _ProfileInfoTab extends StatelessWidget {
  const _ProfileInfoTab({required this.employee});

  final ManagerEmployeeProfile employee;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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

class _DocumentManagementCard extends StatelessWidget {
  const _DocumentManagementCard({
    required this.employee,
    required this.isBusy,
    required this.onUploadDocument,
  });

  final ManagerEmployeeProfile employee;
  final bool isBusy;
  final void Function(EmployeeDocumentType, EmployeeDocumentSource)
  onUploadDocument;

  @override
  Widget build(BuildContext context) {
    return _HistoryCard(
      title: 'إدارة الوثائق',
      icon: Icons.folder_copy_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: EmployeeDocumentType.values
                .where((type) => type != EmployeeDocumentType.cvPdf)
                .map(
                  (type) => OutlinedButton.icon(
                    onPressed: isBusy
                        ? null
                        : () => _showUploadSourceSheet(context, type),
                    icon: Icon(type.icon),
                    label: Text(type.label),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          if (employee.documents.isEmpty)
            const AppEmptyState(
              title: 'لا توجد وثائق مرفوعة',
              message: 'ارفع صورة هوية أو شهادة أو مرفق لربطه بملف الموظف.',
              icon: Icons.folder_off_outlined,
            )
          else
            Column(
              children: employee.documents
                  .map((document) => _DocumentTile(document: document))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Future<void> _showUploadSourceSheet(
    BuildContext context,
    EmployeeDocumentType type,
  ) async {
    final source = await showModalBottomSheet<EmployeeDocumentSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              runSpacing: 8,
              children: EmployeeDocumentSource.values
                  .map(
                    (source) => ListTile(
                      leading: Icon(source.icon),
                      title: Text(source.label),
                      onTap: () => Navigator.of(context).pop(source),
                    ),
                  )
                  .toList(),
            ),
          ),
        );
      },
    );
    if (source == null) {
      return;
    }
    onUploadDocument(type, source);
  }
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({required this.document});

  final EmployeeProfileDocument document;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: document.type.color.withValues(alpha: 0.12),
        child: Icon(document.type.icon, color: document.type.color),
      ),
      title: Text(document.title),
      subtitle: Text(
        '${document.fileName} - ${document.source.label} - ${document.sizeLabel}',
      ),
      trailing: document.hasOcrSuggestions
          ? const Tooltip(
              message: 'تم استخراج بيانات قابلة للمراجعة',
              child: Icon(
                Icons.auto_fix_high_outlined,
                color: Color(0xFF2563EB),
              ),
            )
          : null,
    );
  }
}

class _CvProfileCard extends StatelessWidget {
  const _CvProfileCard({
    required this.employee,
    required this.isBusy,
    required this.onEditCv,
    required this.onUploadCvPdf,
    required this.onAutofillCv,
    required this.onRegenerateCvSummary,
  });

  final ManagerEmployeeProfile employee;
  final bool isBusy;
  final VoidCallback onEditCv;
  final VoidCallback onUploadCvPdf;
  final VoidCallback onAutofillCv;
  final VoidCallback onRegenerateCvSummary;

  @override
  Widget build(BuildContext context) {
    final cv = employee.cvProfile;
    return _HistoryCard(
      title: 'السيرة الذاتية',
      icon: Icons.description_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                onPressed: isBusy ? null : onEditCv,
                icon: const Icon(Icons.edit_note_outlined),
                label: const Text('إدخال يدوي'),
              ),
              OutlinedButton.icon(
                onPressed: isBusy ? null : onUploadCvPdf,
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('رفع PDF'),
              ),
              OutlinedButton.icon(
                onPressed: isBusy ? null : onAutofillCv,
                icon: const Icon(Icons.auto_fix_high_outlined),
                label: const Text('تعبئة تلقائية من الملف'),
              ),
              OutlinedButton.icon(
                onPressed: isBusy ? null : onRegenerateCvSummary,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('إعادة توليد الملخص'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!cv.hasManualData && !cv.hasPdf)
            const AppEmptyState(
              title: 'لا توجد سيرة ذاتية بعد',
              message: 'يمكن إدخال السيرة يدوياً أو رفع ملف PDF كمرجع.',
              icon: Icons.description_outlined,
            )
          else ...[
            if (cv.pdfDocument != null)
              _DocumentTile(document: cv.pdfDocument!),
            if (cv.professionalSummary.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              _SectionBlock(
                title: 'الملخص المهني',
                child: Text(cv.professionalSummary),
              ),
            ],
            if (cv.skills.isNotEmpty) ...[
              const SizedBox(height: 12),
              _SectionBlock(
                title: 'المهارات',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: cv.skills
                      .map((skill) => Chip(label: Text(skill)))
                      .toList(),
                ),
              ),
            ],
            _CvItemsBlock(title: 'الخبرات العملية', items: cv.experience),
            _CvItemsBlock(title: 'الشهادات', items: cv.education),
            _CvItemsBlock(title: 'الدورات', items: cv.courses),
          ],
        ],
      ),
    );
  }
}

class _SectionBlock extends StatelessWidget {
  const _SectionBlock({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDE6F3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _CvItemsBlock extends StatelessWidget {
  const _CvItemsBlock({required this.title, required this.items});

  final String title;
  final List<EmployeeCvItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: _SectionBlock(
        title: title,
        child: Column(
          children: items
              .map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.title),
                  subtitle: Text(
                    [
                      item.organization,
                      item.period,
                      item.description,
                    ].where((value) => value.trim().isNotEmpty).join(' - '),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _AdministrativeRecordsCard extends StatelessWidget {
  const _AdministrativeRecordsCard({
    required this.employee,
    required this.isBusy,
    required this.onAddRecord,
  });

  final ManagerEmployeeProfile employee;
  final bool isBusy;
  final VoidCallback onAddRecord;

  @override
  Widget build(BuildContext context) {
    return _HistoryCard(
      title: 'السجل الإداري',
      icon: Icons.gavel_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ElevatedButton.icon(
              onPressed: isBusy ? null : onAddRecord,
              icon: const Icon(Icons.add_rounded),
              label: const Text('إضافة سجل'),
            ),
          ),
          const SizedBox(height: 16),
          if (employee.administrativeRecords.isEmpty)
            const AppEmptyState(
              title: 'لا توجد سجلات إدارية',
              message: 'أضف الواردات والصادرات والقرارات والبرقيات الخاصة به.',
              icon: Icons.gavel_outlined,
            )
          else
            Column(
              children: employee.administrativeRecords
                  .map((record) => _AdministrativeRecordTile(record: record))
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _AdministrativeRecordTile extends StatelessWidget {
  const _AdministrativeRecordTile({required this.record});

  final EmployeeAdministrativeRecord record;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(child: Icon(record.category.icon)),
      title: Text(record.title),
      subtitle: Text(
        [
          record.category.label,
          record.recordDate,
          record.referenceNumber,
        ].where((value) => value.trim().isNotEmpty).join(' - '),
      ),
      trailing: record.document == null
          ? null
          : const Tooltip(
              message: 'يوجد مرفق',
              child: Icon(Icons.attach_file_rounded),
            ),
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
            _InfoRow(label: 'السوية الوظيفية', value: employee.jobLevel.label),
            _InfoRow(label: 'المسمى الوظيفي', value: employee.jobTitle),
            _InfoRow(label: 'القسم', value: employee.department),
            _InfoRow(label: 'البريد الإلكتروني', value: employee.email),
            _InfoRow(label: 'الهاتف', value: employee.phone),
            _InfoRow(
              label: 'تاريخ الميلاد',
              value: employee.birthDate.isEmpty ? '--' : employee.birthDate,
            ),
            _InfoRow(
              label: 'رقم الهوية',
              value: employee.identityNumber.isEmpty
                  ? '--'
                  : employee.identityNumber,
            ),
            _InfoRow(
              label: 'مكان القيد / الإصدار',
              value: employee.identityPlace.isEmpty
                  ? '--'
                  : employee.identityPlace,
            ),
            _InfoRow(
              label: 'تاريخ إصدار الهوية',
              value: employee.identityIssueDate.isEmpty
                  ? '--'
                  : employee.identityIssueDate,
            ),
            _InfoRow(
              label: 'تاريخ انتهاء الهوية',
              value: employee.identityExpiryDate.isEmpty
                  ? '--'
                  : employee.identityExpiryDate,
            ),
            _InfoRow(
              label: 'الجنسية',
              value: employee.nationality.isEmpty ? '--' : employee.nationality,
            ),
            _InfoRow(
              label: 'حساب شام كاش',
              value: employee.shamCashAccount.isEmpty
                  ? '--'
                  : employee.shamCashAccount,
            ),
            _InfoRow(
              label: 'العنوان',
              value: employee.address.isEmpty ? '--' : employee.address,
            ),
            _InfoRow(
              label: 'رقم الطوارئ',
              value: employee.emergencyContact.isEmpty
                  ? '--'
                  : employee.emergencyContact,
            ),
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
