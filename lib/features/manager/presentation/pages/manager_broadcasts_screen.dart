import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/services/app_services.dart';
import '../../../common/domain/models/app_user_role.dart';
import '../../../common/presentation/widgets/app_empty_state.dart';
import '../../../common/presentation/widgets/app_error_state.dart';
import '../../../common/presentation/widgets/app_loading_state.dart';
import '../../../common/presentation/widgets/manager_broadcast_dialog.dart';
import '../../../common/presentation/widgets/role_bottom_navigation_bar.dart';
import '../../domain/models/manager_broadcast_message.dart';
import '../../domain/models/manager_broadcast_recipient.dart';

class ManagerBroadcastsScreen extends StatefulWidget {
  const ManagerBroadcastsScreen({super.key});

  @override
  State<ManagerBroadcastsScreen> createState() =>
      _ManagerBroadcastsScreenState();
}

class _ManagerBroadcastsScreenState extends State<ManagerBroadcastsScreen> {
  List<ManagerBroadcastMessage> _broadcasts = const [];
  List<ManagerBroadcastRecipient> _recipientOptions = const [];
  bool _isLoading = true;
  bool _isCreating = false;
  String? _busyId;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        AppServices.managerBroadcastRepository.fetchBroadcasts(),
        AppServices.managerBroadcastRepository.fetchRecipientOptions(),
      ]);
      if (!mounted) {
        return;
      }
      setState(() {
        _broadcasts = results[0] as List<ManagerBroadcastMessage>;
        _recipientOptions = results[1] as List<ManagerBroadcastRecipient>;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = _message(error, 'تعذر تحميل الرسائل الجماعية حاليًا.');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createBroadcast() async {
    if (_isCreating) {
      return;
    }

    final draft = await showManagerBroadcastDialog(
      context,
      recipientOptions: _recipientOptions,
    );
    if (draft == null) {
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final created = await AppServices.managerBroadcastRepository
          .createBroadcast(
            title: draft.title,
            message: draft.message,
            audienceType: draft.audienceType,
            recipientIds: draft.recipientIds,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _broadcasts = [created, ..._broadcasts];
      });
      _showSnack('تم إرسال الرسالة وحفظها في صفحة الرسائل الجماعية.');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showSnack(_message(error, 'تعذر إرسال الرسالة حاليًا.'));
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  Future<void> _editBroadcast(ManagerBroadcastMessage broadcast) async {
    if (_busyId != null) {
      return;
    }

    final draft = await showManagerBroadcastDialog(
      context,
      initialTitle: broadcast.title,
      initialMessage: broadcast.message,
      initialAudienceType: broadcast.audienceType,
      initialRecipientIds: broadcast.recipientIds,
      recipientOptions: _recipientOptions,
    );
    if (draft == null) {
      return;
    }

    setState(() {
      _busyId = broadcast.id;
    });

    try {
      final updated = await AppServices.managerBroadcastRepository
          .updateBroadcast(
            broadcastId: broadcast.id,
            title: draft.title,
            message: draft.message,
            audienceType: draft.audienceType,
            recipientIds: draft.recipientIds,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _broadcasts = _broadcasts
            .map((item) => item.id == updated.id ? updated : item)
            .toList();
      });
      _showSnack('تم تحديث الرسالة الجماعية.');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showSnack(_message(error, 'تعذر تحديث الرسالة حاليًا.'));
    } finally {
      if (mounted) {
        setState(() {
          _busyId = null;
        });
      }
    }
  }

  Future<void> _deleteBroadcast(ManagerBroadcastMessage broadcast) async {
    if (_busyId != null) {
      return;
    }

    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('حذف الرسالة'),
              content: Text(
                'سيتم حذف "${broadcast.title}" وإزالته من إشعارات المستلمين.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('حذف'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    setState(() {
      _busyId = broadcast.id;
    });

    try {
      await AppServices.managerBroadcastRepository.deleteBroadcast(
        broadcast.id,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _broadcasts = _broadcasts
            .where((item) => item.id != broadcast.id)
            .toList();
      });
      _showSnack('تم حذف الرسالة الجماعية.');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showSnack(_message(error, 'تعذر حذف الرسالة حاليًا.'));
    } finally {
      if (mounted) {
        setState(() {
          _busyId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: RoleBottomNavigationBar(
        role: AppUserRole.manager,
        selectedIndex: 3,
        onDestinationSelected: _onPrimaryNavigation,
      ),
      appBar: AppBar(
        title: const Text('الرسائل الجماعية'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'تحديث',
          ),
          IconButton(
            onPressed: _isCreating ? null : _createBroadcast,
            icon: _isCreating
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_comment_outlined),
            tooltip: 'رسالة جديدة',
          ),
        ],
      ),
      body: _isLoading
          ? const AppLoadingState()
          : _error != null
          ? AppErrorState(title: 'حدث خطأ', message: _error!, onRetry: _load)
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _Hero(recipientCount: _recipientOptions.length),
                  const SizedBox(height: 16),
                  if (_broadcasts.isEmpty)
                    const AppEmptyState(
                      title: 'لا توجد رسائل جماعية',
                      message:
                          'أنشئ أول رسالة من هذه الصفحة، واختر هل تريد إرسالها للجميع أو لموظفين محددين.',
                      icon: Icons.outbox_outlined,
                    )
                  else ...[
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _MetricCard(
                          label: 'عدد الرسائل',
                          value: '${_broadcasts.length}',
                        ),
                        _MetricCard(
                          label: 'المستلمون المتاحون',
                          value: '${_recipientOptions.length}',
                        ),
                        _MetricCard(
                          label: 'آخر إرسال',
                          value: _broadcasts.first.createdAtLabel,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ..._broadcasts.map(
                      (broadcast) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _BroadcastCard(
                          broadcast: broadcast,
                          isBusy: _busyId == broadcast.id,
                          recipientSummary: _recipientSummary(broadcast),
                          onEdit: () => _editBroadcast(broadcast),
                          onDelete: () => _deleteBroadcast(broadcast),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isCreating ? null : _createBroadcast,
        icon: const Icon(Icons.campaign_outlined),
        label: const Text('رسالة جديدة'),
      ),
    );
  }

  void _onPrimaryNavigation(int index) {
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed(AppRoutes.managerDashboard);
        return;
      case 1:
        Navigator.of(
          context,
        ).pushReplacementNamed(AppRoutes.managerLeaveRequests);
        return;
      case 2:
        Navigator.of(
          context,
        ).pushReplacementNamed(AppRoutes.managerEmployeeDetails);
        return;
      case 3:
        return;
      case 4:
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.notifications,
          arguments: AppUserRole.manager,
        );
        return;
      case 5:
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.profileAccount,
          arguments: AppUserRole.manager,
        );
        return;
    }
  }

  String _recipientSummary(ManagerBroadcastMessage broadcast) {
    if (broadcast.isAllAudience) {
      return 'إرسال للجميع';
    }
    if (broadcast.recipientNames.isEmpty) {
      return 'إرسال مخصص';
    }
    final names = broadcast.recipientNames.join('، ');
    final remaining =
        broadcast.recipientCount - broadcast.recipientNames.length;
    if (remaining > 0) {
      return '$names +$remaining';
    }
    return names;
  }

  String _message(Object error, String fallback) {
    final text = error.toString().replaceFirst('Bad state: ', '').trim();
    return text.isEmpty ? fallback : text;
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.recipientCount});

  final int recipientCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF102A5C), Color(0xFF1D4ED8)],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الرسائل الجماعية للمدير',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'من هذه الصفحة يمكنك إرسال رسالة للجميع أو لموظف واحد أو عدة موظفين وHR، مع إمكانية مراجعتها وتعديلها وحذفها لاحقًا.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.86),
            ),
          ),
          const SizedBox(height: 16),
          _InfoChip(
            label: 'مستلمون متاحون',
            value: '$recipientCount',
            textColor: Colors.white,
            backgroundColor: Colors.white.withValues(alpha: 0.12),
            borderColor: Colors.white.withValues(alpha: 0.16),
          ),
        ],
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
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BroadcastCard extends StatelessWidget {
  const _BroadcastCard({
    required this.broadcast,
    required this.isBusy,
    required this.recipientSummary,
    required this.onEdit,
    required this.onDelete,
  });

  final ManagerBroadcastMessage broadcast;
  final bool isBusy;
  final String recipientSummary;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    broadcast.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (isBusy)
                  const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(broadcast.message),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _InfoChip(
                  label: 'نوع الإرسال',
                  value: broadcast.isAllAudience ? 'الكل' : 'مخصص',
                ),
                _InfoChip(
                  label: 'المستلمون',
                  value: '${broadcast.recipientCount}',
                ),
                _InfoChip(label: 'ملخص', value: recipientSummary),
                _InfoChip(label: 'أرسلت', value: broadcast.createdAtLabel),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                OutlinedButton.icon(
                  onPressed: isBusy ? null : onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('تعديل'),
                ),
                OutlinedButton.icon(
                  onPressed: isBusy ? null : onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('حذف'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    required this.value,
    this.textColor = const Color(0xFF0F172A),
    this.backgroundColor = const Color(0xFFF8FAFC),
    this.borderColor = const Color(0xFFE2E8F0),
  });

  final String label;
  final String value;
  final Color textColor;
  final Color backgroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Text('$label: $value', style: TextStyle(color: textColor)),
    );
  }
}
