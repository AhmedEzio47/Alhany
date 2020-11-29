import 'dart:io';

import 'package:Alhany/app_util.dart';
import 'package:Alhany/constants/colors.dart';
import 'package:Alhany/constants/constants.dart';
import 'package:Alhany/constants/strings.dart';
import 'package:Alhany/services/payment_service.dart';
import 'package:flutter/material.dart';

class PaymentHomePage extends StatefulWidget {
  final String amount;

  const PaymentHomePage({Key key, this.amount}) : super(key: key);
  @override
  _PaymentHomePageState createState() => _PaymentHomePageState();
}

class _PaymentHomePageState extends State<PaymentHomePage> {
  @override
  void initState() {
    PaymentService.initPayment();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment'),
      ),
      body: Container(
        child: Column(
          children: [
            Container(
              width: MediaQuery.of(context).size.width,
              padding: EdgeInsets.all(16),
              color: MyColors.lightPrimaryColor,
              child: Text(
                'You\'re going to pay : ${widget.amount} USD',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ListView.separated(
                    itemBuilder: (context, index) {
                      dynamic icon;
                      Text text;
                      switch (index) {
                        case 0:
                          icon = Icon(
                            Icons.credit_card,
                            color: MyColors.primaryColor,
                          );
                          text = Text('Pay via credit card');
                          break;
                        case 1:
                          if (Platform.isIOS) {
                            icon = Image.asset(Strings.apple);
                            text = Text('Use Apple Pay');
                          } else if (Platform.isAndroid) {
                            icon = Image.asset(
                              Strings.google,
                              scale: 20,
                            );
                            text = Text('Use Google Pay');
                          }
                          break;
                      }
                      return InkWell(
                        onTap: () {
                          onItemPressed(context, index);
                        },
                        child: ListTile(
                          leading: icon,
                          title: text,
                        ),
                      );
                    },
                    separatorBuilder: (context, index) {
                      return Divider(
                        height: 1,
                        color: Colors.grey,
                        thickness: 1,
                      );
                    },
                    itemCount: 2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  onItemPressed(BuildContext context, int index) async {
    switch (index) {
      case 0:
        StripeTransactionResponse response =
            await PaymentService.payViaCreditCard(context, amount: widget.amount, currency: 'USD');
        AppUtil.showToast(response.message);
        Navigator.of(context).pop(response.success);
        break;
      case 1:
        StripeTransactionResponse response = await PaymentService.nativePayment(
          context,
          widget.amount,
          'Songs Name',
        );
        AppUtil.showToast(response.message);
        Navigator.of(context).pop(response.success);
        break;
    }
  }
}
