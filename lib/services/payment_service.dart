import 'dart:convert';
import 'dart:io';

import 'package:Alhany/app_util.dart';
import 'package:Alhany/constants/strings.dart';
import 'package:stripe_payment/stripe_payment.dart';
import 'package:http/http.dart' as http;

class StripeTransactionResponse {
  String message;
  bool success;
  StripeTransactionResponse({this.message, this.success});
}

class PaymentService {
  static String apiBase = 'https://api.stripe.com//v1';
  static String paymentApiUrl = '$apiBase/payment_intents';
  static Map<String, String> headers = {
    'Authorization': 'Bearer ${Strings.paymentSecret}',
    'Content-Type': 'application/x-www-form-urlencoded',
  };

  static Future<StripeTransactionResponse> payViaCreditCard({String amount, String currency}) async {
    try {
      PaymentMethod paymentMethod = await _paymentRequestWithCardForm();
      var paymentIntentMap = await _createPaymentIntent(amount, currency);
      PaymentIntent paymentIntent =
          PaymentIntent(clientSecret: paymentIntentMap['client_secret'], paymentMethodId: paymentMethod.id);
      PaymentIntentResult result = await _confirmPaymentIntent(paymentIntent);
      if (result.status == 'succeeded') {
        return StripeTransactionResponse(message: 'Transaction successful', success: true);
      } else {
        return StripeTransactionResponse(message: 'Transaction failed', success: false);
      }
    } catch (error) {
      return StripeTransactionResponse(message: 'Transaction failed', success: false);
    }
  }

  static Future<PaymentMethod> _paymentRequestWithCardForm() async {
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

  static Future<Map<String, dynamic>> _createPaymentIntent(String amount, String currency) async {
    try {
      Map<String, dynamic> body = {'amount': amount, 'currency': currency, 'payment_method_types[]': 'card'};
      var response = await http.post(paymentApiUrl, body: body, headers: headers);
      return jsonDecode(response.body);
    } catch (error) {
      print(error.toString());
    }
    return null;
  }

  static Future<PaymentIntentResult> _confirmPaymentIntent(PaymentIntent paymentIntent) async {
    PaymentIntentResult paymentIntentResult = await StripePayment.confirmPaymentIntent(paymentIntent);
    return paymentIntentResult;
  }

  static Future<StripeTransactionResponse> nativePayment(String amount, songName, {var controller}) async {
    if (Platform.isIOS) {
      controller.jumpTo(450);
    }
    try {
      Token token = await StripePayment.paymentRequestWithNativePay(
        androidPayOptions: AndroidPayPaymentRequest(
          totalPrice: amount,
          currencyCode: "USD",
        ),
        applePayOptions: ApplePayPaymentOptions(
          countryCode: 'DE',
          currencyCode: 'USD',
          items: [
            ApplePayItem(
              label: songName,
              amount: '1',
            )
          ],
        ),
      );
      if (token != null) {
        StripePayment.completeNativePayRequest();
        AppUtil.showToast('Payment Complete!');
      }
      await StripePayment.completeNativePayRequest();
    } catch (error) {
      print(error.toString());
      return StripeTransactionResponse(success: false, message: 'Transaction failed');
    }
    return StripeTransactionResponse(success: true, message: 'Transaction succeeded');
  }

  static initPayment() {
    StripePayment.setOptions(StripeOptions(
        publishableKey: Strings.paymentPublishableKey,
        merchantId: Strings.merchantId, //YOUR_MERCHANT_ID
        androidPayMode: 'test'));
  }
}
