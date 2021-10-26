import 'package:purchases_flutter/object_wrappers.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class PurchaseApi{

  static const _apiKey = '';

  static Future init() async{
    await Purchases.setDebugLogsEnabled(true);
    await Purchases.setup(_apiKey);
  }
  static Future<List<Offering>> fetchOffers() async{
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;

      return current ?? [];
    }catch(e){
      return [];
    }
  }
}