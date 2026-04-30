class ReportTableCell {
  const ReportTableCell({required this.value, Object? sortValue})
    : sortValue = sortValue ?? value;

  final String value;
  final Object sortValue;
}

class ReportTableRow {
  const ReportTableRow({required this.id, required this.cells});

  final String id;
  final Map<String, ReportTableCell> cells;

  String valueFor(String columnId) => cells[columnId]?.value ?? '--';

  Object sortValueFor(String columnId) =>
      cells[columnId]?.sortValue ?? valueFor(columnId);

  bool matchesQuery(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return true;
    }

    return cells.values.any(
      (cell) => cell.value.toLowerCase().contains(normalized),
    );
  }
}

class ReportTableColumn {
  const ReportTableColumn({
    required this.id,
    required this.label,
    this.isVisible = true,
  });

  final String id;
  final String label;
  final bool isVisible;

  ReportTableColumn copyWith({String? id, String? label, bool? isVisible}) {
    return ReportTableColumn(
      id: id ?? this.id,
      label: label ?? this.label,
      isVisible: isVisible ?? this.isVisible,
    );
  }
}

enum ReportTableType {
  attendance(title: 'الحضور', exportPrefix: 'attendance_view'),
  leaves(title: 'الإجازات', exportPrefix: 'leaves_view');

  const ReportTableType({required this.title, required this.exportPrefix});

  final String title;
  final String exportPrefix;
}

class ReportTableDefaults {
  static List<ReportTableColumn> columnsFor(ReportTableType type) {
    switch (type) {
      case ReportTableType.attendance:
        return const [
          ReportTableColumn(id: 'date', label: 'التاريخ'),
          ReportTableColumn(id: 'employee_code', label: 'رمز الموظف'),
          ReportTableColumn(id: 'employee_name', label: 'اسم الموظف'),
          ReportTableColumn(id: 'department', label: 'القسم'),
          ReportTableColumn(id: 'manager_name', label: 'المدير المباشر'),
          ReportTableColumn(id: 'status_label', label: 'الحالة'),
          ReportTableColumn(id: 'check_in_label', label: 'وقت الدخول'),
          ReportTableColumn(id: 'method', label: 'طريقة التسجيل'),
          ReportTableColumn(
            id: 'location_label',
            label: 'موقع العمل',
            isVisible: false,
          ),
          ReportTableColumn(id: 'note', label: 'ملاحظة', isVisible: false),
        ];
      case ReportTableType.leaves:
        return const [
          ReportTableColumn(id: 'request_date', label: 'تاريخ الطلب'),
          ReportTableColumn(id: 'employee_code', label: 'رمز الموظف'),
          ReportTableColumn(id: 'employee_name', label: 'اسم الموظف'),
          ReportTableColumn(id: 'department', label: 'القسم'),
          ReportTableColumn(
            id: 'manager_name',
            label: 'المدير المباشر',
            isVisible: false,
          ),
          ReportTableColumn(id: 'leave_type_name', label: 'نوع الإجازة'),
          ReportTableColumn(id: 'start_date', label: 'من تاريخ'),
          ReportTableColumn(id: 'end_date', label: 'إلى تاريخ'),
          ReportTableColumn(id: 'days_count', label: 'عدد الأيام'),
          ReportTableColumn(id: 'status_label', label: 'الحالة'),
          ReportTableColumn(id: 'manager_status_label', label: 'قرار المدير'),
          ReportTableColumn(
            id: 'manager_note',
            label: 'ملاحظة المدير',
            isVisible: false,
          ),
          ReportTableColumn(
            id: 'hr_note',
            label: 'ملاحظة HR',
            isVisible: false,
          ),
          ReportTableColumn(
            id: 'current_balance',
            label: 'الرصيد الحالي',
            isVisible: false,
          ),
          ReportTableColumn(
            id: 'remaining_balance',
            label: 'الرصيد المتبقي',
            isVisible: false,
          ),
          ReportTableColumn(
            id: 'note',
            label: 'ملاحظة الطلب',
            isVisible: false,
          ),
        ];
    }
  }
}
