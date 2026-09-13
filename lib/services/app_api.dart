// lib/services/app_api.dart
//
// One ApiClient for the whole app, plus the repositories built on it.
//
// This matters for the cart: the X-Cart-Token has to be consistent across
// screens, and separate ApiClient instances would each hold their own copy of
// the auth token too.
//
// Call initAppApi() in main() BEFORE runApp.

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/catalog_product.dart';
import '../repositories/account_repository.dart';
import '../repositories/auth_repository.dart';
import '../repositories/cart_repository.dart';
import '../repositories/catalog_repository.dart';
import '../repositories/category_repository.dart';
import '../repositories/home_repository.dart';
import 'api_client.dart';
import 'currency_service.dart';

late ApiClient apiV2;
late CatalogRepository catalogRepo;
late CategoryRepository categoryRepo;
late HomeRepository homeRepo;
late CartRepository cartRepo;
late AuthRepository authRepo;
late AccountRepository accountRepo;

bool _initialised = false;

Future<void> initAppApi() async {
  if (_initialised) return;

  apiV2 = await ApiClient.fromEnv();
  apiV2.setLocale(language: 'tr', currency: CurrencyService.fallback);

  // Host for resolving relative image paths. Strips the trailing /api so
  // "/images/x.jpg" resolves against the domain, not the API prefix.
  imageBaseUrl = apiV2.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');

  // Assigned BEFORE anything that can fail. These are `late`, and a throw
  // between here and the end used to leave every screen crashing with
  // "Field 'homeRepo' has not been initialized" — which says nothing about
  // the actual cause.
  catalogRepo = CatalogRepository(apiV2);
  categoryRepo = CategoryRepository(apiV2);
  homeRepo = HomeRepository(apiV2);
  cartRepo = CartRepository(apiV2);
  authRepo = AuthRepository(apiV2);
  accountRepo = AccountRepository(apiV2);

  _initialised = true;

  // Disk reads only — a few milliseconds, no network. Startup used to block
  // on GET /auth/me, which costs a full round trip (~450ms on mobile) before
  // the first frame could render.
  try {
    await CurrencyService.restore();
    await authRepo.loadCachedSession();
  } catch (e) {
    debugPrint('Cached session restore failed: $e');
  }

  // Verified in the BACKGROUND. The cached answer is right almost every time;
  // when it isn't — a revoked token, an un-approved account — this corrects it
  // a moment later, which is a far better trade than making every customer
  // wait on every launch.
  unawaited(
    authRepo.restoreSession().then(
          (_) {},
      onError: (Object e) => debugPrint('Session verify failed: $e'),
    ),
  );
}