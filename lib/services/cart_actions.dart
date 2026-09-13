// lib/services/cart_actions.dart
//
// One place for "add this to the cart and tell the user what happened".
//
// Every screen that shows a product — home, store, product page, search,
// wishlist — calls this instead of repeating the try/catch and the alert.

import 'package:flutter/material.dart';

import '../models/catalog_product.dart';
import 'alert_service.dart';
import 'api_client.dart';
import 'app_api.dart';

class CartActions {
  /// Adds a product and shows the standard top alert.
  ///
  /// Returns true on success, so callers that need to close a sheet or reset a
  /// stepper can react. Never throws — errors surface as a red alert.
  static Future<bool> add(
      BuildContext context, {
        required int productId,
        int quantity = 1,
        String successMessage = 'Ürün sepete eklendi',
        bool showGoToCart = true,
      }) async {
    try {
      await cartRepo.add(productId, quantity: quantity);

      if (!context.mounted) return true;
      AlertService.showTopAlert(
        context,
        successMessage,
        showGoToCart: showGoToCart,
      );
      return true;
    } on ApiException catch (e) {
      if (!context.mounted) return false;
      AlertService.showTopAlert(context, e.message, isError: true);
      return false;
    } catch (e) {
      if (!context.mounted) return false;
      AlertService.showTopAlert(
        context,
        'Ürün sepete eklenemedi.',
        isError: true,
      );
      return false;
    }
  }

  /// Convenience overload when you already have the model — checks stock
  /// before calling out, so an out-of-stock tap doesn't hit the API.
  static Future<bool> addProduct(
      BuildContext context,
      ProductModel product, {
        int quantity = 1,
      }) async {
    if (!product.inStock) {
      AlertService.showTopAlert(context, 'Ürün stokta yok', isError: true);
      return false;
    }

    return add(context, productId: product.id, quantity: quantity);
  }

  /// Sets an absolute quantity on a cart line. Pass 0 to remove it.
  /// [itemId] is CartItem.id, NOT the product id.
  static Future<bool> setQuantity(
      BuildContext context, {
        required int itemId,
        required int quantity,
      }) async {
    try {
      await cartRepo.updateQuantity(itemId, quantity);
      return true;
    } on ApiException catch (e) {
      if (!context.mounted) return false;
      AlertService.showTopAlert(context, e.message, isError: true);
      return false;
    }
  }

  static Future<bool> remove(BuildContext context, int itemId) async {
    try {
      await cartRepo.remove(itemId);
      return true;
    } on ApiException catch (e) {
      if (!context.mounted) return false;
      AlertService.showTopAlert(context, e.message, isError: true);
      return false;
    }
  }
}