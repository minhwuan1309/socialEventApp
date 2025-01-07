import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'event_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EventDetailScreen extends StatefulWidget {
  final Event event;

  const EventDetailScreen({Key? key, required this.event}) : super(key: key);

  @override
  _EventDetailScreenState createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  bool _hasRSVPed = false;
  bool _isLiked = false;
  String? _userId;
  late int _currentRSVPCount;
  late int _likeCount;
  final TextEditingController _commentController = TextEditingController();
  List<Map<String, dynamic>> _comments = [];

  @override
  void initState() {
    super.initState();
    _currentRSVPCount = widget.event.rsvpCount;
    _likeCount = widget.event.likes.length;
    _fetchUserIdAndCheckRSVP();
    _loadComments();
    _fetchLikeStatus();
  }

  Future<void> _fetchUserIdAndCheckRSVP() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userId = user.email;

      if (_userId != null) {
        DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(_userId)
            .get();

        List<dynamic> rsvpEvents = userSnapshot['rsvpEvents'] ?? [];

        setState(() {
          _hasRSVPed = rsvpEvents.contains(widget.event.documentId);
        });
      }
    }
  }
  Future<void> _fetchLikeStatus() async {
    final eventRef = FirebaseFirestore.instance.collection('events').doc(widget.event.documentId);
    final snapshot = await eventRef.get();
    final likes = List<String>.from(snapshot['likes'] ?? []);

    setState(() {
      _isLiked = _userId != null && likes.contains(_userId);
      _likeCount = likes.length;
    });
  }

  Future<void> _toggleLike() async {
    if (_userId == null) return;

    final eventRef = FirebaseFirestore.instance.collection('events').doc(widget.event.documentId);
    try {
      if (_isLiked) {
        await eventRef.update({'likes': FieldValue.arrayRemove([_userId])});
        setState(() {
          _isLiked = false;
          _likeCount--;
        });
      } else {
        await eventRef.update({'likes': FieldValue.arrayUnion([_userId])});
        setState(() {
          _isLiked = true;
          _likeCount++;
        });
      }
    } catch (e) {
      print('Error toggling like: $e');
    }
  }


  Future<void> _loadComments() async {
    final eventRef = FirebaseFirestore.instance.collection('events').doc(widget.event.documentId);
    final snapshot = await eventRef.get();
    if (snapshot.exists) {
      setState(() {
        _comments = List<Map<String, dynamic>>.from(snapshot['comments'] ?? []);
      });
    }
  }

  Future<void> _addComment(String commentText) async {
    if (_userId == null || commentText.trim().isEmpty) return;

    final newComment = {
      'userId': _userId,
      'text': commentText,
      'timestamp': Timestamp.now(),
    };

    final eventRef = FirebaseFirestore.instance.collection('events').doc(widget.event.documentId);
    await eventRef.update({
      'comments': FieldValue.arrayUnion([newComment]),
    });

    setState(() {
      _comments.add(newComment);
    });
    _commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: BoxDecoration(
            color: isDarkMode ? Color(0xFF0D1114) : Colors.white,
          ),
          child: AppBar(
            title: Text('Event Details', style: GoogleFonts.montserrat(color: isDarkMode ? Colors.white : Colors.black)),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        ),
      ),
      backgroundColor: isDarkMode ? Color(0xFF0D1114) : Colors.white,
      body: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.all(16.0),
            children: [
              Container(
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orangeAccent, Colors.deepOrange],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.event.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 16),
              if (widget.event.image != null)
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Image.network(
                      widget.event.image!,
                      width: constraints.maxWidth,
                      fit: BoxFit.cover,
                    );
                  },
                ),
              SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(Icons.calendar_today, 'Date', DateFormat('MMM d, y - h:mm a').format(widget.event.date), isDarkMode),
                  _buildInfoRow(Icons.location_on, 'Location', widget.event.location, isDarkMode),
                  _buildInfoRow(Icons.person, 'Created by', widget.event.createdBy, isDarkMode),
                  _buildInfoRow(Icons.group, 'RSVP Count', '$_currentRSVPCount', isDarkMode),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(_isLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined),
                            color: _isLiked ? Colors.blue : Colors.grey,
                            onPressed: _toggleLike,
                          ),
                          Text('$_likeCount Likes', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
                        ],
                      ),
                      !_hasRSVPed
                          ? ElevatedButton(
                        onPressed: () => _incrementRSVPCount(widget.event.documentId),
                        child: Text('RSVP', style: TextStyle(color: isDarkMode ? Colors.black : Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          textStyle: TextStyle(fontSize: 16),
                        ),
                      )
                          : ElevatedButton(
                        onPressed: () => _decrementRSVPCount(widget.event.documentId),
                        child: Text('Cancel RSVP', style: TextStyle(color: isDarkMode ? Colors.black : Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          textStyle: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  Divider(),
                  Text('Comments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black)),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: _comments.length,
                    itemBuilder: (context, index) {
                      final comment = _comments[index];
                      return ListTile(
                        title: Text(comment['text']),
                        subtitle: Text('By: ${comment['userId']}'),
                        trailing: Text(DateFormat('MMM d, y - h:mm a').format(comment['timestamp'].toDate())),
                      );
                    },
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      suffixIcon: IconButton(
                        icon: Icon(Icons.send),
                        onPressed: () => _addComment(_commentController.text),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, bool isDarkMode) {
    if (label == 'Location') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.blue),
            SizedBox(width: 8),
            RichText(
              text: TextSpan(
                text: '$label: ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
                children: [
                  TextSpan(
                    text: widget.event.location,
                    style: TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        final Uri url = Uri.parse(
                            "https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(widget.event.location)}");
                        try {
                          await _launchURL(url.toString());
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Could not launch $url')),
                          );
                        }
                      },
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.blue),
            SizedBox(width: 8),
            Text(
              '$label: ',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDarkMode ? Colors.white : Colors.black),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(fontSize: 16, color: isDarkMode ? Colors.white70 : Colors.black87, decoration: TextDecoration.none),
              ),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  void _incrementRSVPCount(String documentId) async {
    if (_userId != null) {
      FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentReference eventRef =
        FirebaseFirestore.instance.collection('events').doc(documentId);
        DocumentReference userRef =
        FirebaseFirestore.instance.collection('users').doc(_userId);

        DocumentSnapshot eventSnapshot = await transaction.get(eventRef);
        DocumentSnapshot userSnapshot = await transaction.get(userRef);

        if (!userSnapshot['rsvpEvents'].contains(documentId)) {
          int newRSVPCount = eventSnapshot['rsvpCount'] + 1;
          transaction.update(eventRef, {'rsvpCount': newRSVPCount});
          transaction.update(userRef, {
            'rsvpEvents': FieldValue.arrayUnion([documentId])
          });
        }
      }).then((_) {
        setState(() {
          _currentRSVPCount += 1;
          _hasRSVPed = true;
        });
      }).catchError((error) {
        print("Failed to RSVP: $error");
      });
    }
  }

  void _decrementRSVPCount(String documentId) async {
    if (_userId != null) {
      FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentReference eventRef =
        FirebaseFirestore.instance.collection('events').doc(documentId);
        DocumentReference userRef =
        FirebaseFirestore.instance.collection('users').doc(_userId);

        DocumentSnapshot eventSnapshot = await transaction.get(eventRef);
        DocumentSnapshot userSnapshot = await transaction.get(userRef);

        if (userSnapshot['rsvpEvents'].contains(documentId)) {
          int newRSVPCount = eventSnapshot['rsvpCount'] - 1;
          transaction.update(eventRef, {'rsvpCount': newRSVPCount});
          transaction.update(userRef, {
            'rsvpEvents': FieldValue.arrayRemove([documentId])
          });
        }
      }).then((_) {
        setState(() {
          _currentRSVPCount -= 1;
          _hasRSVPed = false;
        });
      }).catchError((error) {
        print("Failed to cancel RSVP: $error");
      });
    }
  }
}
