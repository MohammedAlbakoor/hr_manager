import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

class AppConnectivityController {
  AppConnectivityController({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;
  final ValueNotifier<bool> _isOffline = ValueNotifier<bool>(false);

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _started = false;

  bool get isOffline => _isOffline.value;
  ValueNotifier<bool> get statusListenable => _isOffline;

  Future<void> startMonitoring() async {
    if (_started) {
      return;
    }

    try {
      _started = true;
      _updateStatus(await _connectivity.checkConnectivity());
      _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
    } on MissingPluginException {
      _started = false;
      _isOffline.value = false;
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    _started = false;
  }

  void _updateStatus(List<ConnectivityResult> results) {
    final isOfflineNow =
        results.isEmpty ||
        results.every((result) => result == ConnectivityResult.none);

    if (_isOffline.value != isOfflineNow) {
      _isOffline.value = isOfflineNow;
    }
  }
}

class ConnectivityHost extends StatefulWidget {
  const ConnectivityHost({
    super.key,
    required this.controller,
    required this.child,
  });

  final AppConnectivityController controller;
  final Widget child;

  @override
  State<ConnectivityHost> createState() => _ConnectivityHostState();
}

class _ConnectivityHostState extends State<ConnectivityHost> {
  @override
  void initState() {
    super.initState();
    unawaited(widget.controller.startMonitoring());
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.controller.statusListenable,
      builder: (context, isOffline, child) {
        return Stack(
          children: [
            child ?? const SizedBox.shrink(),
            IgnorePointer(
              ignoring: true,
              child: SafeArea(
                bottom: false,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    child: AnimatedSlide(
                      offset: isOffline ? Offset.zero : const Offset(0, -1.3),
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      child: AnimatedOpacity(
                        opacity: isOffline ? 1 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: const _OfflineBanner(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      child: widget.child,
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 720),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: AppPalette.primaryDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          boxShadow: const [
            BoxShadow(
              color: AppPalette.shadow,
              blurRadius: 28,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: const Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0x1FFFFFFF),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Icon(
                  Icons.wifi_off_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'لا يوجد اتصال بالإنترنت. تم إيقاف الطلبات مؤقتًا حتى يعود الاتصال.',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
