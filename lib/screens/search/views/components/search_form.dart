import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:image_picker/image_picker.dart' as img_picker;

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

  void openCamera(BuildContext context) async {
    final picker = img_picker.ImagePicker();
    await picker.pickImage(source: img_picker.ImageSource.camera);
    // TODO: handle image result
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
          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14), // ✅ reduce height
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