import 'package:cloud_firestore/cloud_firestore.dart';

class Melody {
  final String id;
  final String name;
  final String songUrl;
  final String melodyUrl;
  final String lyrics;
  final Map levelUrls;
  final Map levelDurations;
  final String imageUrl;
  final String authorId;
  final String singer;
  final String price;
  final String melodyPrice;
  final int views;
  final List search;
  final int duration;
  final int melodyDuration;
  final Timestamp timestamp;

  Melody(
      {this.id,
      this.name,
      this.songUrl,
      this.melodyUrl,
      this.lyrics,
      this.levelUrls,
      this.levelDurations,
      this.imageUrl,
      this.authorId,
      this.singer,
      this.price,
      this.melodyPrice,
      this.views,
      this.search,
      this.duration,
      this.melodyDuration,
      this.timestamp});

  factory Melody.fromDoc(DocumentSnapshot doc) {
    return Melody(
        id: doc.id,
        name: doc.data()['name'],
        songUrl: doc.data()['audio_url'],
        melodyUrl: doc.data()['melody_url'],
        lyrics: doc.data()['lyrics'],
        levelUrls: doc.data()['level_urls'],
        levelDurations: doc.data()['level_durations'],
        imageUrl: doc.data()['image_url'],
        authorId: doc.data()['author_id'],
        singer: doc.data()['singer'],
        price: doc.data()['price'],
        melodyPrice: doc.data()['melody_price'],
        views: doc.data()['views'],
        duration: doc.data()['duration'],
        search: doc.data()['search'],
        timestamp: doc.data()['timestamp']);
  }

  factory Melody.fromMap(Map<String, dynamic> map) {
    return Melody(
        id: map['id'],
        name: map['name'],
        authorId: map['author_id'],
        songUrl: map['audio_url'],
        imageUrl: map['image_url'],
        duration: map['duration'],
        singer: map['singer']);
  }

  copyWith({audioUrl}) {
    return Melody(
      id: this.id,
      name: this.name,
      songUrl: audioUrl,
      imageUrl: this.imageUrl,
      duration: this.duration,
      singer: this.singer,
    );
  }

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      'id': this.id,
      'name': this.name,
      'author_id': this.authorId,
      'audio_url': this.songUrl,
      'image_url': this.imageUrl,
      'singer': this.singer,
      'duration': this.duration,
    };
    return map;
  }
}
