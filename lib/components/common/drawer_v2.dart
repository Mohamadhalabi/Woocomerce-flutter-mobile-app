// lib/components/common/drawer_v2.dart
//
// Same drawer, new API, and nothing loads until it's needed.
//
// The original fetched categories, brands and manufacturers together the
// moment the drawer was built — three lists most people never expand. Each
// section here fetches on its first expand, then TaxonomyService keeps it in
// memory and on disk, so every later open is instant.

import 'package:flutter/material.dart';

import '../skleton/app_skeletons.dart';

import '../../models/filter_models.dart';
import '../../repositories/category_repository.dart';
import '../../screens/category/category_products_screen_v2.dart';
import '../../services/taxonomy_service.dart';

/// One drawer row: a name, a slug to navigate by, and an optional count.
class _Entry {
  final String name;
  final String slug;
  final int? count;

  const _Entry({required this.name, required this.slug, this.count});
}

enum _SectionKind { category, brand, manufacturer }

class CustomDrawerV2 extends StatelessWidget {
  const CustomDrawerV2({super.key, this.onNavigateToIndex});

  final void Function(int)? onNavigateToIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Image.asset('assets/logo/aanahtar-logo.webp', height: 48),
          ),
          Divider(height: 8, color: theme.dividerColor.withOpacity(0.3)),
          const _LazySection(
            title: "KATEGORİLER",
            kind: _SectionKind.category,
          ),
          const _LazySection(
            title: "MARKALAR",
            kind: _SectionKind.brand,
          ),
          const _LazySection(
            title: "ÜRETİCİ FİRMALAR",
            kind: _SectionKind.manufacturer,
          ),
        ],
      ),
    );
  }
}

class _LazySection extends StatefulWidget {
  const _LazySection({required this.title, required this.kind});

  final String title;
  final _SectionKind kind;

  @override
  State<_LazySection> createState() => _LazySectionState();
}

class _LazySectionState extends State<_LazySection> {
  List<_Entry>? _entries;
  bool _loading = false;
  String? _error;

  String _fixHtml(String text) => text
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#039;', "'")
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>');

  /// Called on the first expand only. TaxonomyService serves from cache on
  /// every subsequent open, including after an app restart.
  Future<void> _loadOnce() async {
    if (_entries != null || _loading) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      late List<_Entry> entries;

      switch (widget.kind) {
        case _SectionKind.category:
          final tree = await TaxonomyService.categories();
          // Roots only — the drawer is a flat menu, and children are reachable
          // from the category page itself.
          entries = tree
              .map((CategoryNode c) => _Entry(name: c.name, slug: c.slug))
              .toList();
          break;

        case _SectionKind.brand:
          final brands = await TaxonomyService.brands();
          entries = brands
              .map((TermFacet b) =>
              _Entry(name: b.name, slug: b.slug, count: b.count))
              .toList();
          break;

        case _SectionKind.manufacturer:
          final makers = await TaxonomyService.manufacturers();
          entries = makers
              .map((TermFacet m) =>
              _Entry(name: m.name, slug: m.slug, count: m.count))
              .toList();
          break;
      }

      if (!mounted) return;
      setState(() {
        _entries = entries;
        _loading = false;
      });
    } catch (e) {
      // The message is shown, not just "Yüklenemedi" — a generic failure
      // string here hid a client-side hang for far too long.
      debugPrint('Drawer section ${widget.title} failed: $e');
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _open(BuildContext context, _Entry entry) {
    Navigator.pop(context);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => widget.kind == _SectionKind.category
            ? CategoryProductsScreenV2(
          categorySlug: entry.slug,
          title: entry.name,
        )
            : CategoryProductsScreenV2(
          // Manufacturers aren't a separate constructor argument —
          // the API filters them with manufacturers[], same shape as
          // brands, so this maps onto brandSlug only for brands.
          brandSlug:
          widget.kind == _SectionKind.brand ? entry.slug : null,
          title: entry.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(10),
          border: theme.brightness == Brightness.dark
              ? Border.all(color: Colors.white, width: 1)
              : null,
          boxShadow: [
            if (theme.brightness != Brightness.dark)
              BoxShadow(
                color: Colors.black.withOpacity(0.11),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            // The whole point: nothing is requested until this fires.
            onExpansionChanged: (expanded) {
              if (expanded) _loadOnce();
            },
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            title: Text(
              widget.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
              ),
            ),
            childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
            children: [_children(theme)],
          ),
        ),
      ),
    );
  }

  Widget _children(ThemeData theme) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: MenuSkeleton(rows: 4),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.grey)),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                setState(() => _entries = null);
                _loadOnce();
              },
              child: const Text('Tekrar dene'),
            ),
          ],
        ),
      );
    }

    final entries = _entries ?? const <_Entry>[];

    if (entries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text('Kayıt yok', style: TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      children: entries.map((entry) {
        return Column(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 0),
              title: Text(
                _fixHtml(entry.name),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
              // Categories have no count in /categories — only brands and
              // manufacturers carry one.
              trailing: entry.count == null
                  ? null
                  : Text(
                '${entry.count} ürün',
                style: TextStyle(
                  fontSize: 12,
                  color:
                  theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                ),
              ),
              onTap: () => _open(context, entry),
            ),
            Divider(
              height: 1,
              thickness: 2,
              color: theme.dividerColor.withOpacity(0.3),
            ),
          ],
        );
      }).toList(),
    );
  }
}