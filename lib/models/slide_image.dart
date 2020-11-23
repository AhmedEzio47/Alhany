import 'package:cloud_firestore/cloud_firestore.dart';

class SlideImage {
  final String id;
  final String url;
  final Timestamp timestamp;

  SlideImage({this.id, this.url, this.timestamp});

  factory SlideImage.fromDoc(DocumentSnapshot doc) {
    return SlideImage(
      id: doc.documentID,
      url: doc['url'],
      timestamp: doc['timestamp'],
    );
  }
}
