class ReportExportFilter {
  const ReportExportFilter({
    required this.dateFrom,
    required this.dateTo,
    this.department,
    this.managerId,
    this.status = 'all',
  });

  final DateTime dateFrom;
  final DateTime dateTo;
  final String? department;
  final int? managerId;
  final String status;

  factory ReportExportFilter.currentMonth({String status = 'all'}) {
    final now = DateTime.now();
    return ReportExportFilter(
      dateFrom: DateTime(now.year, now.month, 1),
      dateTo: DateTime(now.year, now.month, now.day),
      status: status,
    );
  }

  ReportExportFilter copyWith({
    DateTime? dateFrom,
    DateTime? dateTo,
    String? department,
    int? managerId,
    String? status,
    bool clearDepartment = false,
    bool clearManager = false,
  }) {
    return ReportExportFilter(
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      department: clearDepartment ? null : (department ?? this.department),
      managerId: clearManager ? null : (managerId ?? this.managerId),
      status: status ?? this.status,
    );
  }

  Map<String, String> toQueryParameters() {
    return {
      'date_from': _formatDate(dateFrom),
      'date_to': _formatDate(dateTo),
      'status': status,
      if (department != null && department!.trim().isNotEmpty)
        'department': department!.trim(),
      if (managerId != null) 'manager_id': '$managerId',
    };
  }

  static String _formatDate(DateTime value) {
    final normalized = DateTime(value.year, value.month, value.day);
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '${normalized.year}-$month-$day';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is ReportExportFilter &&
        other.dateFrom.year == dateFrom.year &&
        other.dateFrom.month == dateFrom.month &&
        other.dateFrom.day == dateFrom.day &&
        other.dateTo.year == dateTo.year &&
        other.dateTo.month == dateTo.month &&
        other.dateTo.day == dateTo.day &&
        other.department == department &&
        other.managerId == managerId &&
        other.status == status;
  }

  @override
  int get hashCode => Object.hash(
    dateFrom.year,
    dateFrom.month,
    dateFrom.day,
    dateTo.year,
    dateTo.month,
    dateTo.day,
    department,
    managerId,
    status,
  );
}
