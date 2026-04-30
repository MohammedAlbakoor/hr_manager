import 'package:flutter/material.dart';

import '../../../../core/utils/arabic_date_time_formatter.dart';
import '../../../common/presentation/widgets/app_empty_state.dart';
import '../../../common/presentation/widgets/app_error_state.dart';
import '../../../common/presentation/widgets/app_loading_state.dart';
import '../../../manager/domain/models/employee_manager_option.dart';
import '../../domain/models/report_table_models.dart';
import '../models/report_workspace_state.dart';

class ReportFilterOption {
  const ReportFilterOption(this.value, this.label);

  final String value;
  final String label;
}

class ReportWorkspaceView extends StatelessWidget {
  const ReportWorkspaceView({
    super.key,
    required this.workspace,
    required this.displayedRows,
    required this.departments,
    required this.managers,
    required this.statusItems,
    required this.searchController,
    required this.onDatePressed,
    required this.onDepartmentChanged,
    required this.onManagerChanged,
    required this.onStatusChanged,
    required this.onApplyFilters,
    required this.onResetFilters,
    required this.onSearchChanged,
    required this.onSort,
    required this.onManageColumns,
    required this.onResetLayout,
    required this.onExport,
    required this.onRetry,
  });

  final ReportWorkspaceState workspace;
  final List<ReportTableRow> displayedRows;
  final List<String> departments;
  final List<EmployeeManagerOption> managers;
  final List<ReportFilterOption> statusItems;
  final TextEditingController searchController;
  final ValueChanged<bool> onDatePressed;
  final ValueChanged<String?> onDepartmentChanged;
  final ValueChanged<int?> onManagerChanged;
  final ValueChanged<String> onStatusChanged;
  final Future<void> Function() onApplyFilters;
  final Future<void> Function() onResetFilters;
  final ValueChanged<String> onSearchChanged;
  final void Function(String columnId, bool ascending) onSort;
  final VoidCallback onManageColumns;
  final VoidCallback onResetLayout;
  final Future<void> Function() onExport;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      children: [
        _FilterCard(
          workspace: workspace,
          departments: departments,
          managers: managers,
          statusItems: statusItems,
          onDatePressed: onDatePressed,
          onDepartmentChanged: onDepartmentChanged,
          onManagerChanged: onManagerChanged,
          onStatusChanged: onStatusChanged,
          onApplyFilters: onApplyFilters,
          onResetFilters: onResetFilters,
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _StatChip(
              icon: Icons.table_rows_outlined,
              label: 'الصفوف المعروضة',
              value: '${displayedRows.length}',
            ),
            _StatChip(
              icon: Icons.dataset_outlined,
              label: 'كل الصفوف',
              value: '${workspace.rows.length}',
            ),
            _StatChip(
              icon: Icons.view_column_outlined,
              label: 'الأعمدة الظاهرة',
              value: '${workspace.visibleColumns.length}',
            ),
            if (workspace.hasPendingFilterChanges) const _PendingChip(),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 320,
                    child: TextField(
                      controller: searchController,
                      onChanged: onSearchChanged,
                      decoration: InputDecoration(
                        labelText: 'بحث داخل الجدول الحالي',
                        hintText: 'اسم الموظف، الرمز، الحالة...',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: workspace.searchQuery.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  searchController.clear();
                                  onSearchChanged('');
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: onManageColumns,
                    icon: const Icon(Icons.swap_horiz_rounded),
                    label: const Text('ترتيب الأعمدة'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onResetLayout,
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: const Text('إعادة ضبط الأعمدة'),
                  ),
                  ElevatedButton.icon(
                    onPressed: workspace.isExporting ? null : onExport,
                    icon: workspace.isExporting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download_rounded),
                    label: Text(
                      workspace.isExporting
                          ? 'جارٍ التصدير...'
                          : 'تصدير الشكل الحالي',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (workspace.errorMessage != null &&
                  workspace.rows.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Color(0xFFB91C1C),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(workspace.errorMessage!)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
              _ReportTable(
                workspace: workspace,
                displayedRows: displayedRows,
                onSort: onSort,
                onRetry: onRetry,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterCard extends StatelessWidget {
  const _FilterCard({
    required this.workspace,
    required this.departments,
    required this.managers,
    required this.statusItems,
    required this.onDatePressed,
    required this.onDepartmentChanged,
    required this.onManagerChanged,
    required this.onStatusChanged,
    required this.onApplyFilters,
    required this.onResetFilters,
  });

  final ReportWorkspaceState workspace;
  final List<String> departments;
  final List<EmployeeManagerOption> managers;
  final List<ReportFilterOption> statusItems;
  final ValueChanged<bool> onDatePressed;
  final ValueChanged<String?> onDepartmentChanged;
  final ValueChanged<int?> onManagerChanged;
  final ValueChanged<String> onStatusChanged;
  final Future<void> Function() onApplyFilters;
  final Future<void> Function() onResetFilters;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fieldWidth = constraints.maxWidth >= 920
              ? (constraints.maxWidth - 24) / 3
              : constraints.maxWidth;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'فلاتر ${workspace.type.title}',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                'غيّر مدخلات الفلترة ثم اضغط "تطبيق الفلاتر" لتحديث الجدول.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: fieldWidth,
                    child: _DateField(
                      label: 'من تاريخ',
                      value: ArabicDateTimeFormatter.date(
                        workspace.filter.dateFrom,
                      ),
                      onTap: () => onDatePressed(true),
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: _DateField(
                      label: 'إلى تاريخ',
                      value: ArabicDateTimeFormatter.date(
                        workspace.filter.dateTo,
                      ),
                      onTap: () => onDatePressed(false),
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: DropdownButtonFormField<String?>(
                      key: ValueKey(
                        'department-${workspace.type.name}-${workspace.filter.department ?? 'all'}',
                      ),
                      initialValue: workspace.filter.department,
                      decoration: const InputDecoration(
                        labelText: 'القسم',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('كل الأقسام'),
                        ),
                        ...departments.map(
                          (department) => DropdownMenuItem<String?>(
                            value: department,
                            child: Text(department),
                          ),
                        ),
                      ],
                      onChanged: onDepartmentChanged,
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: DropdownButtonFormField<int?>(
                      key: ValueKey(
                        'manager-${workspace.type.name}-${workspace.filter.managerId ?? 0}',
                      ),
                      initialValue: workspace.filter.managerId,
                      decoration: const InputDecoration(
                        labelText: 'المدير',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('كل المدراء'),
                        ),
                        ...managers.map(
                          (manager) => DropdownMenuItem<int?>(
                            value: manager.id,
                            child: Text(manager.displayLabel),
                          ),
                        ),
                      ],
                      onChanged: onManagerChanged,
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: DropdownButtonFormField<String>(
                      key: ValueKey(
                        'status-${workspace.type.name}-${workspace.filter.status}',
                      ),
                      initialValue: workspace.filter.status,
                      decoration: const InputDecoration(
                        labelText: 'الحالة',
                        border: OutlineInputBorder(),
                      ),
                      items: statusItems
                          .map(
                            (option) => DropdownMenuItem<String>(
                              value: option.value,
                              child: Text(option.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          onStatusChanged(value);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ElevatedButton.icon(
                    onPressed: workspace.isLoading ? null : onApplyFilters,
                    icon: workspace.isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.filter_alt_rounded),
                    label: Text(
                      workspace.isLoading ? 'جارٍ التحديث...' : 'تطبيق الفلاتر',
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: workspace.isLoading ? null : onResetFilters,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('إعادة ضبط الفلاتر'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ReportTable extends StatefulWidget {
  const _ReportTable({
    required this.workspace,
    required this.displayedRows,
    required this.onSort,
    required this.onRetry,
  });

  final ReportWorkspaceState workspace;
  final List<ReportTableRow> displayedRows;
  final void Function(String columnId, bool ascending) onSort;
  final Future<void> Function() onRetry;

  @override
  State<_ReportTable> createState() => _ReportTableState();
}

class _ReportTableState extends State<_ReportTable> {
  late final ScrollController _horizontalScrollController = ScrollController();
  ReportWorkspaceState get workspace => widget.workspace;
  List<ReportTableRow> get displayedRows => widget.displayedRows;
  void Function(String columnId, bool ascending) get onSort => widget.onSort;
  Future<void> Function() get onRetry => widget.onRetry;

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.workspace.isLoading && widget.workspace.rows.isEmpty) {
      return SizedBox(
        height: 260,
        child: AppLoadingState(
          title: 'جارٍ تحميل جدول ${workspace.type.title}',
          message: 'نجهز الصفوف الحالية بناءً على الفلاتر المحددة.',
        ),
      );
    }

    if (widget.workspace.errorMessage != null &&
        widget.workspace.rows.isEmpty) {
      return SizedBox(
        height: 260,
        child: AppErrorState(
          title: 'تعذر تحميل الجدول',
          message: widget.workspace.errorMessage!,
          onRetry: widget.onRetry,
        ),
      );
    }

    if (widget.displayedRows.isEmpty) {
      return const SizedBox(
        height: 260,
        child: AppEmptyState(
          title: 'لا توجد نتائج',
          message: 'لا توجد صفوف مطابقة للفلاتر أو البحث الحالي.',
          icon: Icons.table_rows_outlined,
        ),
      );
    }

    final visibleColumns = widget.workspace.visibleColumns;
    final sortColumnIndex = widget.workspace.sortColumnId == null
        ? null
        : visibleColumns.indexWhere(
            (column) => column.id == widget.workspace.sortColumnId,
          );

    return Scrollbar(
      controller: _horizontalScrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _horizontalScrollController,
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: visibleColumns.fold<double>(
              0,
              (total, column) => total + _columnWidth(column.id),
            ),
          ),
          child: DataTable(
            sortColumnIndex: sortColumnIndex != null && sortColumnIndex >= 0
                ? sortColumnIndex
                : null,
            sortAscending: widget.workspace.sortAscending,
            columnSpacing: 18,
            columns: visibleColumns
                .map(
                  (column) => DataColumn(
                    label: SizedBox(
                      width: _columnWidth(column.id),
                      child: Text(
                        column.label,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    onSort: (_, ascending) =>
                        widget.onSort(column.id, ascending),
                  ),
                )
                .toList(),
            rows: widget.displayedRows
                .map(
                  (row) => DataRow(
                    cells: visibleColumns
                        .map(
                          (column) => DataCell(
                            SizedBox(
                              width: _columnWidth(column.id),
                              child: Text(
                                row.valueFor(column.id),
                                maxLines: column.id.contains('note') ? 2 : 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  double _columnWidth(String columnId) {
    switch (columnId) {
      case 'employee_name':
      case 'department':
      case 'manager_name':
      case 'leave_type_name':
        return 170;
      case 'manager_note':
      case 'hr_note':
      case 'note':
      case 'location_label':
        return 220;
      default:
        return 130;
    }
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_month_outlined),
        ),
        child: Text(value),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF0F766E)),
          const SizedBox(width: 8),
          Text('$label: $value'),
        ],
      ),
    );
  }
}

class _PendingChip extends StatelessWidget {
  const _PendingChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.pending_actions_outlined,
            size: 18,
            color: Color(0xFFB45309),
          ),
          SizedBox(width: 8),
          Text('يوجد تعديل على الفلاتر لم يُطبّق بعد'),
        ],
      ),
    );
  }
}
