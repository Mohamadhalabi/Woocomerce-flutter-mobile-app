// lib/services/api_cache.dart
//
// Two-layer cache for API responses: memory first, then disk, then network.
//
// The pattern that matters here is stale-while-revalidate — when cached data
// has expired, it's returned IMMEDIATELY and refreshed in the background. The
// customer never waits on a spinner for data that's a few minutes old, and the
// server sees one request instead of one per screen open.
//
// Disk cache survives app restarts, so a cold launch renders from cache while
// the network catches up.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MemoryEntry {
  final dynamic json;
  final DateTime storedAt;

  _MemoryEntry(this.json, this.storedAt);
}

class ApiCache {
  static const _prefix = 'apicache:';

  static final Map<String, _MemoryEntry> _memory = {};

  /// Tracks in-flight fetches so three widgets asking for categories at the
  /// same moment produce ONE request, not three.
  static final Map<String, Future<dynamic>> _inFlight = {};

  /// Reads through the cache.
  ///
  /// [key] must be unique per resource AND per audience where the response
  /// differs — prices are hidden from guests, so a cache shared between signed
  /// in and signed out states would leak the wrong version.
  static Future<T> read<T>({
    required String key,
    required Duration ttl,
    required Future<dynamic> Function() fetch,
    required T Function(dynamic json) decode,
    bool staleWhileRevalidate = true,
  }) async {
    final now = DateTime.now();

    // 1. Memory
    final cached = _memory[key];
    if (cached != null) {
      final age = now.difference(cached.storedAt);
      if (age < ttl) return decode(cached.json);

      if (staleWhileRevalidate) {
        _refreshInBackground(key, fetch);
        return decode(cached.json);
      }
    }

    // 2. Disk
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$key');

    if (raw != null) {
      try {
        final envelope = jsonDecode(raw) as Map<String, dynamic>;
        final storedAt = DateTime.parse(envelope['at'] as String);
        final json = envelope['data'];
        final age = now.difference(storedAt);

        _memory[key] = _MemoryEntry(json, storedAt);

        if (age < ttl) return decode(json);

        if (staleWhileRevalidate) {
          _refreshInBackground(key, fetch);
          return decode(json);
        }
      } catch (_) {
        // Corrupt or from an older schema — drop it and refetch.
        await prefs.remove('$_prefix$key');
      }
    }

    // 3. Network
    final json = await _fetchDeduplicated(key, fetch);
    return decode(json);
  }

  /// Shares one in-flight request between simultaneous callers.
  ///
  /// The timeout is essential: without it a stalled request leaves its key
  /// occupied forever, and every later caller is handed the same stalled
  /// future — a spinner that never resolves and never errors.
  static Future<dynamic> _fetchDeduplicated(
      String key,
      Future<dynamic> Function() fetch,
      ) {
    final existing = _inFlight[key];
    if (existing != null) return existing;

    final future = fetch()
        .timeout(const Duration(seconds: 20))
        .then((json) async {
      await _store(key, json);
      return json;
    })
        .whenComplete(() => _inFlight.remove(key));

    _inFlight[key] = future;

    // Attach a listener so a rejection before the caller awaits isn't an
    // unhandled async error. It must NOT rethrow — doing so creates a second
    // orphaned future and wedges the zone, which is what left drawer sections
    // spinning forever.
    unawaited(future.then((_) {}, onError: (Object e) {
      debugPrint('ApiCache fetch failed for $key: $e');
    }));

    return future;
  }

  /// Fire and forget. A failed refresh leaves the stale copy in place, which
  /// is what keeps the app usable on a bad connection.
  static void _refreshInBackground(
      String key,
      Future<dynamic> Function() fetch,
      ) {
    if (_inFlight.containsKey(key)) return;

    unawaited(_fetchDeduplicated(key, fetch).then((_) {}, onError: (Object e) {
      debugPrint('Cache refresh failed for $key: $e');
    }));
  }

  static Future<void> _store(String key, dynamic json) async {
    _memory[key] = _MemoryEntry(json, DateTime.now());

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '$_prefix$key',
        jsonEncode({'at': DateTime.now().toIso8601String(), 'data': json}),
      );
    } catch (e) {
      // Disk write failures are non-fatal — memory cache still works.
      debugPrint('Cache write failed for $key: $e');
    }
  }

  /// Drops one entry. Use after a mutation that invalidates it.
  static Future<void> invalidate(String key) async {
    _memory.remove(key);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$key');
  }

  /// Clears everything. Call this on sign in and sign out: home sections and
  /// every priced response differ by audience, so keeping the guest copies
  /// around would show a signed-in customer price-less products.
  static Future<void> clearAll() async {
    _memory.clear();
    _inFlight.clear();

    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix)).toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}