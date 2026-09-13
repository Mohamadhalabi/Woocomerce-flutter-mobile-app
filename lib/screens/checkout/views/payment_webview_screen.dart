// lib/screens/checkout/views/payment_webview_screen.dart
//
// Opens iyzico's hosted checkout page.
//
// The card is entered on iyzico's own page, never in the app — that keeps the
// app out of PCI-DSS scope and gives 3-D Secure for free.
//
// IMPORTANT: this screen never decides whether payment succeeded. It watches
// for the return URL, closes, and lets the caller ask the server. A customer
// can close the WebView mid-payment, and the page can redirect on failure just
// as it does on success.

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../constants.dart';

class PaymentWebViewScreen extends StatefulWidget {
  const PaymentWebViewScreen({
    super.key,
    required this.url,
    required this.orderNumber,
  });

  final String url;
  final String orderNumber;

  /// Pops true when the return URL was reached, false when the customer backed
  /// out. Neither means the payment succeeded — poll the server for that.
  static Future<bool> open(
    BuildContext context, {
    required String url,
    required String orderNumber,
  }) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentWebViewScreen(
          url: url,
          orderNumber: orderNumber,
        ),
      ),
    );

    return result ?? false;
  }

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _finished = false;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            // Checked on START, not finish: the return page may redirect again
            // and we'd miss it.
            if (_isReturnUrl(url)) _finish();
          },
          onPageFinished: (url) {
            if (mounted) setState(() => _loading = false);
            if (_isReturnUrl(url)) _finish();
          },
          onNavigationRequest: (request) {
            if (_isReturnUrl(request.url)) {
              _finish();
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  /// PaymentController redirects the browser here once iyzico has called back.
  bool _isReturnUrl(String url) => url.contains('/payment/return');

  void _finish() {
    if (_finished || !mounted) return;
    _finished = true;
    Navigator.pop(context, true);
  }

  Future<bool> _confirmExit() async {
    if (_finished) return true;

    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ödemeden çıkılsın mı?'),
        content: const Text(
          'Ödeme tamamlanmadı. Siparişiniz ödeme bekliyor olarak kalacak.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Devam Et'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Çık'),
          ),
        ],
      ),
    );

    return leave ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        if (await _confirmExit() && mounted) {
          Navigator.pop(context, false);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: blueColor,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            'Güvenli Ödeme',
            style: TextStyle(color: Colors.white),
          ),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              if (await _confirmExit() && mounted) {
                Navigator.pop(context, false);
              }
            },
          ),
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_loading)
              const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}
