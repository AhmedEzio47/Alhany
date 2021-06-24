import 'package:cloud_firestore/cloud_firestore.dart';

class Track {
  final String id;
  final String name;
  final String ownerId;
  final String image;
  final String audio;

  Track({this.id, this.name, this.ownerId, this.image, this.audio});

  factory Track.fromDoc(DocumentSnapshot doc) {
    return Track(
        id: doc.id,
        name: doc.data()['name'],
        ownerId: doc.data()['owner_id'],
        image: doc.data()['image'],
        audio: doc.data()['audio']);
  }
}
