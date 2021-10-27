import 'package:purchases_flutter/object_wrappers.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class PurchaseApi{

  static const _apiKey = 'vMbzspZIBRgUofsCKgSlOawHxTstYeQl';

  static Future init() async{
    await Purchases.setDebugLogsEnabled(true);
    await Purchases.setup(_apiKey);
  }
  static Future<List<Offering>> fetchOffers() async{
    try {
      final offerings = await Purchases.getOfferings();
      //print('offerings $offerings');
      final current = offerings.current;
      //print('offerings.current: $current');


      return [current] ?? [];
    }catch(e){
      return [];
    }
  }

  static Future<bool> purchasePackage(Package package) async{
    try{
      await Purchases.purchasePackage(package);
    return true;
    }catch(e){
      print('purchasePackage error: $e');
      return false;
    }
  }
}