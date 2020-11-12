import 'dart:io';

import 'package:Alhany/app_util.dart';
import 'package:Alhany/constants/strings.dart';
import 'package:Alhany/models/melody_model.dart';
import 'package:stripe_payment/stripe_payment.dart';

class PaymentService {
  static Future<Source> createPaymentSource() async {
    await StripePayment.createSourceWithParams(SourceParams(
      type: 'ideal',
      amount: 2102,
      currency: 'eur',
      returnURL: 'example://stripe-redirect',
    )).then((source) {
      //AppUtil.showToast('Received ${source.sourceId}');
      return source;
    });
    return null;
  }

  static Future<PaymentMethod> createTokenWithCardForm() async {
    PaymentMethod paymentMethod = await StripePayment.paymentRequestWithCardForm(CardFormPaymentRequest());
    //TODO save card details in shared pref
    return paymentMethod;
  }

  static Future<Token> createTokenWithCard() async {
    //TODO retrieve card details from shared pref
    CreditCard testCard = CreditCard(
      number: '4573764466955200',
      expMonth: 07,
      expYear: 24,
    );

    Token token = await StripePayment.createTokenWithCard(
      testCard,
    );

    return token;
  }

  static confirmPaymentIntent(PaymentMethod paymentMethod, String clientSecret) async {
    PaymentIntentResult paymentIntentResult = await StripePayment.confirmPaymentIntent(
      PaymentIntent(
        clientSecret: clientSecret,
        paymentMethodId: paymentMethod.id,
      ),
    );
    return paymentIntentResult;
  }

  static authenticatePaymentIntent() async {
    PaymentIntentResult paymentIntentResult =
        await StripePayment.authenticatePaymentIntent(clientSecret: Strings.paymentSecret);
    //paymentIntentResult = await StripePayment.authenticatePaymentIntent(clientSecret: Strings.paymentSecret);
    return paymentIntentResult;
  }

  static Future<Token> nativePayment(String price, {var controller}) async {
    if (Platform.isIOS) {
      controller.jumpTo(450);
    }
    Token token = await StripePayment.paymentRequestWithNativePay(
      androidPayOptions: AndroidPayPaymentRequest(
        totalPrice: price,
        currencyCode: "USD",
      ),
      applePayOptions: ApplePayPaymentOptions(
        countryCode: 'DE',
        currencyCode: 'USD',
        items: [
          ApplePayItem(
            label: 'Test',
            amount: '1',
          )
        ],
      ),
    );
    if (token != null) {
      StripePayment.completeNativePayRequest();
      AppUtil.showToast('Payment Complete!');
    }
    return token;
  }

  static configureStripePayment() {
    StripePayment.setOptions(StripeOptions(
        publishableKey: Strings.paymentPublishableKey,
        merchantId: Strings.merchantId, //YOUR_MERCHANT_ID
        androidPayMode: 'test'));
  }
}
