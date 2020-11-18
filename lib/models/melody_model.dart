import 'package:cloud_firestore/cloud_firestore.dart';

class Melody {
  final String id;
  final String name;
  final String audioUrl;
  final String lyrics;
  final Map levelUrls;
  final Map levelDurations;
  final String imageUrl;
  final String authorId;
  final String singer;
  final bool isSong;
  final String price;
  final int views;
  final List search;
  final int duration;
  final Timestamp timestamp;

  Melody(
      {this.id,
      this.name,
      this.audioUrl,
      this.lyrics,
      this.levelUrls,
      this.levelDurations,
      this.imageUrl,
      this.authorId,
      this.singer,
      this.isSong,
      this.price,
      this.views,
      this.search,
      this.duration,
      this.timestamp});

  factory Melody.fromDoc(DocumentSnapshot doc) {
    return Melody(
        id: doc.documentID,
        name: doc['name'],
        audioUrl: doc['audio_url'],
        lyrics: doc['lyrics'],
        levelUrls: doc['level_urls'],
        levelDurations: doc['level_durations'],
        imageUrl: doc['image_url'],
        authorId: doc['author_id'],
        singer: doc['singer'],
        isSong: doc['is_song'],
        price: doc['price'],
        views: doc['views'],
        duration: doc['duration'],
        search: doc['search'],
        timestamp: doc['timestamp']);
  }

  factory Melody.fromMap(Map<String, dynamic> map) {
    return Melody(
        id: map['id'],
        name: map['name'],
        authorId: map['author_id'],
        audioUrl: map['audio_url'],
        imageUrl: map['image_url'],
        duration: map['duration'],
        singer: map['singer']);
  }

  copyWith({audioUrl}) {
    return Melody(
      id: this.id,
      name: this.name,
      audioUrl: audioUrl,
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
      'audio_url': this.audioUrl,
      'image_url': this.imageUrl,
      'singer': this.singer,
      'duration': this.duration,
    };
    return map;
  }
}
