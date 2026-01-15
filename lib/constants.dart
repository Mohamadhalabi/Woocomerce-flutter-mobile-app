import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  static final String baseUrl = dotenv.env['API_BASE_URL'] ?? '';
  static final String apiKey = dotenv.env['API_KEY'] ?? '';
  static final String secretKey = dotenv.env['SECRET_KEY'] ?? '';
}
// Just for demo
const productDemoImg1 = "";
const productDemoImg2 = "";
const productDemoImg3 = "";
const productDemoImg4 = "";
const productDemoImg5 = "";
const productDemoImg6 = "";

// End For demo
String fixHtml(String text) {
  return text
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#039;', "'")
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>');
}
const grandisExtendedFont = "Poppins";

// Turkish state codes to city names (WooCommerce style)
const Map<String, String> trStateMap = {
  "TR01": "Adana",
  "TR02": "Adıyaman",
  "TR03": "Afyonkarahisar",
  "TR04": "Ağrı",
  "TR05": "Amasya",
  "TR06": "Ankara",
  "TR07": "Antalya",
  "TR08": "Artvin",
  "TR09": "Aydın",
  "TR10": "Balıkesir",
  "TR11": "Bilecik",
  "TR12": "Bingöl",
  "TR13": "Bitlis",
  "TR14": "Bolu",
  "TR15": "Burdur",
  "TR16": "Bursa",
  "TR17": "Çanakkale",
  "TR18": "Çankırı",
  "TR19": "Çorum",
  "TR20": "Denizli",
  "TR21": "Diyarbakır",
  "TR22": "Edirne",
  "TR23": "Elazığ",
  "TR24": "Erzincan",
  "TR25": "Erzurum",
  "TR26": "Eskişehir",
  "TR27": "Gaziantep",
  "TR28": "Giresun",
  "TR29": "Gümüşhane",
  "TR30": "Hakkâri",
  "TR31": "Hatay",
  "TR32": "Isparta",
  "TR33": "Mersin",
  "TR34": "İstanbul",
  "TR35": "İzmir",
  "TR36": "Kars",
  "TR37": "Kastamonu",
  "TR38": "Kayseri",
  "TR39": "Kırklareli",
  "TR40": "Kırşehir",
  "TR41": "Kocaeli",
  "TR42": "Konya",
  "TR43": "Kütahya",
  "TR44": "Malatya",
  "TR45": "Manisa",
  "TR46": "Kahramanmaraş",
  "TR47": "Mardin",
  "TR48": "Muğla",
  "TR49": "Muş",
  "TR50": "Nevşehir",
  "TR51": "Niğde",
  "TR52": "Ordu",
  "TR53": "Rize",
  "TR54": "Sakarya",
  "TR55": "Samsun",
  "TR56": "Siirt",
  "TR57": "Sinop",
  "TR58": "Sivas",
  "TR59": "Tekirdağ",
  "TR60": "Tokat",
  "TR61": "Trabzon",
  "TR62": "Tunceli",
  "TR63": "Şanlıurfa",
  "TR64": "Uşak",
  "TR65": "Van",
  "TR66": "Yozgat",
  "TR67": "Zonguldak",
  "TR68": "Aksaray",
  "TR69": "Bayburt",
  "TR70": "Karaman",
  "TR71": "Kırıkkale",
  "TR72": "Batman",
  "TR73": "Şırnak",
  "TR74": "Bartın",
  "TR75": "Ardahan",
  "TR76": "Iğdır",
  "TR77": "Yalova",
  "TR78": "Karabük",
  "TR79": "Kilis",
  "TR80": "Osmaniye",
  "TR81": "Düzce"
};
// On color 80, 60.... those means opacity

const Color primaryColor = Color(0xFF2D83B0);

const MaterialColor primaryMaterialColor =
    MaterialColor(0xFF9581FF, <int, Color>{
  50: Color(0xFFEFECFF),
  100: Color(0xFFD7D0FF),
  200: Color(0xFFBDB0FF),
  300: Color(0xFFA390FF),
  400: Color(0xFF8F79FF),
  500: Color(0xFF7B61FF),
  600: Color(0xFF7359FF),
  700: Color(0xFF684FFF),
  800: Color(0xFF5E45FF),
  900: Color(0xFF6C56DD),
});

const Color blackColor = Color(0xFF16161E);
const Color blackColor80 = Color(0xFF45454B);
const Color blackColor60 = Color(0xFF737378);
const Color blackColor40 = Color(0xFFA2A2A5);
const Color blackColor20 = Color(0xFFD0D0D2);
const Color blackColor10 = Color(0xFFE8E8E9);
const Color blackColor5 = Color(0xFFF3F3F4);

const Color whiteColor = Colors.white;
const Color whileColor80 = Color(0xFFCCCCCC);
const Color whileColor60 = Color(0xFF999999);
const Color whileColor40 = Color(0xFF666666);
const Color whileColor20 = Color(0xFF333333);
const Color whileColor10 = Color(0xFF191919);
const Color whileColor5 = Color(0xFF0D0D0D);

const Color greyColor = Color(0xFFB8B5C3);
const Color lightGreyColor = Color(0xFFF8F8F9);
const Color darkGreyColor = Color(0xFF1C1C25);
const Color greenColor = Color(0xFF556B2F);
const Color redColor = Color(0xFF892118);
const Color blueColor = Color(0xFF13699D);
// const Color greyColor80 = Color(0xFFC6C4CF);
// const Color greyColor60 = Color(0xFFD4D3DB);
// const Color greyColor40 = Color(0xFFE3E1E7);
// const Color greyColor20 = Color(0xFFF1F0F3);
// const Color greyColor10 = Color(0xFFF8F8F9);
// const Color greyColor5 = Color(0xFFFBFBFC);

const Color purpleColor = Color(0xFF7B61FF);
const Color successColor = Color(0xFF2ED573);
const Color warningColor = Color(0xFFFFBE21);
const Color errorColor = Color(0xFFEA5B5B);

const double defaultPadding = 16.0;
const double defaultBorderRadious = 12.0;
const Duration defaultDuration = Duration(milliseconds: 300);

final passwordValidator = MultiValidator([
  RequiredValidator(errorText: 'Password is required'),
  MinLengthValidator(8, errorText: 'password must be at least 8 digits long'),
  PatternValidator(r'(?=.*?[#?!@$%^&*-])',
      errorText: 'passwords must have at least one special character')
]);

final emaildValidator = MultiValidator([
  RequiredValidator(errorText: 'Email is required'),
  EmailValidator(errorText: "Enter a valid email address"),
]);

const pasNotMatchErrorText = "passwords do not match";
