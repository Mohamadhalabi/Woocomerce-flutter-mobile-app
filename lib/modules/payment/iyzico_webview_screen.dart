import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import '../../services/api_service.dart';
import '../../services/alert_service.dart';

class IyzicoWebviewScreen extends StatefulWidget {
  final String conversationId;   // orderId
  final String? token;           // optional
  final String? pageUrl;         // backend page
  final String? htmlContent;     // ORIGINAL iyzico snippet (preferred)

  const IyzicoWebviewScreen({
    super.key,
    required this.conversationId,
    this.pageUrl,
    this.token,
    this.htmlContent,
  });

  @override
  State<IyzicoWebviewScreen> createState() => _IyzicoWebviewScreenState();
}

class _IyzicoWebviewScreenState extends State<IyzicoWebviewScreen> {
  late final WebViewController _controller;
  Timer? _poll;
  bool _loading = true;
  String _lastLog = '';

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() {
              _loading = true;
              _lastLog = 'Loading: $url';
            });
          },
          onPageFinished: (_) async {
            // give the bundle a split second to attach to DOM
            await Future.delayed(const Duration(milliseconds: 300));
            setState(() => _loading = false);
            await _diagnoseAndMaybeFallback();
          },
          onWebResourceError: (e) {
            setState(() => _lastLog = 'web error: ${e.errorCode} ${e.description}');
            AlertService.showTopAlert(context, "WebView hata: ${e.description}", isError: true);
          },
        ),
      )
      ..setUserAgent(
        'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148',
      );

    _boot();
  }

  Future<void> _boot() async {
    await _configureAndroidCookies();
    await _loadPreferred();
    _startPolling();
  }

  Future<void> _configureAndroidCookies() async {
    if (!Platform.isAndroid) return;
    try {
      AndroidWebViewController.enableDebugging(true);
      final androidCtrl = _controller.platform as AndroidWebViewController;
      final cookieMgr = AndroidWebViewCookieManager(
        const PlatformWebViewCookieManagerCreationParams(),
      );
      await cookieMgr.setAcceptThirdPartyCookies(androidCtrl, true);
    } catch (e) {
      setState(() => _lastLog = 'cookie cfg error: $e');
    }
  }

  // Ensures the iyzico overlay has full-height space to render
  String _wrapHtml(String inner) => '''
<!doctype html><html lang="tr">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
  html,body,#iyzipay-checkout-form { margin:0; padding:0; height:100%; background:#fff; }
</style>
</head>
<body>$inner</body>
</html>
''';

  Future<void> _loadPreferred() async {
    try {
      final html = (widget.htmlContent ?? '').trim();
      final url  = (widget.pageUrl ?? '').trim();

      if (html.isNotEmpty) {
        // ✅ Load the ORIGINAL snippet first (most reliable)
        await _controller.loadHtmlString(
          _wrapHtml(html),
          baseUrl: 'https://www.aanahtar.com.tr',
        );
      } else if (url.isNotEmpty) {
        await _controller.loadRequest(Uri.parse(url));
      } else {
        setState(() => _lastLog = 'No pageUrl or htmlContent');
      }
    } catch (e) {
      setState(() => _lastLog = 'load error: $e');
    }
  }

  Future<void> _diagnoseAndMaybeFallback() async {
    try {
      final hasIyzi = await _controller.runJavaScriptReturningResult("typeof iyziInit");
      final bundleCount = await _controller.runJavaScriptReturningResult(
        "document.querySelectorAll('script[src*=\"checkoutform\"]').length",
      );
      final hostCount = await _controller.runJavaScriptReturningResult(
        "document.getElementById('iyzipay-checkout-form') ? 1 : 0",
      );

      setState(() => _lastLog =
      'typeof iyziInit=$hasIyzi, bundle tags=$bundleCount, hostDiv=$hostCount');

      // If (for some reason) the host div is missing and we still have the inline snippet,
      // force the inline path once.
      if (hostCount.toString() == '0' &&
          (widget.htmlContent ?? '').isNotEmpty) {
        await _controller.loadHtmlString(
          _wrapHtml(widget.htmlContent!),
          baseUrl: 'https://www.aanahtar.com.tr',
        );
      }
    } catch (e) {
      setState(() => _lastLog = 'diagnose error: $e');
    }
  }

  void _startPolling() {
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 3), (t) async {
      try {
        final res = await ApiService.getIyzicoStatus(orderId: widget.conversationId);
        if (res['paid'] == true) {
          t.cancel();
          if (mounted) Navigator.pop(context, true);
          return;
        }
      } catch (_) {}
      if (t.tick >= 60) {
        t.cancel();
        if (mounted) {
          AlertService.showTopAlert(context, "Ödeme henüz tamamlanmadı.", isError: true);
        }
      }
    });
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
        title: const Text('Kart ile Ödeme'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadPreferred),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Kapat', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading) const Center(child: CircularProgressIndicator()),
          Positioned(
            left: 12, right: 12, bottom: 12,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.85,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _lastLog.isEmpty ? '...' : _lastLog,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
