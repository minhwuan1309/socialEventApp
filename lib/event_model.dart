import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String documentId;
  final String createdBy;
  final int rsvpCount;
  final DateTime date;
  final String description;
  final String location;
  final String title;
  final String username;
  final List<String> tags;
  final String? image;
  final List<String> likes;
  final List<Map<String, dynamic>> comments;

  Event({
    required this.documentId,
    required this.createdBy,
    required this.rsvpCount,
    required this.date,
    required this.description,
    required this.location,
    required this.title,
    required this.username,
    required this.tags, // Add this to the constructor
    required this.image,
    required this.likes,
    required this.comments,
  });

  factory Event.fromJson(String id, Map<String, dynamic> json) {
    return Event(
      documentId: id,
      createdBy: json['createdBy'] ?? '',
      rsvpCount: json['rsvpCount'] ?? 0,
      date: (json['date'] as Timestamp).toDate(),
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      title: json['title'] ?? '',
      username: json['username'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      image: json['image'],
      likes: List<String>.from(json['likes'] ?? []),
      comments: List<Map<String, dynamic>>.from(json['comments'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'createdBy': createdBy,
      'rsvpCount': rsvpCount,
      'date': Timestamp.fromDate(date),
      'description': description,
      'location': location,
      'title': title,
      'username': username,
      'tags': tags,
      'image': image,
      'likes': likes,
      'comments': comments,
    };
  }
}