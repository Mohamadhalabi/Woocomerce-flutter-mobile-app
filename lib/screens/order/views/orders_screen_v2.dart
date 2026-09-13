// lib/screens/order/views/orders_screen_v2.dart
//
// GET /account/orders (paginated, 10 per page) and
// GET /account/orders/{order_number}.
//
// Orders are addressed by NUMBER (AA-100123), not id. Both endpoints scope by
// the customer id on the token, so another customer's order 404s.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../components/skleton/app_skeletons.dart';
import '../../../components/skleton/skelton.dart';
import '../../../constants.dart';
import '../../../repositories/account_repository.dart';
import '../../../services/api_client.dart';
import '../../../services/app_api.dart';
import '../../product/views/product_details_screen_v2.dart';

class OrdersScreenV2 extends StatefulWidget {
  const OrdersScreenV2({super.key});

  @override
  State<OrdersScreenV2> createState() => _OrdersScreenV2State();
}

class _OrdersScreenV2State extends State<OrdersScreenV2> {
  final List<OrderSummary> _orders = [];
  final _scrollController = ScrollController();

  bool _loading = false;
  bool _firstLoad = true;
  bool _hasMore = true;
  int _page = 1;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200 &&
          !_loading &&
          _hasMore) {
        _load();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading) return;

    setState(() {
      _loading = true;
      _error = null;
      if (reset) {
        _orders.clear();
        _page = 1;
        _hasMore = true;
        _firstLoad = true;
      }
    });

    try {
      final page = await accountRepo.orders(page: _page);
      if (!mounted) return;

      setState(() {
        _orders.addAll(page.orders);
        _hasMore = page.hasMore;
        _page = page.currentPage + 1;
        _loading = false;
        _firstLoad = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
        _firstLoad = false;
      });
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'shipped':
        return Colors.blue;
      case 'processing':
        return Colors.orange;
      case 'cancelled':
      case 'refunded':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title:
        const Text('Siparişlerim', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _body(theme),
    );
  }

  Widget _body(ThemeData theme) {
    if (_firstLoad && _loading) {
      return const ListSkeleton(itemHeight: 76);
    }

    if (_error != null && _orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 44, color: Colors.grey),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(_error!, textAlign: TextAlign.center),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _load(reset: true),
              child: const Text('Tekrar dene'),
            ),
          ],
        ),
      );
    }

    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('Henüz siparişiniz yok',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    final isDark = theme.brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: () => _load(reset: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(12),
        itemCount: _orders.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _orders.length) {
            // Next page loading: a skeleton row keeps the list height steady.
            return const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Skeleton(height: 76, radious: 12),
            );
          }

          final order = _orders[index];

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor.withOpacity(0.3)),
            ),
            child: ListTile(
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              title: Text(
                order.orderNumber,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _statusColor(order.status).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        order.statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _statusColor(order.status),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(order.createdAt),
                      style:
                      const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    order.formattedTotal,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: primaryColor,
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 18),
                ],
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      OrderDetailScreenV2(orderNumber: order.orderNumber),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────

class OrderDetailScreenV2 extends StatefulWidget {
  const OrderDetailScreenV2({super.key, required this.orderNumber});

  final String orderNumber;

  @override
  State<OrderDetailScreenV2> createState() => _OrderDetailScreenV2State();
}

class _OrderDetailScreenV2State extends State<OrderDetailScreenV2> {
  OrderDetail? _order;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final order = await accountRepo.order(widget.orderNumber);
      if (!mounted) return;
      setState(() {
        _order = order;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.statusCode == 404 ? 'Sipariş bulunamadı.' : e.message;
        _loading = false;
      });
    }
  }

  String _money(double value) {
    final symbol = _order?.summary.currencySymbol ?? '₺';
    return '$symbol${value.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title:
        Text(widget.orderNumber, style: const TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const ListSkeleton(itemCount: 4, itemHeight: 110)
          : _order == null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error ?? 'Sipariş bulunamadı.'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _load,
              child: const Text('Tekrar dene'),
            ),
          ],
        ),
      )
          : ListView(
        padding: const EdgeInsets.all(14),
        children: [
          _card(
            isDark,
            theme,
            title: 'Durum',
            child: Text(
              _order!.summary.statusLabel,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          _card(
            isDark,
            theme,
            title: 'Ürünler',
            child: Column(
              children: _order!.items.map(_line).toList(),
            ),
          ),
          _card(
            isDark,
            theme,
            title: 'Özet',
            child: Column(
              children: [
                _row('Ara Toplam', _money(_order!.subtotal)),
                if (_order!.discount > 0)
                  _row('İndirim', '-${_money(_order!.discount)}'),
                _row('KDV', _money(_order!.tax)),
                _row(
                  'Kargo',
                  _order!.shippingCost == 0
                      ? 'Ücretsiz'
                      : _money(_order!.shippingCost),
                ),
                const Divider(),
                _row(
                  'Toplam',
                  _order!.summary.formattedTotal,
                  bold: true,
                ),
              ],
            ),
          ),
          if ((_order!.address ?? '').isNotEmpty)
            _card(
              isDark,
              theme,
              title: 'Teslimat Adresi',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if ((_order!.customerName ?? '').isNotEmpty)
                    Text(_order!.customerName!),
                  if ((_order!.phone ?? '').isNotEmpty)
                    Text(_order!.phone!),
                  const SizedBox(height: 4),
                  Text(_order!.address!),
                  Text([
                    _order!.city,
                    _order!.state,
                    _order!.postcode,
                  ].where((e) => (e ?? '').isNotEmpty).join(' / ')),
                ],
              ),
            ),
          if ((_order!.paymentMethod ?? '').isNotEmpty)
            _card(
              isDark,
              theme,
              title: 'Ödeme Yöntemi',
              child: Text(_order!.paymentMethod!),
            ),
          if ((_order!.notes ?? '').isNotEmpty)
            _card(
              isDark,
              theme,
              title: 'Sipariş Notu',
              child: Text(_order!.notes!),
            ),
        ],
      ),
    );
  }

  Widget _card(
      bool isDark,
      ThemeData theme, {
        required String title,
        required Widget child,
      }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
              )),
          Text(
            value,
            style: TextStyle(
              fontSize: bold ? 15 : 13,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: bold ? primaryColor : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _line(OrderLine item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: item.slug == null
            ? null
            : () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailsScreenV2(slug: item.slug!),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              padding: const EdgeInsets.all(4),
              child: item.thumb == null
                  ? const Icon(Icons.image_not_supported,
                  size: 20, color: Colors.grey)
                  : CachedNetworkImage(
                imageUrl: item.thumb!,
                fit: BoxFit.contain,
                memCacheWidth: 150,
                placeholder: (_, __) => const Skeleton(radious: 8),
                errorWidget: (_, __, ___) => const Icon(
                  Icons.broken_image,
                  size: 20,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if ((item.sku ?? '').isNotEmpty)
                    Text(
                      item.sku!,
                      style:
                      const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.quantity} x ${_money(item.unitPrice)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              _money(item.lineTotal),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}