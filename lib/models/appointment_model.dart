import 'package:cloud_firestore/cloud_firestore.dart';

class Appointment {
  final String id;
  final String userId;
  final String email;
  final String name;
  final String notes;
  final Timestamp timestamp;

  Appointment(
      {this.id,
      this.userId,
      this.email,
      this.name,
      this.notes,
      this.timestamp});

  factory Appointment.fromDoc(DocumentSnapshot doc) {
    return Appointment(
        id: doc.id,
        userId: doc.data()['user_id'],
        name: doc.data()['name'],
        email: doc.data()['email'],
        timestamp: doc.data()['timestamp'],
        notes: doc.data()['notes']);
  }
}
