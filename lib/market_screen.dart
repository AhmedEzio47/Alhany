// import 'dart:async';
//
// import 'package:Alhany/constants/constants.dart';
// import 'package:Alhany/models/past_purchase.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:in_app_purchase/in_app_purchase.dart';
//
// class MarketScreen extends StatefulWidget  {
//   const MarketScreen({Key key}) : super(key: key);
//
//   @override
//   _MarketScreenState createState() => _MarketScreenState();
// }
//
// class _MarketScreenState extends State<MarketScreen>  with ChangeNotifier{
//   // In-app Purchase Plugin
//   InAppPurchase _inAppPurchase = InAppPurchase.instance;
//
//   // Products for sale
//   List<ProductDetails> _products = [];
//
//   // Past purchases
//   List<PurchaseDetails> _purchases = [];
//
//   // Updates to purchases
//   StreamSubscription _subscription;
//
//   // Consumable songs the user can buy
//   int _songsCredits = 0;
//
//
//   @override
//   void initState() {
//     _initialize();
//     _getPastPurchases();
//     super.initState();
//   }
//
//   @override
//   void dispose() {
//     _subscription.cancel();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Container();
//   }
//
//   void _initialize() async{
//     // Check the availability of In-App purchases
//     bool _available = await _inAppPurchase.isAvailable();
//     if(_available){
//       // await _getProducts();
//       // await _getPastPurchases();
//
//       List<Future> futures = [Future<void> _getProducts(), Future<void> _getPastPurchases()];
//       await Future.wait(futures);
//       _verifyPurchase();
//
//       // Listen to new purchases
//       _subscription = _inAppPurchase.purchaseStream.listen((data) {
//         setState(() {
//           print("NEW PURCHASE STREAM");
//           _purchases.addAll(data);
//         });
//       });
//     }
//   }
//
//   FirebaseFirestore _firestore;
//   FirebaseAuth _auth;
//
//
//
//   bool get isLoggedIn => _user != null;
//   User _user;
//   bool hasActiveSubscription = false;
//
//   List<PastPurchase> purchases = [];
//
//   StreamSubscription<User> _userSubscription;
//   StreamSubscription<QuerySnapshot> _purchaseSubscription;
//
//   // Get past purchases
//   Future<void> _getPastPurchases() async{
//     _purchaseSubscription?.cancel();
//     var user = _user;
//     if (user == null) {
//       purchases = [];
//       hasActiveSubscription = false;
//       return;
//     }
//     var purchaseStream = _firestore
//         .collection('purchases')
//         .where('userId', isEqualTo: user.uid)
//         .snapshots();
//
//     _purchaseSubscription = purchaseStream.listen((snapshot) {
//       purchases = snapshot.docs.map((document) {
//         var data = document.data();
//         return PastPurchase.fromJson(data);
//       }).toList();
//
//       hasActiveSubscription = purchases.any((element) =>
//       element.productId == Constants.exclusivesSubscription &&
//           element.status != Status.expired);
//
//       notifyListeners();
//     });
//
//   }
//
//   // Get all products available for sale
//   Future<void> _getProducts() async{
//     Set<String> ids = Set.from([Constants.exclusivesSubscription]);
//     ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(ids);
//
//     setState(() {
//       _products = response.productDetails;
//     });
//   }
// }
