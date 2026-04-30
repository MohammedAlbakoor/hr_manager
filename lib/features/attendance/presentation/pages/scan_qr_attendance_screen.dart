import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/services/app_services.dart';
import '../../domain/models/attendance_record.dart';
import '../../domain/models/attendance_scan_payload.dart';

class ScanQrAttendanceScreen extends StatefulWidget {
  const ScanQrAttendanceScreen({super.key});

  @override
  State<ScanQrAttendanceScreen> createState() => _ScanQrAttendanceScreenState();
}

class _ScanQrAttendanceScreenState extends State<ScanQrAttendanceScreen> {
  _ScanQrAttendanceScreenState()
    : _scannerController = MobileScannerController(
        autoStart: true,
        autoZoom: true,
        detectionSpeed: DetectionSpeed.noDuplicates,
        facing: CameraFacing.back,
        formats: const [BarcodeFormat.qrCode],
      );

  final TextEditingController _tokenController = TextEditingController();
  final MobileScannerController _scannerController;

  bool _isScanning = false;
  bool _isTorchEnabled = false;
  String? _detectedToken;
  String? _cameraMessage;
  AttendanceRecord? _record;

  bool get _supportsCameraScanner =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  @override
  void dispose() {
    _tokenController.dispose();
    if (_supportsCameraScanner) {
      unawaited(_scannerController.dispose());
    }
    super.dispose();
  }

  Future<void> _submitScan({
    String? tokenOverride,
    bool fromCamera = false,
  }) async {
    final token = (tokenOverride ?? _tokenController.text).trim();
    if (token.isEmpty) {
      _showSnack(
        'وجّه الكاميرا نحو رمز QR أو أدخل رمز الجلسة يدوياً ثم حاول مرة أخرى.',
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isScanning = true;
      _detectedToken = token;
      if (fromCamera) {
        _cameraMessage = 'تم التقاط الرمز، جاري التحقق من جلسة الحضور...';
      }
    });

    try {
      final deviceId = await AppServices.deviceIdentifierService
          .getDeviceIdentifier();

      final record = await AppServices.attendanceRepository.scanAttendance(
        AttendanceScanPayload(token: token, deviceId: deviceId),
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _record = record;
        _cameraMessage = 'تم اعتماد جلسة QR وتسجيل الحضور بنجاح.';
      });

      if (_supportsCameraScanner) {
        await _scannerController.stop();
      }

      _showSnack('تم تسجيل الحضور بنجاح عند ${record.checkInTimeLabel}.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        if (fromCamera) {
          _cameraMessage =
              'تعذر اعتماد الرمز الحالي. جرّب توجيه الكاميرا مرة أخرى أو استخدم الإدخال اليدوي.';
        }
      });

      if (fromCamera && _supportsCameraScanner) {
        unawaited(_scannerController.start());
      }

      _showSnack(error.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  Future<void> _handleBarcodeDetection(BarcodeCapture capture) async {
    if (_isScanning) {
      return;
    }

    final token = _extractToken(capture);
    if (token == null) {
      return;
    }

    _tokenController.text = token;

    if (_supportsCameraScanner) {
      await _scannerController.stop();
    }

    await _submitScan(tokenOverride: token, fromCamera: true);
  }

  String? _extractToken(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue?.trim();
      if (value != null && value.isNotEmpty) {
        return _normalizeToken(value);
      }
    }
    return null;
  }

  String _normalizeToken(String value) {
    final uri = Uri.tryParse(value);
    if (uri != null) {
      final token = uri.queryParameters['token']?.trim();
      if (token != null && token.isNotEmpty) {
        return token;
      }

      final attendanceToken = uri.queryParameters['attendance_token']?.trim();
      if (attendanceToken != null && attendanceToken.isNotEmpty) {
        return attendanceToken;
      }
    }

    return value;
  }

  Future<void> _toggleTorch() async {
    if (!_supportsCameraScanner) {
      return;
    }

    try {
      await _scannerController.toggleTorch();
      if (!mounted) {
        return;
      }

      setState(() {
        _isTorchEnabled = !_isTorchEnabled;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showSnack('تعذر تغيير حالة الإضاءة في هذه اللحظة.');
    }
  }

  Future<void> _resetScanner() async {
    _tokenController.clear();
    setState(() {
      _record = null;
      _detectedToken = null;
      _cameraMessage = null;
      _isTorchEnabled = false;
    });

    if (_supportsCameraScanner) {
      await _scannerController.start();
    }
  }

  void _handleDetectError(Object error, StackTrace stackTrace) {
    if (!mounted) {
      return;
    }

    setState(() {
      _cameraMessage =
          'تعذر الوصول إلى الكاميرا أو قراءة الرمز حالياً. يمكنك المحاولة مرة أخرى أو استخدام الإدخال اليدوي.';
    });
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 920;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل الحضور عبر QR'),
        centerTitle: true,
      ),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ScanHero(
                      currentToken:
                          _detectedToken ?? _tokenController.text.trim(),
                      record: _record,
                      supportsCameraScanner: _supportsCameraScanner,
                    ),
                    const SizedBox(height: 20),
                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: _ScanEntryCard(
                              controller: _tokenController,
                              scannerController: _scannerController,
                              supportsCameraScanner: _supportsCameraScanner,
                              isScanning: _isScanning,
                              isTorchEnabled: _isTorchEnabled,
                              cameraMessage: _cameraMessage,
                              onChanged: (_) => setState(() {}),
                              onSubmit: _submitScan,
                              onDetect: _handleBarcodeDetection,
                              onDetectError: _handleDetectError,
                              onToggleTorch: _toggleTorch,
                              onResetScanner: _resetScanner,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: _ScanResultPanel(record: _record),
                          ),
                        ],
                      )
                    else ...[
                      _ScanEntryCard(
                        controller: _tokenController,
                        scannerController: _scannerController,
                        supportsCameraScanner: _supportsCameraScanner,
                        isScanning: _isScanning,
                        isTorchEnabled: _isTorchEnabled,
                        cameraMessage: _cameraMessage,
                        onChanged: (_) => setState(() {}),
                        onSubmit: _submitScan,
                        onDetect: _handleBarcodeDetection,
                        onDetectError: _handleDetectError,
                        onToggleTorch: _toggleTorch,
                        onResetScanner: _resetScanner,
                      ),
                      const SizedBox(height: 16),
                      _ScanResultPanel(record: _record),
                    ],
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'إرشادات التسجيل',
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 14),
                          const _GuidePoint(
                            icon: Icons.camera_alt_outlined,
                            text:
                                'وجّه الكاميرا نحو رمز QR الحقيقي المعروض من المدير أو الموارد البشرية ليتم التقاط جلسة Laravel مباشرة.',
                          ),
                          const SizedBox(height: 12),
                          const _GuidePoint(
                            icon: Icons.security_outlined,
                            text:
                                'الخادم يتحقق من صلاحية جلسة QR ومن ربط الجهاز الحقيقي فقط قبل اعتماد تسجيل الحضور.',
                          ),
                          const SizedBox(height: 12),
                          const _GuidePoint(
                            icon: Icons.keyboard_outlined,
                            text:
                                'إذا تعذر استخدام الكاميرا على المنصة الحالية أو لم يتم منح الصلاحية، يبقى الإدخال اليدوي متاحاً كخيار احتياطي.',
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _isScanning
                                      ? null
                                      : () => _resetScanner(),
                                  icon: const Icon(Icons.restart_alt_rounded),
                                  label: const Text('مسح جديد'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).pushNamed(
                                      AppRoutes.employeeAttendanceHistory,
                                    );
                                  },
                                  icon: const Icon(Icons.history_rounded),
                                  label: const Text('سجل الدوام'),
                                ),
                              ),
                            ],
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

class _ScanHero extends StatelessWidget {
  const _ScanHero({
    required this.currentToken,
    required this.record,
    required this.supportsCameraScanner,
  });

  final String currentToken;
  final AttendanceRecord? record;
  final bool supportsCameraScanner;

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
            'تسجيل حضور حقيقي عبر QR والكاميرا',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            supportsCameraScanner
                ? 'افتح الكاميرا ووجّهها إلى رمز QR ليتم التقاط رمز الجلسة تلقائياً ثم إرسال الطلب مباشرة إلى خادم Laravel.'
                : 'هذه المنصة لا تدعم مسح الكاميرا حالياً داخل التطبيق، لذلك سيبقى الإدخال اليدوي متاحاً بشكل احتياطي.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.86),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroBadge(
                label: currentToken.isEmpty
                    ? 'بانتظار مسح رمز QR'
                    : 'آخر رمز ملتقط: $currentToken',
              ),
              _HeroBadge(
                label: record == null
                    ? 'لم يتم تسجيل حضور بعد'
                    : 'آخر تسجيل: ${record?.checkInTimeLabel}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ScanEntryCard extends StatelessWidget {
  const _ScanEntryCard({
    required this.controller,
    required this.scannerController,
    required this.supportsCameraScanner,
    required this.isScanning,
    required this.isTorchEnabled,
    required this.cameraMessage,
    required this.onChanged,
    required this.onSubmit,
    required this.onDetect,
    required this.onDetectError,
    required this.onToggleTorch,
    required this.onResetScanner,
  });

  final TextEditingController controller;
  final MobileScannerController scannerController;
  final bool supportsCameraScanner;
  final bool isScanning;
  final bool isTorchEnabled;
  final String? cameraMessage;
  final ValueChanged<String> onChanged;
  final Future<void> Function({String? tokenOverride, bool fromCamera})
  onSubmit;
  final Future<void> Function(BarcodeCapture capture) onDetect;
  final void Function(Object error, StackTrace stackTrace) onDetectError;
  final Future<void> Function() onToggleTorch;
  final Future<void> Function() onResetScanner;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('مسح رمز QR', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Text(
            supportsCameraScanner
                ? 'استخدم الكاميرا الخلفية لمسح الرمز مباشرة. وعند الحاجة يمكنك استخدام الإدخال اليدوي الموجود أسفل المعاينة.'
                : 'الكاميرا غير مدعومة على هذه المنصة حالياً، لذلك يمكنك إدخال رمز الجلسة يدوياً كخيار احتياطي.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          Container(
            height: 320,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(28),
            ),
            clipBehavior: Clip.antiAlias,
            child: supportsCameraScanner
                ? MobileScanner(
                    controller: scannerController,
                    fit: BoxFit.cover,
                    tapToFocus: true,
                    onDetect: onDetect,
                    onDetectError: onDetectError,
                    placeholderBuilder: (_) => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    errorBuilder: (context, error) => const _CameraUnavailableState(
                      title: 'تعذر فتح الكاميرا',
                      message:
                          'تحقق من صلاحية الكاميرا ثم حاول مجدداً، أو استخدم الإدخال اليدوي الموجود أسفل المعاينة.',
                    ),
                    overlayBuilder: (context, constraints) =>
                        const _ScannerOverlay(),
                  )
                : const _CameraUnavailableState(
                    title: 'الكاميرا غير مدعومة',
                    message:
                        'يمكنك متابعة تجربة تسجيل الحضور من خلال إدخال رمز الجلسة يدوياً على هذه المنصة.',
                  ),
          ),
          const SizedBox(height: 14),
          if (cameraMessage != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                cameraMessage!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              if (supportsCameraScanner)
                OutlinedButton.icon(
                  onPressed: isScanning ? null : onToggleTorch,
                  icon: Icon(
                    isTorchEnabled
                        ? Icons.flashlight_off_rounded
                        : Icons.flashlight_on_rounded,
                  ),
                  label: Text(
                    isTorchEnabled ? 'إطفاء الإضاءة' : 'تشغيل الإضاءة',
                  ),
                ),
              OutlinedButton.icon(
                onPressed: isScanning ? null : onResetScanner,
                icon: const Icon(Icons.center_focus_strong_rounded),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'إدخال يدوي احتياطي',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            enabled: !isScanning,
            onChanged: onChanged,
            decoration: const InputDecoration(
              labelText: 'رمز جلسة QR',
              hintText: 'ألصق رمز الجلسة هنا عند الحاجة',
              prefixIcon: Icon(Icons.password_rounded),
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: isScanning ? null : () => onSubmit(),
            icon: isScanning
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_circle_outline_rounded),
            label: Text(isScanning ? 'جاري تسجيل الحضور' : 'تأكيد الحضور'),
          ),
        ],
      ),
    );
  }
}

class _CameraUnavailableState extends StatelessWidget {
  const _CameraUnavailableState({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: const Color(0xFF0F172A),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 64,
              width: 64,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.qr_code_scanner_rounded,
                color: Colors.white,
                size: 34,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.82),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScannerOverlay extends StatelessWidget {
  const _ScannerOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        color: Colors.black.withValues(alpha: 0.18),
        child: Center(
          child: Container(
            width: 210,
            height: 210,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.12),
                  blurRadius: 24,
                ),
              ],
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.all(14),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.48),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'ضع رمز QR داخل الإطار',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScanResultPanel extends StatelessWidget {
  const _ScanResultPanel({required this.record});

  final AttendanceRecord? record;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('نتيجة العملية', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: record == null
                  ? const Color(0xFFF8FAFC)
                  : const Color(0xFFEAFBF4),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: record == null
                    ? const Color(0xFFE2E8F0)
                    : const Color(0xFFB7E6D2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        record == null
                            ? Icons.hourglass_bottom_rounded
                            : Icons.check_circle_outline_rounded,
                        color: record == null
                            ? const Color(0xFF475569)
                            : const Color(0xFF0F766E),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        record == null
                            ? 'بانتظار تنفيذ المسح'
                            : 'تم تسجيل الحضور',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _InfoLine(label: 'التاريخ', value: record?.dateLabel ?? '--'),
                const SizedBox(height: 8),
                _InfoLine(
                  label: 'الوقت',
                  value: record?.checkInTimeLabel ?? '--',
                ),
                const SizedBox(height: 8),
                _InfoLine(label: 'الحالة', value: record?.status.label ?? '--'),
                const SizedBox(height: 8),
                _InfoLine(label: 'الطريقة', value: record?.method ?? '--'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 78,
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFF64748B)),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
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
