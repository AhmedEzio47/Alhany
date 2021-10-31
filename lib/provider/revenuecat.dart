import 'package:flutter/cupertino.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

enum Entitlement { free, exclusives }

class RevenueCatProvider extends ChangeNotifier {
  RevenueCatProvider() {
    init();
  }

  Entitlement _entitlement = Entitlement.free;
  Entitlement get entitlement => _entitlement;
  Future init() async {
    //getPurchaseStatus();
    Purchases.addPurchaserInfoUpdateListener((purchaserInfo) async {
      updatePurchaseStatus();
    });
  }

  Future getPurchaseStatus() async {
    //print('eidarous1');
    PurchaserInfo restoredInfo = await Purchases.restoreTransactions();
    final entitlements = restoredInfo.entitlements.active.values.toList();
    print('restored entitlements $entitlements');
    _entitlement =
        entitlements.isEmpty ? Entitlement.free : Entitlement.exclusives;
    notifyListeners();
  }

  Future updatePurchaseStatus() async {
    final purchaserInfo = await Purchases.getPurchaserInfo();
    final entitlements = purchaserInfo.entitlements.active.values.toList();
    print('entitlements $entitlements');
    _entitlement =
        entitlements.isEmpty ? Entitlement.free : Entitlement.exclusives;
    notifyListeners();
  }
}
