import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../constants.dart';
import '../../../entry_point.dart';
import '../../../services/api_service.dart';
import 'order_details_screen.dart';

class OrdersScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? orders;

  const OrdersScreen({super.key, this.orders});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late Future<List<Map<String, dynamic>>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    if (widget.orders != null && widget.orders!.isNotEmpty) {
      _ordersFuture = Future.value(widget.orders!);
    } else {
      _ordersFuture = ApiService.fetchUserOrders();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final borderColor = isLight ? Colors.grey.shade300 : Colors.grey.shade700;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Siparişlerim"),
        backgroundColor: blueColor,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Siparişler alınamadı: ${snapshot.error}",
                textAlign: TextAlign.center,
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Henüz siparişiniz yok."));
          }

          final orders = snapshot.data!;

          return LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 600;

              // ----- Narrow screens: stacked responsive “cards” (no horizontal scroll) -----
              if (isNarrow) {
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: orders.length,
                  itemBuilder: (context, i) {
                    final o = orders[i];
                    final id = o['id'];
                    final date = (o['date_created'] ?? '').toString();
                    final formattedDate = date.isNotEmpty
                        ? DateFormat("d MMMM yyyy", "tr_TR").format(DateTime.parse(date))
                        : '-';
                    final status = (o['status'] ?? '').toString();
                    final total = (o['total'] ?? '').toString();
                    final currency = (o['currency_symbol'] ?? '₺').toString();
                    final itemCount = (o['line_items'] as List?)?.length ?? 0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isLight ? Colors.white : theme.cardColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderColor, width: 1),
                      ),
                      child: Column(
                        children: [
                          _rowKV(context, "Sipariş", "#$id", borderColor),
                          _rowKV(context, "Tarih", formattedDate, borderColor),
                          _rowKV(context, "Durum", _statusLabel(status), borderColor),
                          _rowKV(context, "Toplam", "$itemCount ürün için $total $currency", borderColor),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => OrderDetailsScreen(orderId: id),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isLight ? Colors.grey.shade200 : Colors.grey.shade800,
                                  foregroundColor: theme.textTheme.bodyMedium?.color,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  elevation: 0,
                                ),
                                icon: const Icon(Icons.visibility, size: 16),
                                label: const Text("Görüntüle"),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }

              // ----- Wide screens: full-width table (no horizontal scroll) -----
              return ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: isLight ? Colors.white : theme.cardColor,
                      border: Border.all(color: borderColor, width: 1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Table(
                      columnWidths: const {
                        0: FlexColumnWidth(1.2), // Sipariş
                        1: FlexColumnWidth(1.8), // Tarih
                        2: FlexColumnWidth(1.6), // Durum
                        3: FlexColumnWidth(2.4), // Toplam
                        4: FlexColumnWidth(1.6), // Eylemler
                      },
                      border: TableBorder.symmetric(
                        inside: BorderSide(color: borderColor, width: 1),
                        outside: BorderSide.none,
                      ),
                      children: [
                        TableRow(
                          decoration: BoxDecoration(
                            color: isLight ? Colors.grey.shade100 : Colors.black12,
                            border: Border(bottom: BorderSide(color: borderColor, width: 1)),
                          ),
                          children: [
                            _headerCell("Sipariş"),
                            _headerCell("Tarih"),
                            _headerCell("Durum"),
                            _headerCell("Toplam"),
                            _headerCell("Eylemler"),
                          ],
                        ),
                        ...orders.map((o) {
                          final id = o['id'];
                          final date = (o['date_created'] ?? '').toString();
                          final formattedDate = date.isNotEmpty
                              ? DateFormat("d MMMM yyyy", "tr_TR").format(DateTime.parse(date))
                              : '-';
                          final status = (o['status'] ?? '').toString();
                          final total = (o['total'] ?? '').toString();
                          final currency = (o['currency_symbol'] ?? '₺').toString();
                          final itemCount = (o['line_items'] as List?)?.length ?? 0;

                          return TableRow(
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: borderColor, width: 1)),
                            ),
                            children: [
                              _cell("#$id"),
                              _cell(formattedDate),
                              _cell(_statusLabel(status)),
                              _cell("$itemCount ürün için $total $currency"),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => OrderDetailsScreen(orderId: id),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isLight ? Colors.grey.shade200 : Colors.grey.shade800,
                                      foregroundColor: theme.textTheme.bodyMedium?.color,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      elevation: 0,
                                    ),
                                    icon: const Icon(Icons.visibility, size: 16),
                                    label: const Text("Görüntüle"),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              );
            },
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

  // ---------- helpers ----------

  Widget _rowKV(BuildContext context, String label, String value, Color borderColor) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
      ),
      child: Row(
        children: [
          // label
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          // value
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Text(value, textAlign: TextAlign.right),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _cell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case "completed":
        return "Tamamlandı";
      case "cancelled":
        return "İptal edildi";
      case "processing":
        return "İşleniyor";
      default:
        return status;
    }
  }
}
