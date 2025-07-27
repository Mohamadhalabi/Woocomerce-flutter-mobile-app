import 'package:flutter/material.dart';
import 'package:shop/constants.dart';
import 'package:shop/screens/search/views/components/search_form.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop/screens/search/views/global_search_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  DiscoverScreenState createState() => DiscoverScreenState(); // 🔓 Public state
}

class DiscoverScreenState extends State<DiscoverScreen> {
  List<String> previousSearches = [];

  @override
  void initState() {
    super.initState();
    loadPreviousSearches();
  }

  // 🔄 Called by EntryPoint to reload the tab
  Future<void> refresh() async {
    await loadPreviousSearches();
  }

  Future<void> loadPreviousSearches() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      previousSearches = prefs.getStringList('recent_searches') ?? [];
    });
  }

  Future<void> saveSearch(String query) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> updated = [query, ...previousSearches.where((q) => q != query)];
    if (updated.length > 10) updated = updated.sublist(0, 10);
    await prefs.setStringList('recent_searches', updated);
    setState(() => previousSearches = updated);
  }

  Future<void> clearSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('recent_searches');
    setState(() => previousSearches = []);
  }

  void handleSearch(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;

    saveSearch(trimmed);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GlobalSearchScreen(query: trimmed),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(defaultPadding),
            child: SearchForm(
              onFieldSubmitted: (value) {
                if (value != null) handleSearch(value);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: defaultPadding, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Önceki Aramalar",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                if (previousSearches.isNotEmpty)
                  TextButton(
                    onPressed: clearSearchHistory,
                    child: const Text("Temizle"),
                  ),
              ],
            ),
          ),
          if (previousSearches.isEmpty)
            const Padding(
              padding: EdgeInsets.all(defaultPadding),
              child: Text("Henüz arama yapılmadı."),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
              child: Wrap(
                spacing: 8,
                children: previousSearches.map((query) {
                  return ActionChip(
                    label: Text(query),
                    onPressed: () => handleSearch(query),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}