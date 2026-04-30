import 'package:flutter/material.dart';

import '../../../manager/domain/models/manager_broadcast_recipient.dart';

class ManagerBroadcastDraft {
  const ManagerBroadcastDraft({
    required this.title,
    required this.message,
    required this.audienceType,
    required this.recipientIds,
  });

  final String title;
  final String message;
  final String audienceType;
  final List<int> recipientIds;
}

Future<ManagerBroadcastDraft?> showManagerBroadcastDialog(
  BuildContext context, {
  String? initialTitle,
  String? initialMessage,
  String initialAudienceType = 'all',
  List<int> initialRecipientIds = const [],
  List<ManagerBroadcastRecipient> recipientOptions = const [],
}) {
  return showDialog<ManagerBroadcastDraft>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ManagerBroadcastDialog(
      initialTitle: initialTitle,
      initialMessage: initialMessage,
      initialAudienceType: initialAudienceType,
      initialRecipientIds: initialRecipientIds,
      recipientOptions: recipientOptions,
    ),
  );
}

class _ManagerBroadcastDialog extends StatefulWidget {
  const _ManagerBroadcastDialog({
    this.initialTitle,
    this.initialMessage,
    required this.initialAudienceType,
    required this.initialRecipientIds,
    required this.recipientOptions,
  });

  final String? initialTitle;
  final String? initialMessage;
  final String initialAudienceType;
  final List<int> initialRecipientIds;
  final List<ManagerBroadcastRecipient> recipientOptions;

  @override
  State<_ManagerBroadcastDialog> createState() =>
      _ManagerBroadcastDialogState();
}

class _ManagerBroadcastDialogState extends State<_ManagerBroadcastDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _messageController;
  late final TextEditingController _searchController;

  late String _audienceType;
  late Set<int> _selectedRecipientIds;
  String _searchQuery = '';
  bool _showRecipientError = false;

  bool get _isEdit => (widget.initialTitle?.isNotEmpty ?? false);
  bool get _isCustomAudience => _audienceType == 'custom';

  List<ManagerBroadcastRecipient> get _filteredRecipients {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return widget.recipientOptions;
    }

    return widget.recipientOptions.where((recipient) {
      return recipient.name.toLowerCase().contains(query) ||
          recipient.code.toLowerCase().contains(query) ||
          recipient.department.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _messageController = TextEditingController(
      text: widget.initialMessage ?? '',
    );
    _searchController = TextEditingController();
    _audienceType = widget.initialAudienceType;
    _selectedRecipientIds = widget.initialRecipientIds.toSet();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'تعديل الرسالة' : 'رسالة جماعية'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'العنوان',
                    prefixIcon: Icon(Icons.title_rounded),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'أدخل عنوان الرسالة';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _messageController,
                  minLines: 4,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'محتوى الرسالة',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.campaign_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'أدخل محتوى الرسالة';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                Text(
                  'المستلمون',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ChoiceChip(
                      label: const Text('إرسال للجميع'),
                      selected: _audienceType == 'all',
                      onSelected: (_) {
                        setState(() {
                          _audienceType = 'all';
                          _showRecipientError = false;
                        });
                      },
                    ),
                    ChoiceChip(
                      label: const Text('تحديد يدوي'),
                      selected: _audienceType == 'custom',
                      onSelected: (_) {
                        setState(() {
                          _audienceType = 'custom';
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: _isCustomAudience
                      ? _RecipientSelector(
                          key: const ValueKey('custom'),
                          searchController: _searchController,
                          recipients: _filteredRecipients,
                          selectedRecipientIds: _selectedRecipientIds,
                          showRecipientError: _showRecipientError,
                          totalSelectedCount: _selectedRecipientIds.length,
                          onSearchChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                          onRecipientToggle: _toggleRecipient,
                        )
                      : Container(
                          key: const ValueKey('all'),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Text(
                            'سيتم إرسال الرسالة إلى جميع الموظفين وموارد HR النشطة.',
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        ElevatedButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.send_rounded),
          label: Text(_isEdit ? 'حفظ التعديل' : 'إرسال'),
        ),
      ],
    );
  }

  void _toggleRecipient(int recipientId, bool selected) {
    setState(() {
      if (selected) {
        _selectedRecipientIds.add(recipientId);
      } else {
        _selectedRecipientIds.remove(recipientId);
      }
      _showRecipientError = false;
    });
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    if (_isCustomAudience && _selectedRecipientIds.isEmpty) {
      setState(() {
        _showRecipientError = true;
      });
      return;
    }

    Navigator.of(context).pop(
      ManagerBroadcastDraft(
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
        audienceType: _audienceType,
        recipientIds: _selectedRecipientIds.toList()..sort(),
      ),
    );
  }
}

class _RecipientSelector extends StatelessWidget {
  const _RecipientSelector({
    super.key,
    required this.searchController,
    required this.recipients,
    required this.selectedRecipientIds,
    required this.showRecipientError,
    required this.totalSelectedCount,
    required this.onSearchChanged,
    required this.onRecipientToggle,
  });

  final TextEditingController searchController;
  final List<ManagerBroadcastRecipient> recipients;
  final Set<int> selectedRecipientIds;
  final bool showRecipientError;
  final int totalSelectedCount;
  final ValueChanged<String> onSearchChanged;
  final void Function(int recipientId, bool selected) onRecipientToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: searchController,
          decoration: const InputDecoration(
            hintText: 'ابحث بالاسم أو الرقم الوظيفي',
            prefixIcon: Icon(Icons.search_rounded),
          ),
          onChanged: onSearchChanged,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Text(
              'تم اختيار $totalSelectedCount',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          constraints: const BoxConstraints(maxHeight: 260),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: showRecipientError
                  ? const Color(0xFFDC2626)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: recipients.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('لا يوجد مستلمون مطابقون للبحث الحالي.'),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: recipients.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final recipient = recipients[index];
                    final isSelected = selectedRecipientIds.contains(
                      recipient.id,
                    );
                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (value) =>
                          onRecipientToggle(recipient.id, value ?? false),
                      title: Text(recipient.name),
                      subtitle: Text(recipient.subtitle),
                      secondary: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: recipient.isHr
                              ? const Color(0xFFEDE9FE)
                              : const Color(0xFFDBEAFE),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          recipient.roleLabel,
                          style: TextStyle(
                            color: recipient.isHr
                                ? const Color(0xFF6D28D9)
                                : const Color(0xFF1D4ED8),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                    );
                  },
                ),
        ),
        if (showRecipientError) ...[
          const SizedBox(height: 8),
          const Text(
            'اختر مستلمًا واحدًا على الأقل.',
            style: TextStyle(
              color: Color(0xFFDC2626),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}
