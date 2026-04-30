import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/services/app_services.dart';
import '../../../../core/utils/arabic_date_time_formatter.dart';
import '../../../attendance/domain/models/attendance_qr_session.dart';
import '../../../common/domain/models/app_user_role.dart';
import '../../../common/presentation/widgets/app_error_state.dart';
import '../../../common/presentation/widgets/app_loading_state.dart';

class ManagerQrDisplayScreen extends StatefulWidget {
  const ManagerQrDisplayScreen({super.key});

  @override
  State<ManagerQrDisplayScreen> createState() => _ManagerQrDisplayScreenState();
}

class _ManagerQrDisplayScreenState extends State<ManagerQrDisplayScreen> {
  AttendanceQrSession? _session;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession({bool refresh = false}) async {
    if (refresh && _isRefreshing) {
      return;
    }

    setState(() {
      if (refresh) {
        _isRefreshing = true;
      } else {
        _isLoading = true;
      }
      _errorMessage = null;
    });

    try {
      final session = await AppServices.attendanceRepository
          .createAttendanceQrSession(
            role: AppUserRole.manager,
            refresh: refresh,
          );
      if (!mounted) {
        return;
      }

      setState(() {
        _session = session;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'تعذر تحميل باركود الحضور حالياً.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = _session;

    return Scaffold(
      appBar: AppBar(title: const Text('عرض QR الحضور'), centerTitle: true),
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
          child: _isLoading
              ? const AppLoadingState(
                  title: 'جارٍ تحميل باركود الحضور',
                  message: 'نحضّر جلسة QR الحالية الخاصة بالمدير المباشر.',
                )
              : _errorMessage != null
              ? AppErrorState(
                  title: 'حدث خطأ',
                  message: _errorMessage!,
                  onRetry: () => _loadSession(),
                )
              : session == null
              ? AppErrorState(
                  title: 'تعذر تحميل الرمز',
                  message: 'لا توجد جلسة QR متاحة حالياً.',
                  onRetry: () => _loadSession(),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _QrHero(
                            title: 'باركود حضور ثابت للفريق',
                            subtitle:
                                'يبقى هذا الرمز كما هو حتى تضغط زر تغيير الباركود. عند التغيير يتم إبطال الرمز السابق مباشرة ويظهر رمز جديد للمسح.',
                            token: session.token,
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Center(
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(28),
                                      border: Border.all(
                                        color: const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    child: QrImageView(
                                      data: session.payload,
                                      size: 260,
                                      backgroundColor: Colors.white,
                                      eyeStyle: const QrEyeStyle(
                                        eyeShape: QrEyeShape.square,
                                        color: Color(0xFF0F172A),
                                      ),
                                      dataModuleStyle: const QrDataModuleStyle(
                                        dataModuleShape:
                                            QrDataModuleShape.square,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  session.token,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    _InfoTile(
                                      icon: Icons.schedule_rounded,
                                      label: 'آخر إنشاء',
                                      value: ArabicDateTimeFormatter.dateTime(
                                        session.generatedAt,
                                      ),
                                    ),
                                    const _InfoTile(
                                      icon: Icons.lock_clock_outlined,
                                      label: 'حالة الرمز',
                                      value: 'ثابت حتى تغييره يدويًا',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: const Text(
                                    'يمكن للموظف مسح هذا الباركود في أي وقت، وسيبقى صالحًا حتى تضغط على زر تغيير الباركود في الأسفل.',
                                  ),
                                ),
                                const SizedBox(height: 18),
                                ElevatedButton.icon(
                                  onPressed: _isRefreshing
                                      ? null
                                      : () => _loadSession(refresh: true),
                                  icon: Icon(
                                    _isRefreshing
                                        ? Icons.hourglass_top_rounded
                                        : Icons.refresh_rounded,
                                  ),
                                  label: Text(
                                    _isRefreshing
                                        ? 'جارٍ تغيير الباركود'
                                        : 'تغيير باركود الحضور',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _GuidePoint(
                                  icon: Icons.touch_app_outlined,
                                  text:
                                      'الرمز لا يتغير تلقائيًا بعد الآن، بل يتبدل فقط عند الضغط على زر تغيير الباركود.',
                                ),
                                SizedBox(height: 12),
                                _GuidePoint(
                                  icon: Icons.sync_disabled_outlined,
                                  text:
                                      'يبقى نفس الباركود ظاهرًا حتى لو انتظرت أكثر من 30 ثانية، ولن يتم إلغاؤه إلا عند إصدار رمز جديد يدويًا.',
                                ),
                                SizedBox(height: 12),
                                _GuidePoint(
                                  icon: Icons.qr_code_scanner_rounded,
                                  text:
                                      'عند تغيير الباركود، يصبح الرمز السابق غير صالح للمسح فورًا ويعتمد النظام الرمز الجديد فقط.',
                                ),
                              ],
                            ),
                          ),
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

class _QrHero extends StatelessWidget {
  const _QrHero({
    required this.title,
    required this.subtitle,
    required this.token,
  });

  final String title;
  final String subtitle;
  final String token;

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
          Text(
            title,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.86),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Token: $token',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFE7EEFF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: const Color(0xFF1D4ED8)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
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

class _GuidePoint extends StatelessWidget {
  const _GuidePoint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFE7EEFF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: const Color(0xFF1D4ED8)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}
