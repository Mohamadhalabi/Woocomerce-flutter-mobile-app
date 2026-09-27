// lib/components/update_gate.dart
//
// Blocks the app when the installed version is older than the minimum the
// server allows (GET /app/version). Checked on launch and whenever the app
// comes back to the foreground, so a customer who leaves for the store and
// returns without updating is still blocked.
//
// Fails OPEN: if the check can't reach the server, the app keeps working. A
// network problem must never lock paying customers out.
//
// Self-contained on purpose (dart:io HttpClient, dotenv for the URL and key):
// it sits above the Navigator in MaterialApp.builder and must not depend on
// anything that could itself be broken in an old version.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateGate extends StatefulWidget {
  const UpdateGate({super.key, required this.child});

  final Widget child;

  @override
  State<UpdateGate> createState() => _UpdateGateState();
}

class _UpdateGateState extends State<UpdateGate> with WidgetsBindingObserver {
  /// Non-null while the app is blocked: where the Güncelle button goes.
  String? _storeUrl;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    if (_checking || !(Platform.isAndroid || Platform.isIOS)) return;
    _checking = true;

    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 8);

    try {
      final base = (dotenv.env['NEW_API_BASE_URL'] ?? '')
          .replaceAll(RegExp(r'/+$'), '');
      if (base.isEmpty) return;

      final request = await client.getUrl(Uri.parse('$base/app/version'));
      request.headers.set('Accept', 'application/json');
      request.headers.set('X-Client-Key', dotenv.env['CLIENT_KEY_APP'] ?? '');

      final response =
          await request.close().timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return;

      final body = jsonDecode(await response.transform(utf8.decoder).join())
          as Map<String, dynamic>;
      final platform =
          body[Platform.isIOS ? 'ios' : 'android'] as Map<String, dynamic>?;

      final minVersion = platform?['min_version']?.toString();
      final storeUrl = platform?['store_url']?.toString() ?? '';

      // No store link means nowhere to send them — don't block.
      if (minVersion == null || storeUrl.isEmpty) return;

      final installed = (await PackageInfo.fromPlatform()).version;
      final next = _compare(installed, minVersion) < 0 ? storeUrl : null;

      if (mounted && next != _storeUrl) {
        setState(() => _storeUrl = next);
      }
    } catch (e) {
      debugPrint('Update check failed (app stays usable): $e');
    } finally {
      client.close();
      _checking = false;
    }
  }

  /// Compares "1.2.3" style versions. Negative when [a] is older than [b].
  /// Build numbers ("+12") are ignored — the store version is what counts.
  static int _compare(String a, String b) {
    List<int> parts(String v) => v
        .split('+')
        .first
        .split('.')
        .map((s) => int.tryParse(s.trim()) ?? 0)
        .toList();

    final x = parts(a);
    final y = parts(b);

    for (var i = 0; i < 3; i++) {
      final diff = (i < x.length ? x[i] : 0) - (i < y.length ? y[i] : 0);
      if (diff != 0) return diff;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final storeUrl = _storeUrl;
    if (storeUrl == null) return widget.child;
    return _ForceUpdateScreen(storeUrl: storeUrl);
  }
}

class _ForceUpdateScreen extends StatelessWidget {
  const _ForceUpdateScreen({required this.storeUrl});

  final String storeUrl;

  static const Color _primary = Color(0xFF2D83B0);

  Future<void> _openStore() async {
    await launchUrl(
      Uri.parse(storeUrl),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/logo/aanahtar-logo.webp', height: 64),
              const SizedBox(height: 40),
              const Icon(Icons.system_update, size: 56, color: _primary),
              const SizedBox(height: 20),
              const Text(
                'Güncelleme Gerekli',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              const Text(
                'Uygulamanın yeni bir sürümü yayınlandı. Devam etmek için '
                'lütfen uygulamayı güncelleyin.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _openStore,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text('Güncelle'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
