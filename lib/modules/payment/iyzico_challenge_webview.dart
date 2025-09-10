import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../../services/api_service.dart';
import '../../services/alert_service.dart';

class IyzicoChallengeWebView extends StatefulWidget {
  final String html;    // full HTML returned by /pay-card (threeDSHtml)
  final String orderId; // used to poll status

  const IyzicoChallengeWebView({
    super.key,
    required this.html,
    required this.orderId,
  });

  @override
  State<IyzicoChallengeWebView> createState() => _IyzicoChallengeWebViewState();
}

class _IyzicoChallengeWebViewState extends State<IyzicoChallengeWebView> {
  late final WebViewController _controller;
  Timer? _poll;
  bool _loading = true;

  // 🔧 Tune these two to control how “fast” failure shows:
  static const Duration _pollInterval = Duration(seconds: 2);  // was 3s
  static const Duration _maxWait      = Duration(seconds: 75); // was ~360s
  late final int _maxTicks = (_maxWait.inSeconds / _pollInterval.inSeconds).ceil();

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() => _loading = true);
            _maybeFastClose(url);
          },
          onPageFinished: (url) {
            setState(() => _loading = false);
            _maybeFastClose(url);
          },
          onNavigationRequest: (request) {
            _maybeFastClose(request.url);
            return NavigationDecision.navigate;
          },
          onWebResourceError: (e) =>
              AlertService.showTopAlert(context, 'WebView hata: ${e.description}', isError: true),
        ),
      );

    _androidCookieSetup();
    _controller.loadHtmlString(widget.html, baseUrl: 'https://www.aanahtar.com.tr');
    _startPolling();
  }

  void _androidCookieSetup() {
    if (!Platform.isAndroid) return;
    try {
      final androidCtrl = _controller.platform as AndroidWebViewController;
      final cookieMgr = AndroidWebViewCookieManager(
        const PlatformWebViewCookieManagerCreationParams(),
      );
      cookieMgr.setAcceptThirdPartyCookies(androidCtrl, true);
    } catch (_) {}
  }

  // 🚀 Faster polling + immediate fail on status=failed
  void _startPolling() {
    _poll?.cancel();
    int ticks = 0;

    _poll = Timer.periodic(_pollInterval, (t) async {
      ticks++;
      try {
        final res = await ApiService.getIyzicoStatus(orderId: widget.orderId);
        final status = (res['status'] ?? '').toString().toLowerCase();
        final paid   = res['paid'] == true;

        if (paid || status == 'paid') {
          t.cancel();
          if (mounted) Navigator.pop(context, true);
          return;
        }
        if (status == 'failed') {
          t.cancel();
          if (mounted) Navigator.pop(context, false);
          return;
        }
      } catch (_) {
        // ignore – keep polling
      }

      if (ticks >= _maxTicks) {
        t.cancel();
        if (mounted) Navigator.pop(context, false); // ⏳ timeout -> treat as failed
      }
    });
  }

  // ⚡ If the bank/browser lands on our callback URL, check once and close immediately
  Future<void> _maybeFastClose(String? url) async {
    if (url == null) return;
    // Adjust if you change your REST route
    if (url.contains('/wp-json/mobile-iyzico/v1/three-ds-callback')) {
      try {
        final res = await ApiService.getIyzicoStatus(orderId: widget.orderId);
        final status = (res['status'] ?? '').toString().toLowerCase();
        final paid   = res['paid'] == true;
        if (!mounted) return;
        Navigator.pop(context, paid || status == 'paid');
      } catch (_) {
        if (!mounted) return;
        Navigator.pop(context, false);
      }
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('3D Secure Doğrulama'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // user cancels immediately
            child: const Text('Kapat', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
