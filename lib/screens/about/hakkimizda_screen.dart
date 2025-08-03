import 'package:flutter/material.dart';
import '../../../constants.dart';
import '../../entry_point.dart';

class HakkimizdaScreen extends StatelessWidget {
  final Function(String) onLocaleChange;

  static const int homeIndex = 0;
  static const int searchIndex = 1;
  static const int storeIndex = 2;
  static const int cartIndex = 3;
  static const int profileIndex = 4;

  const HakkimizdaScreen({super.key, required this.onLocaleChange});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget sectionTitle(String title) {
      return Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
      );
    }

    Widget sectionText(String text) {
      return Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Hakkımızda", style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sectionTitle("Biz Neler Yapıyoruz?"),
            sectionText(
              "Anadolu Anahtar olarak, oto anahtar, immobilizer, otomasyon ve merkezi kilit sistemleri gibi ürünlerin ithalatını ve pazarlamasını yapıyoruz. "
                  "Müşterilerimize, işleri için yenilikçi ve güvenilir çözümler sunuyoruz.",
            ),

            sectionTitle("Vizyonumuz Nedir?"),
            sectionText(
              "Vizyonumuz, sektörde lider bir firma olarak, en kaliteli ürün ve hizmetleri sunmak ve yenilikçi çözümlerle müşterilerimizin işlerini iyileştirmektir.",
            ),

            sectionTitle("Şirketimizin Kuruluşu"),
            sectionText(
              "2018 yılında Mersin’de kurulan Anadolu Anahtar, kısa sürede otomotiv ve anahtarcılık sektörlerinde güvenilir bir marka haline geldi.",
            ),

            sectionTitle("Ekibimiz"),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _teamMember("Kerem", "Satış"),
                _teamMember("Huseyin", "Satış"),
                _teamMember("Ziya", "Satış"),
                _teamMember("Emin", "Satış"),
              ],
            ),

            sectionTitle("Sizin İçin Neler Yapabiliriz?"),
            sectionText(
              "Geniş ürün yelpazemizle, işinizi büyütmek ve güvenliğini artırmak için gerekli çözümleri sunuyoruz.",
            ),

            sectionTitle("Bizimle İşbirliği Yapın"),
            sectionText(
              "Kaliteli ürünlerimiz ve çözüm odaklı hizmetlerimizle, işinizi daha verimli hale getirmek için birlikte çalışabiliriz.",
            ),

            sectionTitle("Neden Anadolu Anahtar?"),
            sectionText(
              "Anadolu Anahtar, güvenilirlik, kalite, hızlı çözümler ve müşteri odaklı hizmet anlayışıyla öne çıkar. "
                  "Sektördeki tecrübemiz ve yenilikçi yaklaşımımızla, müşterilerimize en iyi ürün ve hizmetleri sunmayı taahhüt ediyoruz. "
                  "Bizimle çalışmak, sadece ihtiyaçlarınızı karşılamakla kalmaz, aynı zamanda işlerinizi daha güvenli ve verimli hale getirir. "
                  "Anadolu Anahtar’ı tercih ederek, işinizi güçlü bir ortakla bir adım öne taşırsınız.",
            ),
          ],
        ),
      ),

      // ✅ BottomNavigationBar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.bottomNavigationBarTheme.backgroundColor ??
              theme.cardColor,
          boxShadow: [
            BoxShadow(
              color: theme.brightness == Brightness.dark
                  ? Colors.black54
                  : Colors.black12,
              offset: const Offset(0, -2),
              blurRadius: 6,
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: theme.bottomNavigationBarTheme.backgroundColor ??
              theme.cardColor,
          currentIndex: profileIndex,
          onTap: (index) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => EntryPoint(
                  onLocaleChange: onLocaleChange,
                  initialIndex: index,
                ),
              ),
            );
          },
          selectedItemColor: primaryColor,
          unselectedItemColor: theme.unselectedWidgetColor,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home), label: "Anasayfa"),
            BottomNavigationBarItem(
                icon: Icon(Icons.search), label: "Keşfet"),
            BottomNavigationBarItem(
                icon: Icon(Icons.store), label: "Mağaza"),
            BottomNavigationBarItem(
                icon: Icon(Icons.shopping_bag), label: "Sepet"),
            BottomNavigationBarItem(
                icon: Icon(Icons.person), label: "Profil"),
          ],
        ),
      ),
    );
  }

  Widget _teamMember(String name, String role) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: primaryColor.withOpacity(0.15),
          child: Icon(Icons.person, size: 30, color: primaryColor),
        ),
        const SizedBox(height: 6),
        Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(role, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
