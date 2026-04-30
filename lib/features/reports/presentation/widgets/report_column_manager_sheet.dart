import 'package:flutter/material.dart';

import '../../domain/models/report_table_models.dart';

class ReportColumnManagerSheet extends StatefulWidget {
  const ReportColumnManagerSheet({
    super.key,
    required this.title,
    required this.initialColumns,
    required this.defaultColumns,
  });

  final String title;
  final List<ReportTableColumn> initialColumns;
  final List<ReportTableColumn> defaultColumns;

  @override
  State<ReportColumnManagerSheet> createState() =>
      _ReportColumnManagerSheetState();
}

class _ReportColumnManagerSheetState extends State<ReportColumnManagerSheet> {
  late List<ReportTableColumn> _draftColumns = widget.initialColumns
      .map((column) => column.copyWith())
      .toList();

  void _toggleColumn(String columnId, bool isVisible) {
    final visibleCount = _draftColumns
        .where((column) => column.isVisible)
        .length;
    if (!isVisible && visibleCount == 1) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('يجب إبقاء عمود واحد ظاهر على الأقل.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

    setState(() {
      _draftColumns = _draftColumns
          .map(
            (column) => column.id == columnId
                ? column.copyWith(isVisible: isVisible)
                : column,
          )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.88,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'إدارة أعمدة ${widget.title}',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'اسحب لتغيير ترتيب العمود، واستخدم المفتاح لإظهاره أو إخفائه. هذا التعديل محلي على شكل التقرير فقط.',
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ReorderableListView.builder(
                itemCount: _draftColumns.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) {
                      newIndex -= 1;
                    }
                    final item = _draftColumns.removeAt(oldIndex);
                    _draftColumns.insert(newIndex, item);
                  });
                },
                itemBuilder: (context, index) {
                  final column = _draftColumns[index];
                  return ListTile(
                    key: ValueKey(column.id),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    leading: ReorderableDragStartListener(
                      index: index,
                      child: const Icon(Icons.drag_indicator_rounded),
                    ),
                    title: Text(column.label),
                    subtitle: Text(column.id),
                    trailing: Switch(
                      value: column.isVisible,
                      onChanged: (value) => _toggleColumn(column.id, value),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _draftColumns = widget.defaultColumns
                          .map((column) => column.copyWith())
                          .toList();
                    });
                  },
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: const Text('الوضع الافتراضي'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(_draftColumns),
                  child: const Text('اعتماد الشكل'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
