import 'package:flutter/material.dart';
import 'package:shop/constants.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

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
          "Kullanıcı Sözleşmesi",
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              "1. TARAFLAR",
              "İşbu Sözleşme aşağıdaki taraflar arasında aşağıda belirtilen hüküm ve şartlar çerçevesinde imzalanmıştır.\n\n'ALICI'; (sözleşmede bundan sonra \"ALICI\" olarak anılacaktır)\n'SATICI'; (sözleşmede bundan sonra \"SATICI\" olarak anılacaktır)\n\nAd: Anadolu Anahtar\nAdres: Kuyuluk, Fındıkpınarı Cd, 36103. Sk. No:70, 33330 Mezitli/Mersin",
              textColor,
            ),
            _buildSection(
              "2. KONU",
              "İşbu Sözleşme, ALICI’nın, SATICI’ya ait mobil uygulama üzerinden elektronik ortamda siparişini verdiği aşağıda nitelikleri ve satış fiyatı belirtilen ürünün satışı ve teslimi ile ilgili olarak 6502 sayılı Tüketicinin Korunması Hakkında Kanun ve Mesafeli Sözleşmelere Dair Yönetmelik hükümleri gereğince tarafların hak ve yükümlülüklerinin saptanmasıdır.",
              textColor,
            ),
            _buildSection(
              "3. GENEL HÜKÜMLER",
              "3.1. ALICI, mobil uygulamada sözleşme konusu ürünün temel nitelikleri, satış fiyatı ve ödeme şekli ile teslimata ilişkin ön bilgileri okuyup bilgi sahibi olduğunu, elektronik ortamda gerekli teyidi verdiğini kabul, beyan ve taahhüt eder.\n\n3.2. Sözleşme konusu her bir ürün, 30 günlük yasal süreyi aşmamak kaydı ile ALICI'nın yerleşim yeri uzaklığına bağlı olarak internet sitesindeki ön bilgiler kısmında belirtilen süre zarfında ALICI veya gösterdiği adresteki kişi/kuruluşa teslim edilir.",
              textColor,
            ),
            _buildSection(
              "4. CAYMA HAKKI",
              "ALICI; mal satışına ilişkin mesafeli sözleşmelerde, ürünün kendisine veya gösterdiği adresteki kişi/kuruluşa teslim tarihinden itibaren 14 (on dört) gün içerisinde, SATICI’ya bildirmek şartıyla hiçbir hukuki ve cezai sorumluluk üstlenmeksizin ve hiçbir gerekçe göstermeksizin malı reddederek sözleşmeden cayma hakkına sahiptir. Elektronik ortamda anında ifa edilen hizmetler veya tüketiciye anında teslim edilen gayrimaddi mallar (örneğin; yazılım, dijital kodlar vb.) cayma hakkı kapsamı dışındadır.",
              textColor,
            ),
            _buildSection(
              "5. YETKİLİ MAHKEME",
              "İşbu sözleşmeden doğan uyuşmazlıklarda şikayet ve itirazlar, Mersin Mahkemeleri ve İcra Daireleri yetkilidir.",
              textColor,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}