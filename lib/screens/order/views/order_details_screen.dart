import 'package:flutter/material.dart';
import '../../../constants.dart';
import '../../../entry_point.dart';
import '../../../services/api_service.dart';
import '../../../services/alert_service.dart';

class OrderDetailsScreen extends StatefulWidget {
  final int orderId;
  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  late Future<Map<String, dynamic>> _detailsFuture;

  @override
  void initState() {
    super.initState();
    _detailsFuture = _fetch();
  }

  Future<Map<String, dynamic>> _fetch() async {
    try {
      return await ApiService.fetchOrderDetails(widget.orderId);
    } catch (e) {
      AlertService.showTopAlert(context, "Sipariş detayları alınamadı: $e", isError: true);
      rethrow;
    }
  }

  // Styled Card helper (white + full border in light mode)
  Card buildStyledCard({
    required Widget child,
    EdgeInsets? margin,
    EdgeInsetsGeometry? padding,
  }) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Card(
      color: isLight ? Colors.white : theme.cardColor,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isLight ? Colors.grey.shade300 : Colors.grey.shade700,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      margin: margin ?? const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(14),
        child: child,
      ),
    );
  }

  // Money formatter (very simple)
  String _money(dynamic val, String currency) {
    if (val == null) return "0 $currency";
    final s = val.toString();
    return "$s $currency";
  }

  // Sum line_items total values (as num if possible, else fallback to string concat-safe)
  num _sumLineTotals(List items) {
    num total = 0;
    for (final it in items) {
      final map = it as Map<String, dynamic>;
      final t = map['total'];
      if (t is num) {
        total += t;
      } else {
        // Woo often sends as string like "2442.00"
        final parsed = num.tryParse((t ?? '0').toString()) ?? 0;
        total += parsed;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final borderColor = isLight ? Colors.grey.shade300 : Colors.grey.shade700;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("Sipariş #${widget.orderId}"),
        backgroundColor: blueColor,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _detailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Text(
                "Detaylar yüklenemedi.\n${snapshot.error ?? ''}",
                textAlign: TextAlign.center,
              ),
            );
          }

          final details = snapshot.data!;
          final currency = details['currency_symbol'] ?? '₺';
          final lineItems = (details['line_items'] as List?) ?? [];

          // Compute summary numbers with safe fallbacks
          final subtotalFromApi = details['subtotal'];
          final subtotal = subtotalFromApi ??
              _sumLineTotals(lineItems); // fallback: sum of line item totals

          final totalTaxRaw = details['total_tax']; // may be string like "488.40"
          final totalTax = () {
            if (totalTaxRaw is num) return totalTaxRaw;
            return num.tryParse((totalTaxRaw ?? '0').toString()) ?? 0;
          }();

          final totalRaw = details['total'];
          final total = () {
            if (totalRaw is num) return totalRaw;
            return num.tryParse((totalRaw ?? '0').toString()) ?? 0;
          }();

          final paymentMethod = details['payment_method_title'] ?? '';

          // ===== UI =====
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              // SİPARİŞ ÖZETİ (Woo-style table)
              buildStyledCard(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Text(
                        "Sipariş Özeti",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                    ),
                    // Table
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                      decoration: BoxDecoration(
                        border: Border.all(color: borderColor, width: 1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Table(
                        columnWidths: const {
                          0: FlexColumnWidth(3), // Ürün
                          1: FlexColumnWidth(1), // Toplam
                        },
                        border: TableBorder.symmetric(
                          inside: BorderSide(color: borderColor, width: 1),
                          outside: BorderSide.none,
                        ),
                        children: [
                          // Header row
                          TableRow(
                            decoration: BoxDecoration(
                              color: isLight ? Colors.grey.shade100 : Colors.black12,
                              border: Border(
                                bottom: BorderSide(color: borderColor, width: 1),
                              ),
                            ),
                            children: [
                              _tableHeaderCell("Ürün", left: true),
                              _tableHeaderCell("Toplam"),
                            ],
                          ),

                          // Line items
                          ...lineItems.map((item) {
                            final map = item as Map<String, dynamic>;
                            final img = (map['image'] as Map?)?['src'] as String?;
                            final qty = map['quantity'];
                            final name = map['name'] ?? '';
                            final lineTotal = map['total']; // string or num

                            return TableRow(
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: borderColor, width: 1),
                                ),
                              ),
                              children: [
                                // Ürün cell (image + name + ×qty)
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      if (img != null)
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            img,
                                            width: 40,
                                            height: 40,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      else
                                        const Icon(Icons.image_not_supported, size: 40),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: RichText(
                                          text: TextSpan(
                                            style: theme.textTheme.bodyMedium,
                                            children: [
                                              TextSpan(text: name),
                                              TextSpan(
                                                text: "  × $qty",
                                                style: const TextStyle(fontWeight: FontWeight.w600),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Toplam cell
                                _tableValueCell(
                                  _money(lineTotal, currency),
                                  alignRight: true,
                                ),
                              ],
                            );
                          }),

                          // Ara toplam
                          TableRow(
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: borderColor, width: 1),
                              ),
                            ),
                            children: [
                              _tableLabelCell("Ara toplam:"),
                              _tableValueCell(_money(subtotal, currency), alignRight: true),
                            ],
                          ),

                          // KDV
                          TableRow(
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: borderColor, width: 1),
                              ),
                            ),
                            children: [
                              _tableLabelCell("KDV:"),
                              _tableValueCell(_money(totalTax, currency), alignRight: true),
                            ],
                          ),

                          // Ödeme yöntemi
                          TableRow(
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: borderColor, width: 1),
                              ),
                            ),
                            children: [
                              _tableLabelCell("Ödeme yöntemi:"),
                              _tableValueCell(paymentMethod, alignRight: true),
                            ],
                          ),

                          // Toplam
                          TableRow(
                            children: [
                              _tableLabelCell("Toplam:", bold: true),
                              _tableValueCell(
                                _money(total, currency),
                                alignRight: true,
                                bold: true,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),

              // TESLİMAT ADRESİ
              if ((details['shipping'] as Map<String, dynamic>?)?.isNotEmpty ?? false)
                buildStyledCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Teslimat Adresi",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(_formatAddress(details['shipping'] as Map<String, dynamic>)),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.bottomNavigationBarTheme.backgroundColor ?? theme.cardColor,
          boxShadow: [
            BoxShadow(
              color: theme.brightness == Brightness.dark ? Colors.black54 : Colors.black12,
              offset: const Offset(0, -2),
              blurRadius: 6,
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: 4,
          onTap: (index) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => EntryPoint(
                  onLocaleChange: (_) {},
                  initialIndex: index,
                ),
              ),
            );
          },
          selectedItemColor: primaryColor,
          unselectedItemColor: theme.unselectedWidgetColor,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Anasayfa"),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: "Keşfet"),
            BottomNavigationBarItem(icon: Icon(Icons.store), label: "Mağaza"),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: "Sepet"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
          ],
        ),
      ),
    );
  }

  // --- Table cell builders ---

  Widget _tableHeaderCell(String text, {bool left = false}) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w600,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Align(
        alignment: left ? Alignment.centerLeft : Alignment.centerRight,
        child: Text(text, style: style),
      ),
    );
  }

  Widget _tableLabelCell(String text, {bool bold = false}) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(text, style: style),
    );
  }

  Widget _tableValueCell(String text, {bool alignRight = false, bool bold = false}) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Align(
        alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
        child: Text(text, style: style),
      ),
    );
  }

  Widget _kv(String k, String v, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: const TextStyle(color: Colors.grey)),
          Text(v, style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
        ],
      ),
    );
  }

  String _formatAddress(Map<String, dynamic> s) {
    final name = [s['first_name'], s['last_name']]
        .where((e) => (e ?? '').toString().isNotEmpty)
        .join(' ');
    final lines = [
      name,
      s['address_1'],
      s['address_2'],
      "${s['postcode'] ?? ''} ${s['city'] ?? ''}",
      s['state'],
      s['country'],
      s['phone'],
    ].where((e) => (e ?? '').toString().trim().isNotEmpty).join('\n');
    return lines;
  }
}
