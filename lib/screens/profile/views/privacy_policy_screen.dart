import 'package:flutter/material.dart';
import 'package:shop/constants.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
          "Gizlilik ve Güvenlik Politikası",
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              "GİZLİLİK VE GÜVENLİK POLİTİKASI",
              "Mağazamızda verilen tüm servisler, Kuyuluk, Fındıkpınarı Cd, 36103. Sk. No:70, 33330 Mezitli/Mersin adresinde kayıtlı Anadolu Anahtar firmamıza aittir ve firmamız tarafından işletilir.",
              textColor,
            ),
            _buildSection(
              "KİŞİSEL VERİLERİN TOPLANMASI",
              "Firmamız, çeşitli amaçlarla kişisel veriler toplayabilir. Üyelik veya mağazamız üzerindeki çeşitli formların doldurulması suretiyle üyelerin kendileriyle ilgili bir takım kişisel bilgileri (isim-soy isim, firma bilgileri, telefon, adres veya e-posta adresleri gibi) Mağazamız tarafından işin doğası gereği toplanmaktadır.",
              textColor,
            ),
            _buildSection(
              "KREDİ KARTI GÜVENLİĞİ",
              "Firmamız, alışveriş sitelerimizden alışveriş yapan kredi kartı sahiplerinin güvenliğini ilk planda tutmaktadır. Kredi kartı bilgileriniz hiçbir şekilde sistemimizde saklanmamaktadır.\n\nİşlemler sürecine girdiğinizde güvenli bir sitede olduğunuzu anlamak için tarayıcınızın alt satırında bulunan bir anahtar ya da kilit simgesine dikkat ediniz. Bu güvenli bir internet sayfasında olduğunuzu gösterir ve her türlü bilginiz şifrelenerek korunur. Ödeme sırasında kullanılan kredi kartı ile ilgili bilgiler alışveriş sitelerimizden bağımsız olarak 128 bit SSL (Secure Sockets Layer) protokolü ile şifrelenip sorgulanmak üzere ilgili bankaya ulaştırılır.",
              textColor,
            ),
            _buildSection(
              "E-POSTA GÜVENLİĞİ",
              "Mağazamızın Müşteri Hizmetleri’ne, herhangi bir siparişinizle ilgili olarak göndereceğiniz e-postalarda, asla kredi kartı numaranızı veya şifrelerinizi yazmayınız. E-postalarda yer alan bilgiler üçüncü şahıslar tarafından görülebilir. Firmamız e-postalarınızdan aktarılan bilgilerin güvenliğini hiçbir koşulda garanti edemez.",
              textColor,
            ),
            _buildSection(
              "İLETİŞİM BİLGİLERİ",
              "Firma Ünvanı: Anadolu Anahtar\nAdres: Kuyuluk, Fındıkpınarı Cd, 36103. Sk. No:70, 33330 Mezitli/Mersin\nE-posta: satis@aanahtar.com.tr\nTelefon: +90 552 436 80 30",
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