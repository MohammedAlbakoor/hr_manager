import '../../domain/models/report_export_filter.dart';
import '../../domain/models/report_table_models.dart';

class ReportWorkspaceState {
  const ReportWorkspaceState({
    required this.type,
    required this.filter,
    required this.appliedFilter,
    required this.columns,
    this.rows = const [],
    this.searchQuery = '',
    this.sortColumnId,
    this.sortAscending = true,
    this.isLoading = false,
    this.isExporting = false,
    this.errorMessage,
  });

  factory ReportWorkspaceState.initial(ReportTableType type) {
    final filter = ReportExportFilter.currentMonth();
    return ReportWorkspaceState(
      type: type,
      filter: filter,
      appliedFilter: filter,
      columns: ReportTableDefaults.columnsFor(type),
    );
  }

  final ReportTableType type;
  final ReportExportFilter filter;
  final ReportExportFilter appliedFilter;
  final List<ReportTableColumn> columns;
  final List<ReportTableRow> rows;
  final String searchQuery;
  final String? sortColumnId;
  final bool sortAscending;
  final bool isLoading;
  final bool isExporting;
  final String? errorMessage;

  List<ReportTableColumn> get visibleColumns =>
      columns.where((column) => column.isVisible).toList();

  bool get hasPendingFilterChanges => filter != appliedFilter;

  ReportWorkspaceState copyWith({
    ReportTableType? type,
    ReportExportFilter? filter,
    ReportExportFilter? appliedFilter,
    List<ReportTableColumn>? columns,
    List<ReportTableRow>? rows,
    String? searchQuery,
    String? sortColumnId,
    bool clearSortColumn = false,
    bool? sortAscending,
    bool? isLoading,
    bool? isExporting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ReportWorkspaceState(
      type: type ?? this.type,
      filter: filter ?? this.filter,
      appliedFilter: appliedFilter ?? this.appliedFilter,
      columns: columns ?? this.columns,
      rows: rows ?? this.rows,
      searchQuery: searchQuery ?? this.searchQuery,
      sortColumnId: clearSortColumn
          ? null
          : (sortColumnId ?? this.sortColumnId),
      sortAscending: sortAscending ?? this.sortAscending,
      isLoading: isLoading ?? this.isLoading,
      isExporting: isExporting ?? this.isExporting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
