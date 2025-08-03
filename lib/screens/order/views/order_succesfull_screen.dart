import 'package:flutter/material.dart';
import '../../../constants.dart';
import '../../../entry_point.dart';
import '../../../route/route_constants.dart';

class OrderSuccessScreen extends StatelessWidget {
  final int orderId;

  const OrderSuccessScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Sipariş Başarılı', style: TextStyle(color: Colors.white)),
        backgroundColor: blueColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 80),
              const SizedBox(height: 20),
              Text(
                "Siparişiniz başarıyla oluşturuldu!",
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                "Sipariş Numaranız: #$orderId",
                style: theme.textTheme.titleMedium?.copyWith(color: blueColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: blueColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pushNamed(context, '/orders');
                      },
                      child: const Text("Siparişe Git"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: blueColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EntryPoint(
                                onLocaleChange: (_) {},
                                initialIndex: 0, // Home tab
                              ),
                            ),
                                (route) => false,
                          );
                        },
                      child: const Text("Ana Sayfa"),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}