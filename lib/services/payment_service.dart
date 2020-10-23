import 'dart:io';

import 'package:dubsmash/app_util.dart';
import 'package:dubsmash/constants/strings.dart';
import 'package:dubsmash/models/melody_model.dart';
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
    await StripePayment.paymentRequestWithCardForm(CardFormPaymentRequest()).then((paymentMethod) {
      //AppUtil.showToast('Received ${paymentMethod.id}');
      //TODO save card details in shared pref
      // _paymentMethod = paymentMethod;
      // _creditCard = _paymentMethod.card;
      return paymentMethod;
    });
    return null;
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

    PaymentMethod paymentMethod = await StripePayment.createPaymentMethod(
      PaymentMethodRequest(card: testCard),
    );

    //await confirmPaymentIntent(paymentMethod);
    await authenticatePaymentIntent();

    return token;
  }

  static confirmPaymentIntent(PaymentMethod paymentMethod) async {
    PaymentIntentResult paymentIntentResult = await StripePayment.confirmPaymentIntent(
      PaymentIntent(
        clientSecret: Strings.paymentSecret,
        paymentMethodId: paymentMethod.id,
      ),
    );
    //paymentIntentResult = await StripePayment.authenticatePaymentIntent(clientSecret: Strings.paymentSecret);
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
