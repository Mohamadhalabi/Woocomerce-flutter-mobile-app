import 'package:iyzico/iyzico.dart';

class IyzicoClientInitResult {
  final String token;
  final String payUrl;                 // https://sandbox-ode.iyzico.com/?token=...&lang=tr
  final String checkoutFormContent;    // may be empty
  IyzicoClientInitResult({
    required this.token,
    required this.payUrl,
    required this.checkoutFormContent,
  });
}

class IyzicoClient {
  // ⚠️ SANDBOX KEYS – never ship live secrets in a production app build.
  static const _apiKey  = 'sandbox-NZUlzU0AxxbMV83pidwudpYk6FZYOg2W';
  static const _secret  = 'sandbox-bmXJayF9kVEiF2Cro5HLSIU2JYPQd2FQ';
  static const _baseUrl = 'https://sandbox-api.iyzipay.com';

  static const _lang = 'tr'; // for payUrl

  static Iyzico get _client =>
      Iyzico.fromConfig(configuration: IyziConfig(_apiKey, _secret, _baseUrl));

  /// Hosted Checkout init (client-side). We still recommend server-side verify afterward.
  /// amountTry MUST equal sum of basket item totals you pass here.
  static Future<IyzicoClientInitResult> initCheckoutForm({
    required int orderId,
    required double amountTry,
    required Map<String, dynamic> billing,
    required List<Map<String, dynamic>> cartItems,
    required String callbackUrl,
  }) async {
    // ---- Buyer
    final buyer = Buyer(
      id: '$orderId',
      name: (billing['first_name'] ?? 'Musteri').toString(),
      surname: (billing['last_name'] ?? 'Soyad').toString(),
      identityNumber: '11111111111', // sandbox ok
      email: (billing['email'] ?? 'noreply@example.com').toString(),
      registrationAddress: (billing['address_1'] ?? 'Adres').toString(),
      city: (billing['city'] ?? 'Istanbul').toString(),
      country: 'Turkey',
      ip: '85.34.78.112',
    );

    // ---- Addresses
    final addr = Address(
      address: (billing['address_1'] ?? 'Adres').toString(),
      contactName:
      '${billing['first_name'] ?? ''} ${billing['last_name'] ?? ''}'.trim(),
      zipCode: (billing['postcode'] ?? '34000').toString(),
      city: (billing['city'] ?? 'Istanbul').toString(),
      country: 'Turkey',
    );

    // ---- Basket (use line totals so their sum matches amountTry)
    final items = <BasketItem>[];
    double sum = 0.0;
    int i = 1;
    for (final raw in cartItems) {
      final qty = int.tryParse(raw['quantity']?.toString() ?? '1') ?? 1;
      final unit = (raw['price'] is num)
          ? (raw['price'] as num).toDouble()
          : double.tryParse(raw['price']?.toString() ?? '0') ?? 0.0;
      final lineTotal = unit * qty;
      sum += lineTotal;

      items.add(BasketItem(
        id: (raw['product_id'] ?? raw['id'] ?? i).toString(),
        name: (raw['title'] ?? raw['name'] ?? 'Ürün').toString(),
        category1: 'General',
        itemType: BasketItemType.PHYSICAL,
        price: lineTotal.toStringAsFixed(2), // <- line total
      ));
      i++;
    }

    // iyzico expects price == paidPrice == sum(basketItems)
    final double finalAmount =
    double.parse(amountTry.toStringAsFixed(2));
    final double itemsSum =
    double.parse(sum.toStringAsFixed(2));

    // If mismatch due to rounding, prefer items sum
    final double usedAmount = (finalAmount == itemsSum) ? finalAmount : itemsSum;

    // Required by the package even for hosted checkout; sandbox test card:
    final paymentCard = PaymentCard(
      cardHolderName: 'John Doe',
      cardNumber: '5528790000000008',
      expireYear: '2030',
      expireMonth: '12',
      cvc: '123',
    );

    // ---- Call the SDK — returns CheckoutFormInitialize
    final init = await _client.initializeCheoutForm(
      price: usedAmount,
      paidPrice: usedAmount,
      paymentCard: paymentCard,          // <- required by this package
      buyer: buyer,
      shippingAddress: addr,
      billingAddress: addr,
      basketItems: items,
      callbackUrl: callbackUrl,          // your success page; we still verify on server
      enabledInstallments: const [],
    );

    // init is CheckoutFormInitialize
    final status = (init.status ?? '').toLowerCase();
    if (status != 'success') {
      throw Exception(init.errorMessage ?? 'iyzico init failed');
    }

    final token = init.token ?? '';
    if (token.isEmpty) {
      throw Exception('iyzico token boş döndü.');
    }

    final content = init.checkoutFormContent ?? '';
    final payUrl = 'https://sandbox-ode.iyzico.com/?token=$token&lang=$_lang';

    return IyzicoClientInitResult(
      token: token,
      payUrl: payUrl,
      checkoutFormContent: content,
    );
  }

  /// Optional local verify (useful for debugging). For REAL order state changes,
  /// keep using your server endpoint to update WooCommerce.
  static Future<bool> verifyCheckoutOnClient({required String token}) async {
    final result = await _client.retrieveCheckoutForm(token: token); // CheckoutForm
    final status = (result.paymentStatus ?? '').toUpperCase();
    return status == 'SUCCESS';
  }
}
