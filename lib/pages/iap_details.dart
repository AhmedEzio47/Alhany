import 'package:Alhany/app_util.dart';
import 'package:Alhany/constants/colors.dart';
import 'package:Alhany/constants/constants.dart';
import 'package:Alhany/constants/routes.dart';
import 'package:Alhany/constants/strings.dart';
import 'package:Alhany/pages/web_browser/webview_modal.dart';
import 'package:Alhany/services/purchase_api.dart';
import 'package:Alhany/widgets/paywall_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class IAPDetails extends StatefulWidget {
  const IAPDetails({Key key}) : super(key: key);

  @override
  _IAPDetailsState createState() => _IAPDetailsState();
}

class _IAPDetailsState extends State<IAPDetails> {

  TextStyle headingStyle = TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18);
  TextStyle linkStyle = TextStyle(fontWeight: FontWeight.bold, color: Colors.blue);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: InkWell(
        onTap: ()=>fetchOffers(),
        child: Container(width: MediaQuery.of(context).size.width, child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Text('PURCHASE SUBSCRIPTION', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),),
        ), color: MyColors.accentColor,),
      ),
      appBar: AppBar(centerTitle: true,title: Image.asset(Strings.app_bar, height: 40,),
      backgroundColor: MyColors.primaryColor,),
      body: Container(
        decoration: BoxDecoration(
          gradient: new LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              MyColors.primaryColor,
            ],
          ),
          color: MyColors.primaryColor,
          image: DecorationImage(
            colorFilter: new ColorFilter.mode(
                Colors.black.withOpacity(0.1), BlendMode.dstATop),
            image: AssetImage(Strings.default_bg),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            decoration: BoxDecoration(
                border: Border.all(color: Colors.amberAccent)
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HeadingWidget('Exclusives Subscription'),
                  Padding(
                    padding: const EdgeInsets.all(12.0),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SubscriptionDetails(text: 'Subscription duration: ', subText: ' 1 month' ),
                        SubscriptionDetails(text: 'Subscription price: ', subText: ' \$5' ),
                        SubscriptionDetails(text: 'Auto-renew: ', subText: ' This is an auto-renewing subscription, read below to know more...' ),

                      ],
                    ),
                  ),
                  HeadingWidget('Why unlock this feature?'),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                     RichText(
                    text: TextSpan(
                    style: TextStyle(color: Colors.white, fontSize: 14, height: 1.5 ),
                    children: <TextSpan>[
                      TextSpan(text: 'Stay connected to the latest exclusives while enjoying Alhani app. This is a subscription that will be automatically renewed (you will be charged) \$5 every month. You can read your terms of use here for more details: '),
                      TextSpan(text: 'https://www.alhaniiraq.com/terms-of-service/', style: linkStyle, recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          Navigator.of(context).push(WebViewModal(
                              url: Strings.terms_of_service_link));
                          print('Terms of Service"');
                        }),
                      TextSpan(text: '\nPlease read below about the auto-renewing subscription nature of this product before purchasing it', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: '- Payment Will be charged to iTunes Account at confirmation of purchase.\n'
                          '- Subscription automatically renews unless auto-renew is turned off at least 24-hours before the end of the current period.\n'
                          '- Account will be charged for renewal within 24-hours prior to the end of the current period, and identify the cost of the renewal.\n'
                          '- Subscriptions may be managed by the user and auto-renewal may be turned off by going to the user\'s Account Settings after purchase.\n'
                          '- Also look at our Privacy Policy here: '),
                      TextSpan(text: 'https://www.alhaniiraq.com/privacy-policy/', style: linkStyle, recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          Navigator.of(context).push(WebViewModal(
                              url: Strings.privacy_policy_link));
                          print('Privacy Policy"');
                        }),
                    ],
                  ),
            ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget HeadingWidget(String title){

    return Container(color: MyColors.accentColor,child: ListTile(dense: true,title: Text(title, style: headingStyle, )));

  }

  Widget SubscriptionDetails({String text, String subText}){
    return RichText(
      text: TextSpan(
        style: TextStyle(color: Colors.white, fontSize: 14, height: 1.5 ),
        children: <TextSpan>[
          TextSpan(text: text, style: TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(text: subText),
        ],
      ),
    );
  }

  Future fetchOffers() async {
    final offerings = await PurchaseApi.fetchOffers(all: false);
    print('fetchOffers.offerings $offerings');
    if (offerings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(language(
            ar: 'هذا العنصر غير متوفر للشراء حالياً',
            en: 'The app currently has no offers')),
      ));
    } else {
      //final offer = offerings.first;
      //print('Offer: $offer');
      final packages = offerings
          .map((offer) => offer.availablePackages)
          .expand((pair) => pair)
          .toList();
      _settingModalBottomSheet(packages);
    }
  }

  void _settingModalBottomSheet(List packages) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return PaywallWidget(
            packages: packages,
            title: language(
                ar: '🌟 الاشتراك في الحصريات',
                en: '🌟 Subscribe to exclusives'),
            description: language(
                ar: 'احصل على صلاحية الإستماع لحصريات ألحاني',
                en: 'Get access to Alhani\'s exclusives'),
            onClickedPackage: (package) async {
              final success = await PurchaseApi.purchasePackage(package);
              if(success){
                await usersRef
                    .doc(Constants.currentUserID)
                    .update({'exclusive_last_date': FieldValue.serverTimestamp()});
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(language(
                      ar: 'تمت عملية الشراء بنجاح',
                      en: 'Purchase success')),
                ));
              }else{
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(language(
                      ar: 'لم تتم عملية الشراء',
                      en: 'Purchase Failed')),
                ));
              }
              Future.delayed(Duration(milliseconds: 1000), () {
                Navigator.of(context).pushReplacementNamed(Routes.homePage,
                    arguments: {
                      'selectedPage': 3,
                    });
              });
            },
          );
        });
  }
}
