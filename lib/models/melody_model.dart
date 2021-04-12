import 'package:cloud_firestore/cloud_firestore.dart';

class Melody {
  final String? id;
  final String? name;
  final String? audioUrl;
  final String? lyrics;
  final Map? levelUrls;
  final Map? levelDurations;
  final String? imageUrl;
  final String? authorId;
  final String? singer;
  final bool? isSong;
  final String? price;
  final int? views;
  final List? search;
  final int? duration;
  final Timestamp? timestamp;

  Melody(
      { this.id,
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
        id: doc.id,
        name: doc.data()!['name'],
        audioUrl: doc.data()!['audio_url'],
        lyrics: doc.data()!['lyrics'],
        levelUrls: doc.data()!['level_urls'],
        levelDurations: doc.data()!['level_durations'],
        imageUrl: doc.data()!['image_url'],
        authorId: doc.data()!['author_id'],
        singer: doc.data()!['singer'],
        isSong: doc.data()!['is_song'],
        price: doc.data()!['price'],
        views: doc.data()!['views'],
        duration: doc.data()!['duration'],
        search: doc.data()!['search'],
        timestamp: doc.data()!['timestamp']);
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

  Map<String, Object> toMap() {
    var map = <String, Object>{
      'id': this.id as Object,
      'name': this.name as Object,
      'author_id': this.authorId as Object,
      'audio_url': this.audioUrl as Object,
      'image_url': this.imageUrl as Object,
      'singer': this.singer as Object,
      'duration': this.duration as Object,
    };
    return map;
  }
}
