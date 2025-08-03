import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart' as img_picker;
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SearchForm extends StatelessWidget {
  const SearchForm({
    super.key,
    this.formKey,
    this.isEnabled = true,
    this.onSaved,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.focusNode,
    this.autofocus = false,
  });

  final GlobalKey<FormState>? formKey;
  final bool isEnabled;
  final ValueChanged<String?>? onSaved, onChanged, onFieldSubmitted;
  final FormFieldValidator<String>? validator;
  final FocusNode? focusNode;
  final bool autofocus;

  static Map<String, String> locksmithMap = {};

  /// Load JSON mapping from assets
  static Future<void> loadLocksmithMapping() async {
    final String jsonString =
    await rootBundle.loadString('assets/locksmith_mapping.json');
    locksmithMap = Map<String, String>.from(json.decode(jsonString));
  }

  static const List<String> ignoreColors = [
    "gümüş", "siyah", "beyaz", "mavi", "kırmızı", "yeşil",
    "gri", "kahverengi", "turuncu", "mor", "altın", "bej"
  ];

  String get googleApiKey => dotenv.env['GOOGLE_API_KEY'] ?? "";

  /// OCR special keywords
  static final Map<String, String> ocrKeywordMap = {
    "mqb adapter": "mqb",
    "vvdi": "vvdi",
    "key tool": "vvdi",
    "mini key tool": "vvdi",
    "remote": "kumanda",
    "xhorse": "xhorse"
  };

  /// Clean label by removing colors
  String cleanLabel(String label) {
    return SearchForm.ignoreColors.contains(label.toLowerCase()) ? "" : label;
  }

  /// Map Vision label to locksmith term
  String mapLabelToTurkish(String? label) {
    if (label == null) return "";
    label = cleanLabel(label.toLowerCase());

    if (label.isEmpty) return "";

    // Check JSON mapping first
    if (locksmithMap.containsKey(label)) {
      return locksmithMap[label]!;
    }

    // ✅ Car/vehicle related keywords → kumanda
    if (label.contains("araba") ||
        label.contains("araç") ||
        label.contains("car") ||
        label.contains("vehicle")) {
      return "kumanda";
    }

    // Fallback remote detection
    if (label.contains("remote") || label.contains("kumanda") || label.contains("fob")) {
      return "kumanda";
    }

    return label;
  }

  /// Shorten query to 1 word
  String shortenQuery(String query) {
    query = query.trim();
    if (query.split(" ").length > 1) {
      return query.split(" ").first;
    }
    return query;
  }

  /// Vision API detection
  Future<Map<String, dynamic>> detectLabelsLogosAndText(File imageFile) async {
    final uri = Uri.parse(
      'https://vision.googleapis.com/v1/images:annotate?key=$googleApiKey',
    );

    final imageBytes = base64Encode(await imageFile.readAsBytes());

    final body = jsonEncode({
      "requests": [
        {
          "image": {"content": imageBytes},
          "features": [
            {"type": "LABEL_DETECTION", "maxResults": 10},
            {"type": "LOGO_DETECTION", "maxResults": 3},
            {"type": "TEXT_DETECTION", "maxResults": 5}
          ]
        }
      ]
    });

    final response = await http.post(uri, body: body);
    if (response.statusCode != 200) {
      throw Exception("Vision API error: ${response.body}");
    }

    final data = jsonDecode(response.body);

    final labels = data['responses'][0]['labelAnnotations'] as List? ?? [];
    final logos = data['responses'][0]['logoAnnotations'] as List? ?? [];
    final textAnnotations = data['responses'][0]['textAnnotations'] as List? ?? [];

    List<String> allLabels = labels
        .map((l) => cleanLabel(l['description'].toString()))
        .where((l) => l.isNotEmpty)
        .toList();

    String? brand = logos.isNotEmpty ? logos.first['description'] : null;
    String? ocrText = textAnnotations.isNotEmpty
        ? textAnnotations.first['description'].toLowerCase()
        : null;

    return {"labels": allLabels, "brand": brand, "ocr": ocrText};
  }

  /// Google Translate API
  Future<String> translateToTurkish(String text) async {
    final uri = Uri.parse(
      'https://translation.googleapis.com/language/translate/v2?key=$googleApiKey',
    );

    final body = jsonEncode({"q": text, "target": "tr", "format": "text"});

    final response = await http.post(uri, body: body, headers: {
      "Content-Type": "application/json"
    });

    if (response.statusCode != 200) {
      throw Exception("Translate API error: ${response.body}");
    }

    final data = jsonDecode(response.body);
    return data['data']['translations'][0]['translatedText'];
  }

  /// Main camera logic
  void openCamera(BuildContext context) async {
    final picker = img_picker.ImagePicker();
    final pickedFile = await picker.pickImage(source: img_picker.ImageSource.camera);
    if (pickedFile == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await detectLabelsLogosAndText(File(pickedFile.path));
      List<String> labels = List<String>.from(result["labels"]);
      String? brand = result["brand"];
      String? ocrText = result["ocr"];

      String mappedLabel = labels.isNotEmpty ? mapLabelToTurkish(labels.first) : "";

      String? ocrMatch;
      if (ocrText != null && ocrText.isNotEmpty) {
        for (var entry in ocrKeywordMap.entries) {
          if (ocrText.contains(entry.key)) {
            ocrMatch = entry.value;
            break;
          }
        }
      }

      String finalQuery = "";
      if (ocrMatch != null && brand != null) {
        finalQuery = "$brand $ocrMatch";
      } else if (ocrMatch != null) {
        finalQuery = ocrMatch;
      } else if (brand != null && mappedLabel.isNotEmpty) {
        finalQuery = "$brand $mappedLabel";
      } else {
        finalQuery = brand ?? mappedLabel;
      }

      finalQuery = shortenQuery(finalQuery);

      if (finalQuery.isNotEmpty &&
          !RegExp(r'[ğüşöçıİĞÜŞÖÇ]').hasMatch(finalQuery)) {
        finalQuery = await translateToTurkish(finalQuery);
      }

      Navigator.pop(context);

      if (finalQuery.isNotEmpty && onFieldSubmitted != null) {
        onFieldSubmitted!(finalQuery);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ürün tespit edilemedi.")),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Görsel arama hatası: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      child: TextFormField(
        autofocus: autofocus,
        focusNode: focusNode,
        enabled: isEnabled,
        onChanged: onChanged,
        onSaved: onSaved,
        onFieldSubmitted: onFieldSubmitted,
        validator: validator,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: "Ürün ara...",
          filled: true,
          fillColor: Theme.of(context).cardColor,
          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: SvgPicture.asset(
              "assets/icons/Search.svg",
              height: 22,
              color: Theme.of(context).iconTheme.color!.withOpacity(0.3),
            ),
          ),
          suffixIcon: IconButton(
            icon: const Icon(Icons.camera_alt_outlined, size: 20),
            onPressed: () => openCamera(context),
          ),
        ),
      ),
    );
  }
}
