import 'dart:convert';
import 'dart:io';

import 'package:Alhany/constants/strings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:stripe_payment/stripe_payment.dart';

class StripeTransactionResponse {
  String message;
  bool success;
  StripeTransactionResponse({this.message, this.success});
}

class PaymentService {
  static String apiBase = 'https://api.stripe.com//v1';
  static String paymentApiUrl = '$apiBase/payment_intents';
  static Map<String, String> headers = {
    'Authorization': 'Bearer ${Strings.stripeSecret}',
    'Content-Type': 'application/x-www-form-urlencoded',
  };

  static Future<StripeTransactionResponse> payViaCreditCard(
      BuildContext context,
      {String amount,
      String currency}) async {
    try {
      PaymentMethod paymentMethod = await _paymentRequestWithCardForm();
      var paymentIntentMap = await _createPaymentIntent(
          (double.parse(amount) * 100).toStringAsFixed(0), currency);
      PaymentIntent paymentIntent = PaymentIntent(
          clientSecret: paymentIntentMap['client_secret'],
          paymentMethodId: paymentMethod.id);

      PaymentIntentResult result = await _confirmPaymentIntent(paymentIntent);
      if (result.status == 'succeeded') {
        return StripeTransactionResponse(
            message: 'Transaction successful', success: true);
      } else {
        return StripeTransactionResponse(
            message: 'Transaction failed', success: false);
      }
    } catch (error) {
      return StripeTransactionResponse(
          message: 'Transaction failed', success: false);
    }
  }

  static Future<PaymentMethod> _paymentRequestWithCardForm() async {
    PaymentMethod paymentMethod =
        await StripePayment.paymentRequestWithCardForm(
            CardFormPaymentRequest());
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

  static Future<Map<String, dynamic>> _createPaymentIntent(
      String amount, String currency) async {
    try {
      Map<String, dynamic> body = {
        'amount': amount,
        'currency': currency,
        'payment_method_types[]': 'card'
      };
      var response = await http.post(Uri.parse(paymentApiUrl),
          body: body, headers: headers);
      return jsonDecode(response.body);
    } catch (error) {
      print(error.toString());
    }
    return null;
  }

  static Future<PaymentIntentResult> _confirmPaymentIntent(
      PaymentIntent paymentIntent) async {
    PaymentIntentResult paymentIntentResult =
        await StripePayment.confirmPaymentIntent(paymentIntent);
    return paymentIntentResult;
  }

  static Future<StripeTransactionResponse> nativePayment(
      BuildContext context, String amount, songName,
      {var controller}) async {
    if (Platform.isIOS) {
      //controller.jumpTo(450);
    }
    try {
      Token token = await StripePayment.paymentRequestWithNativePay(
        androidPayOptions: AndroidPayPaymentRequest(
          totalPrice: (double.parse(amount) * 100).toStringAsFixed(2),
          currencyCode: "USD",
        ),
        applePayOptions: ApplePayPaymentOptions(
          countryCode: 'IQ',
          currencyCode: 'USD',
          items: [
            ApplePayItem(
              label: songName,
              amount: (double.parse(amount) * 100).toStringAsFixed(2),
            )
          ],
        ),
      );
      if (token != null) {
        await StripePayment.completeNativePayRequest();
        // await AppUtil.showAlertDialog(
        //     context: context,
        //     message: 'You\'re going to pay $amount USD, continue?',
        //     firstBtnText: 'Yes',
        //     firstFunc: () async {
        //       StripePayment.completeNativePayRequest();
        //       AppUtil.showToast('Payment Complete!');
        //     },
        //     secondBtnText: 'No',
        //     secondFunc: () => Navigator.of(context).pop());
      }
      //await StripePayment.completeNativePayRequest();
    } catch (error) {
      print((error as PlatformException).message.toString());
      print((error as PlatformException).code.toString());
      print((error as PlatformException).details.toString());
      return StripeTransactionResponse(
          success: false, message: 'Transaction failed');
    }
    return StripeTransactionResponse(
        success: true, message: 'Transaction succeeded');
  }

  static initPayment() {
    StripePayment.setOptions(StripeOptions(
        publishableKey: Strings.stripePublishableKey,
        merchantId: Strings.merchantId, //YOUR_MERCHANT_ID
        androidPayMode: 'production'));
  }
}
