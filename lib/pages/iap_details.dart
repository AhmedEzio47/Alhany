import 'package:Alhany/app_util.dart';
import 'package:Alhany/constants/colors.dart';
import 'package:Alhany/constants/strings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class IAPDetails extends StatefulWidget {
  const IAPDetails({Key key}) : super(key: key);

  @override
  _IAPDetailsState createState() => _IAPDetailsState();
}

class _IAPDetailsState extends State<IAPDetails> {

  TextStyle headingStyle = TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              ],
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
}
