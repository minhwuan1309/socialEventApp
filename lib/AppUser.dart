class AppUser {
  final String uid;
  final String name;
  final String email;
  final String profilePictureUrl;
  final List<String> tags;
  final List<String> friends;
  final List<String> rsvpEvents;
  final List<String> bookmarks;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.profilePictureUrl,
    required this.tags,
    required this.friends,
    required this.rsvpEvents,
    required this.bookmarks,
  });

  factory AppUser.fromJson(Map<String, dynamic> json, String id) {
    return AppUser(
      uid: id,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      profilePictureUrl: json['profilePictureUrl'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      friends: List<String>.from(json['friends'] ?? []),
      rsvpEvents: List<String>.from(json['rsvpEvents'] ?? []),
      bookmarks: List<String>.from(json['bookmarks'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'profilePictureUrl': profilePictureUrl,
      'tags': tags,
      'friends': friends,
      'rsvpEvents': rsvpEvents,
      'bookmarks': bookmarks,
    };
  }
}
