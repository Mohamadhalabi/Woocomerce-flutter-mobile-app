import 'package:flutter/material.dart';
import 'package:shop/constants.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Sıkça Sorulan Sorular",
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildFAQItem(
            context,
            "Siparişimi nasıl takip edebilirim?",
            "Siparişinizi verdikten sonra 'Hesabım > Siparişlerim' sayfasından kargo durumunu anlık olarak takip edebilirsiniz.",
          ),
          _buildFAQItem(
            context,
            "Hangi ödeme yöntemleri geçerli?",
            "Kredi kartı, banka kartı ve havale/EFT yöntemleri ile güvenli bir şekilde ödeme yapabilirsiniz. Tüm işlemler 128-bit SSL ile korunmaktadır.",
          ),
          _buildFAQItem(
            context,
            "Aldığım kumanda aracıma uyumlu mu?",
            "Ürün detay sayfasında belirtilen marka, model ve yıl bilgilerini kontrol ediniz. Emin değilseniz, WhatsApp destek hattımızdan şase numaranız ile teyit alabilirsiniz.",
          ),
          _buildFAQItem(
            context,
            "İade ve değişim koşulları nelerdir?",
            "Satın aldığınız ürünü, ambalajı açılmamış ve kullanılmamış olması şartıyla 14 gün içinde iade edebilirsiniz. Kodlanmış veya işlem görmüş ürünlerin iadesi mümkün değildir.",
          ),
          _buildFAQItem(
            context,
            "Kargom ne zaman ulaşır?",
            "Saat 16:00'a kadar verilen siparişler aynı gün kargoya verilir. Teslimat süresi bulunduğunuz ile göre 1-3 iş günü arasında değişmektedir.",
          ),
          _buildFAQItem(
            context,
            "Toptan satışınız var mı?",
            "Evet, çilingir ve anahtarcı meslektaşlarımız için toptan satışımız mevcuttur. Bayi kaydı oluşturmak için bizimle iletişime geçebilirsiniz.",
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(BuildContext context, String question, String answer) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        // ✅ High Contrast Background
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white24 : theme.dividerColor.withOpacity(0.3),
        ),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: primaryColor,
          collapsedIconColor: isDark ? Colors.white70 : Colors.grey,
          title: Text(
            question,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14.5,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                answer,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}