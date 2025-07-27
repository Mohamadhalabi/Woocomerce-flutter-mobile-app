double parseWooPrice(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String && value.isNotEmpty) {
    return double.tryParse(value) ?? 0.0;
  }
  if (value is Map && value['raw'] != null) {
    final rawVal = value['raw'];
    if (rawVal is num) return rawVal.toDouble();
    if (rawVal is String && rawVal.isNotEmpty) {
      return double.tryParse(rawVal) ?? 0.0;
    }
  }
  return 0.0;
}

String getCurrencySymbol(String currency) {
  switch (currency) {
    case 'USD':
      return '\$';
    case 'EUR':
      return '€';
    case 'TRY':
      return '₺';
    case 'GBP':
      return '£';
    default:
      return currency; // fallback: show the code itself
  }
}