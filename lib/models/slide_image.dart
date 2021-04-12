import 'package:cloud_firestore/cloud_firestore.dart';

class SlideImage {
  final String? id;
  final String? url;
  final String? page;
  final Timestamp? timestamp;

  SlideImage({ this.id,  this.url,  this.page,  this.timestamp});

  factory SlideImage.fromDoc(DocumentSnapshot doc) {
    return SlideImage(
      id: doc.id,
      url: doc.data()!['url'],
      page: doc.data()!['page'],
      timestamp: doc.data()!['timestamp'],
    );
  }
}
