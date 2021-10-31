import 'package:Alhany/constants/constants.dart';
import 'package:purchases_flutter/object_wrappers.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class PurchaseTracks {
  static const oneTrackPurchaseID = 'one_track';
  static const allTracksPurchaseID = 'all_tracks';

  static const allIds = [oneTrackPurchaseID, allTracksPurchaseID];
}

class PurchaseApi {
  static const _apiKey = 'vMbzspZIBRgUofsCKgSlOawHxTstYeQl';

  static Future init() async {
    await Purchases.setDebugLogsEnabled(true);
    await Purchases.setup(_apiKey, appUserId: Constants.currentUserID);
  }

  static Future<List<Offering>> fetchOffersByIds(List<String> ids) async {
    final offers = await fetchOffers();

    return offers.where((offer) => ids.contains(offer.identifier)).toList();
  }

  static Future<List<Offering>> fetchOffers({bool all = true}) async {
    try {
      final offerings = await Purchases.getOfferings();
      if (!all) {
        //print('offerings $offerings');
        final current = offerings.current;
        //print('offerings.current: $current');

        return [current] ?? [];
      } else {
        return offerings.all.values.toList();
      }
    } catch (e) {
      return [];
    }
  }

  static Future<bool> purchasePackage(Package package) async {
    try {
      await Purchases.purchasePackage(package);
      return true;
    } catch (e) {
      print('purchasePackage error: $e');
      return false;
    }
  }
}
