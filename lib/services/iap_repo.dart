import 'dart:async';

import 'package:Alhany/constants/constants.dart';
import 'package:Alhany/models/past_purchase.dart';
import 'package:Alhany/models/purchasable_product.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

enum StoreState{
  notAvailable,
  available
}

class IAPRepo extends ChangeNotifier {
  FirebaseFirestore _firestore;
  FirebaseAuth _auth;
  //FirebaseNotifier firebaseNotifier;

  bool get isLoggedIn => _user != null;
  User _user;
  bool hasActiveSubscription = false;
  bool hasUpgrade = false;
  List<PastPurchase> purchases = [];

  StreamSubscription<User> _userSubscription;
  StreamSubscription<QuerySnapshot> _purchaseSubscription;

  IAPRepo() {
      _auth = FirebaseAuth.instance;
      _firestore = firestore;
      updatePurchases();
      final purchaseUpdated =
          iapConnection.purchaseStream;
      _subscription = purchaseUpdated.listen(
        _onPurchaseUpdate,
        onDone: _updateStreamOnDone,
        onError: _updateStreamOnError,
      );
      loadPurchases();
      listenToLogin();

  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    purchaseDetailsList.forEach(_handlePurchase);
    notifyListeners();
  }

  void _handlePurchase(PurchaseDetails purchaseDetails) {
    if (purchaseDetails.status == PurchaseStatus.purchased) {
      switch (purchaseDetails.productID) {
        case Constants.exclusivesSubscription:
          //counter.applyPaidMultiplier();
          break;
        // case storeKeyConsumable:
        //   counter.addBoughtDashes(2000);
        //   break;
        // case storeKeyUpgrade:
        //   _beautifiedDashUpgrade = true;
        //   break;
      }
    }

    if (purchaseDetails.pendingCompletePurchase) {
      iapConnection.completePurchase(purchaseDetails);
    }
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    // var functions = await firebaseNotifier.functions;
    // final callable = functions.httpsCallable('verifyPurchase');
    // final results = await callable({
    //   'source':
    //   purchaseDetails.verificationData.source,
    //   'verificationData':
    //   purchaseDetails.verificationData.serverVerificationData,
    //   'productId': purchaseDetails.productID,
    // });
    // return results.data as bool;
  }

  Future<void> buy(PurchasableProduct product) async {
    final purchaseParam = PurchaseParam(productDetails: product.productDetails);
    switch (product.id) {
      // case storeKeyConsumable:
      //   await iapConnection.buyConsumable(purchaseParam: purchaseParam);
      //   break;
      case Constants.exclusivesSubscription:
      // case storeKeyUpgrade:
      //   await iapConnection.buyNonConsumable(purchaseParam: purchaseParam);
      //   break;
      default:
        throw ArgumentError.value(
            product.productDetails, '${product.id} is not a known product');
    }
  }


  void _updateStreamOnDone() {
    _subscription.cancel();
  }

  void _updateStreamOnError(dynamic error) {
    //Handle error here
  }
  StreamSubscription<List<PurchaseDetails>> _subscription;
  final iapConnection = InAppPurchase.instance;

  void listenToLogin() {
    _user = _auth.currentUser;
    _userSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      _user = user;
      updatePurchases();
    });
  }

  void updatePurchases() {
    _purchaseSubscription?.cancel();
    var user = _user;
    if (user == null) {
      purchases = [];
      hasActiveSubscription = false;
      hasUpgrade = false;
      return;
    }
    var purchaseStream = _firestore
        .collection('purchases')
        .where('userId', isEqualTo: user.uid)
        .snapshots();
    _purchaseSubscription = purchaseStream.listen((snapshot) {
      purchases = snapshot.docs.map((document) {
        var data = document.data();
        return PastPurchase.fromJson(data);
      }).toList();

      hasActiveSubscription = purchases.any((element) =>
      element.productId == Constants.exclusivesSubscription &&
          element.status != Status.expired);

      notifyListeners();
    });
  }

  Future<void> loadPurchases() async {
    final available = await InAppPurchase.instance.isAvailable();
    if (!available) {
      var storeState = StoreState.notAvailable;
      const ids = <String>{
        Constants.exclusivesSubscription
      };
      final response =
      await InAppPurchase.instance.queryProductDetails(ids);
      response.notFoundIDs.forEach((element) {
        print('Purchase $element not found');
      });
      var products =
          response.productDetails.map((e) => PurchasableProduct(e)).toList();
      storeState = StoreState.available;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    _purchaseSubscription?.cancel();
    super.dispose();
  }
}
