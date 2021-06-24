import 'package:cloud_firestore/cloud_firestore.dart';

class Track {
  final String id;
  final String name;
  final String ownerId;
  final String image;
  final String price;
  final String audio;
  final int duration;
  final Timestamp timestamp;

  Track(
      {this.id,
      this.name,
      this.ownerId,
      this.image,
      this.price,
      this.audio,
      this.duration,
      this.timestamp});

  factory Track.fromDoc(DocumentSnapshot doc) {
    return Track(
        id: doc.id,
        name: doc.data()['name'],
        ownerId: doc.data()['owner_id'],
        image: doc.data()['image'],
        price: doc.data()['price'],
        audio: doc.data()['audio'],
        duration: doc.data()['duration'],
        timestamp: doc.data()['timestamp']);
  }
}
